"""
Game Handler Lambda — POST /game/start, POST /game/message
Core gameplay: session management, AI calls, repair detection.
"""
import json
import os
import boto3
import sys
import re

# Add shared layer to path
sys.path.insert(0, "/opt")
from db import (get_or_create_user, update_user, create_session,
                get_session, update_session, archive_session, get_daily_reset,
                update_daily_reset, add_leaderboard_point,
                get_completed_scenarios, get_solved_session_for_scenario)
from prompts import (build_game_system_prompt, build_hint_system_prompt,
                     build_mastery_feedback_prompt, sanitize_input,
                     validate_output, validate_language)
from scenarios import get_scenario_by_id, get_scenarios_by_difficulty
from response import api_response

bedrock = boto3.client("bedrock-runtime", region_name=os.environ.get("BEDROCK_REGION", "us-east-1"))
MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "us.amazon.nova-lite-v1:0")

def lambda_handler(event, context):
    """Route based on path."""
    path = event.get("rawPath", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    user_id = event.get("requestContext", {}).get("authorizer", {}).get("lambda", {}).get("userId", "")

    if not user_id:
        return api_response(401, {"error": "unauthorized"})

    if path == "/game/start" and method == "POST":
        return handle_start(event, user_id)
    elif path == "/game/message" and method == "POST":
        return handle_message(event, user_id)
    elif path == "/game/completed" and method == "GET":
        return handle_completed(user_id)
    elif path.startswith("/game/archive/") and method == "GET":
        scenario_id = path.rsplit("/", 1)[-1]
        return handle_archive(user_id, scenario_id)
    else:
        return api_response(404, {"error": "not_found"})


def handle_start(event, user_id):
    """Start a new game session."""
    body = _parse_body(event)
    scenario_id = body.get("scenarioId")

    if not scenario_id:
        return api_response(400, {"error": "scenarioId required"})

    # Get user and scenario
    user = get_or_create_user(user_id)
    is_pro = user.get("subscription") == "pro"

    scenario = get_scenario_by_id(scenario_id)
    if not scenario:
        return api_response(404, {"error": "scenario_not_found"})

    solved_session = get_solved_session_for_scenario(user_id, int(scenario_id))
    if solved_session:
        return api_response(409, {
            "error": "already_solved",
            "message": "Bu vaka zaten çözüldü. Arşivden sohbeti inceleyebilirsin.",
            "scenarioId": int(scenario_id),
            "sessionId": solved_session["sessionId"],
            "solvedAt": solved_session.get("solvedAt"),
        })

    if not is_pro and user["energy"] <= 0:
        return api_response(403, {"error": "no_energy", "message": "Watch an ad or wait for daily reset."})

    # Create session
    session = create_session(user_id, scenario_id)

    # Deduct energy for free users only. Pro users have unlimited energy.
    new_energy = user["energy"] if is_pro else user["energy"] - 1
    if not is_pro:
        update_user(user_id, {"energy": new_energy})

    # Update daily tracking
    daily = get_daily_reset(user_id)
    update_daily_reset(user_id, {
        "energyUsed": daily["energyUsed"] + 1,
        "casesPlayed": daily["casesPlayed"] + 1,
    })

    return api_response(200, {
        "sessionId": session["sessionId"],
        "scenario": {
            "id": scenario["id"],
            "vehicle": scenario["vehicle"],
            "complaint": scenario["complaint"],
            "difficulty": scenario["difficulty"],
        },
        "energy": new_energy,
        "isPro": is_pro,
    })


def handle_message(event, user_id):
    """Process a player message in an active session."""
    body = _parse_body(event)
    session_id = body.get("sessionId")
    user_message = body.get("message", "").strip()

    if not session_id or not user_message:
        return api_response(400, {"error": "sessionId and message required"})

    # Load session
    session = get_session(session_id)
    if not session:
        return api_response(404, {"error": "session_not_found"})
    if session["userId"] != user_id:
        return api_response(403, {"error": "not_your_session"})
    if session["status"] != "active":
        return api_response(400, {"error": "session_not_active", "status": session["status"]})

    # Check message limit
    message_limit = session.get("messageLimit", 18)
    cooldown_ends_at = session.get("cooldownEndsAt")
    
    now = __import__("datetime").datetime.now(__import__("datetime").timezone.utc).timestamp()
    
    if session["messageCount"] >= message_limit:
        if cooldown_ends_at and now >= cooldown_ends_at:
            # Cooldown is over, grant 18 more messages
            message_limit += 18
            update_session(session_id, {"messageLimit": message_limit, "cooldownEndsAt": None})
            session["messageLimit"] = message_limit
            session["cooldownEndsAt"] = None
        else:
            # Enforce cooldown
            if not cooldown_ends_at:
                cooldown_ends_at = now + (2 * 3600)
                update_session(session_id, {"cooldownEndsAt": cooldown_ends_at})
            
            return api_response(403, {
                "error": "cooldown", 
                "cooldownEndsAt": cooldown_ends_at,
                "message": "Ustayı yordun! 2 saat bekle veya reklam izle."
            })

    # === LAYER 1: Input Sanitization ===
    is_safe, checked = sanitize_input(user_message)
    if not is_safe:
        messages = session["messages"] + [
            {"role": "user", "content": user_message},
            {"role": "assistant", "content": checked},
        ]
        update_session(session_id, {
            "messages": messages,
            "messageCount": session["messageCount"] + 1,
        })
        return api_response(200, {
            "response": checked,
            "messageCount": session["messageCount"] + 1,
            "solved": False,
            "blocked": True,
        })

    # Build prompt and call AI
    user = get_or_create_user(user_id)
    lang_code = body.get("langCode", user.get("languageCode", "tr"))
    
    scenario = get_scenario_by_id(int(session["scenarioId"]))
    system_prompt = build_game_system_prompt(scenario, lang_code=lang_code)

    # Memory pruning: first message + last 5
    all_msgs = session["messages"] + [{"role": "user", "content": user_message}]
    game_msgs = [m for m in all_msgs if not m.get("isHint")]
    if len(game_msgs) > 6:
        api_msgs = [game_msgs[0]] + game_msgs[-5:]
    else:
        api_msgs = game_msgs
    clean_msgs = [{"role": m["role"], "content": [{"text": m["content"]}]} for m in api_msgs]

    # Call Bedrock
    try:
        nova_body = {
            "system": [{"text": system_prompt}],
            "messages": clean_msgs,
            "inferenceConfig": {"maxTokens": 200},
        }
        response = bedrock.invoke_model(
            modelId=MODEL_ID, contentType="application/json",
            accept="application/json", body=json.dumps(nova_body),
        )
        result = json.loads(response["body"].read())
        ai_text = result["output"]["message"]["content"][0]["text"]
    except Exception as e:
        print(f"BEDROCK_ERROR: {e}")
        ai_text = "Garajın şartelleri attı — tekrar dene."

    # === LAYER 3: Output Validation ===
    is_lang_valid, lang_msg = validate_language(ai_text, lang_code)
    if not is_lang_valid:
        ai_text = lang_msg
    else:
        ai_text = validate_output(ai_text, scenario, lang_code=lang_code)
    ai_text = _soften_unhelpful_invalid_response(ai_text, lang_code)

    # Check [CASE_SOLVED]. The model can describe the correct repair but forget
    # the marker, so keep a deterministic repair-command guard as backup.
    case_solved = "[CASE_SOLVED]" in ai_text or _is_correct_repair_command(
        scenario,
        user_message,
    )
    clean_text = ai_text.replace("[CASE_SOLVED]", "").strip()

    # Update session
    new_messages = session["messages"] + [
        {"role": "user", "content": user_message},
        {"role": "assistant", "content": clean_text},
    ]
    new_count = session["messageCount"] + 1

    session_updates = {"messages": new_messages, "messageCount": new_count}

    response_data = {
        "response": clean_text,
        "messageCount": new_count,
        "messageLimit": session.get("messageLimit", 18),
        "solved": case_solved,
    }

    if case_solved:
        session_updates["status"] = "solved"
        session_updates["solvedAt"] = __import__("datetime").datetime.now(
            __import__("datetime").timezone.utc
        ).isoformat()

        # Update user stats
        user = get_or_create_user(user_id)
        new_repairs = user["totalRepairs"] + 1
        new_streak = user["streakCount"] + 1
        user_updates = {"totalRepairs": new_repairs, "streakCount": new_streak}

        # Streak bonus: every 3 repairs = +1 energy
        bonus_energy = False
        if new_streak % 3 == 0:
            user_updates["energy"] = user["energy"] + 1
            bonus_energy = True

        update_user(user_id, user_updates)
        response_data["streakCount"] = new_streak
        response_data["bonusEnergy"] = bonus_energy

        # Leaderboard +1
        add_leaderboard_point(user_id, user["displayName"])

        mastery_feedback = _build_mastery_feedback(
            scenario=scenario,
            messages=new_messages,
            lang_code=lang_code,
        )
        if mastery_feedback:
            response_data["masteryFeedback"] = mastery_feedback
            session_updates["masteryFeedback"] = mastery_feedback

    if case_solved:
        archive_session(session_id, session_updates)
    else:
        update_session(session_id, session_updates)
    return api_response(200, response_data)


def handle_completed(user_id):
    user = get_or_create_user(user_id)
    daily = get_daily_reset(user_id)
    return api_response(200, {
        "completedScenarios": get_completed_scenarios(user_id),
        "archiveViewsToday": int(daily.get("archiveViews", 0)),
        "archiveViewLimit": 9999 if user.get("subscription") == "pro" else 2,
        "isPro": user.get("subscription") == "pro",
    })


def handle_archive(user_id, scenario_id_value):
    try:
        scenario_id = int(scenario_id_value)
    except Exception:
        return api_response(400, {"error": "invalid_scenario_id"})

    session = get_solved_session_for_scenario(user_id, scenario_id)
    if not session:
        return api_response(404, {"error": "archive_not_found"})

    scenario = get_scenario_by_id(scenario_id)
    user = get_or_create_user(user_id)
    is_pro = user.get("subscription") == "pro"
    daily = get_daily_reset(user_id)
    viewed_ids = [int(x) for x in daily.get("archiveViewedScenarioIds", [])]
    archive_views = int(daily.get("archiveViews", 0))

    if not is_pro and scenario_id not in viewed_ids:
        if archive_views >= 2:
            return api_response(403, {
                "error": "archive_limit",
                "message": "Bugün 2 geçmiş vaka inceleme hakkını kullandın. Pro Usta sınırsız arşiv açar.",
                "archiveViewsToday": archive_views,
                "archiveViewLimit": 2,
            })
        viewed_ids.append(scenario_id)
        archive_views += 1
        update_daily_reset(user_id, {
            "archiveViews": archive_views,
            "archiveViewedScenarioIds": viewed_ids,
        })

    return api_response(200, {
        "sessionId": session["sessionId"],
        "scenario": {
            "id": scenario["id"],
            "vehicle": scenario["vehicle"],
            "complaint": scenario["complaint"],
            "difficulty": scenario["difficulty"],
        } if scenario else {"id": scenario_id},
        "messages": session.get("messages", []),
        "messageCount": session.get("messageCount", 0),
        "solved": True,
        "solvedAt": session.get("solvedAt"),
        "masteryFeedback": session.get("masteryFeedback"),
        "archiveViewsToday": archive_views,
        "archiveViewLimit": 9999 if is_pro else 2,
        "isPro": is_pro,
    })


def _parse_body(event):
    body = event.get("body", "{}")
    if isinstance(body, str):
        try:
            return json.loads(body)
        except Exception:
            return {}
    return body


def _build_mastery_feedback(scenario, messages, lang_code="tr"):
    """Generate a short post-solve coaching note. Failure should never block gameplay."""
    if os.environ.get("ENABLE_MASTERY_FEEDBACK", "true").lower() == "false":
        return None

    try:
        feedback_messages = _format_feedback_messages(messages)
        if not feedback_messages:
            return None

        feedback_prompt = build_mastery_feedback_prompt(scenario, lang_code=lang_code)
        body = {
            "system": [{"text": feedback_prompt}],
            "messages": [
                {
                    "role": "user",
                    "content": [{
                        "text": "CHAT HISTORY:\n" + feedback_messages,
                    }],
                }
            ],
            "inferenceConfig": {"maxTokens": 180},
        }
        response = bedrock.invoke_model(
            modelId=os.environ.get("MASTERY_FEEDBACK_MODEL_ID", MODEL_ID),
            contentType="application/json",
            accept="application/json",
            body=json.dumps(body),
        )
        result = json.loads(response["body"].read())
        feedback = result["output"]["message"]["content"][0]["text"].strip()
        feedback = _clean_mastery_feedback(feedback)
        if not feedback:
            return None
        feedback = _improve_mastery_feedback(feedback, messages, lang_code)

        is_lang_valid, _ = validate_language(feedback, lang_code)
        if not is_lang_valid:
            return None
        return feedback
    except Exception as e:
        print(f"MASTERY_FEEDBACK_ERROR: {e}")
        return None


def _format_feedback_messages(messages):
    relevant = [
        m for m in messages
        if m.get("role") in ("user", "assistant") and m.get("content")
    ]
    relevant = relevant[-10:]
    return "\n".join(
        f"{m['role'].upper()}: {m['content'][:500]}"
        for m in relevant
    )


UNHELPFUL_INVALID_RESPONSE_TERMS = [
    "bulunmuyor", "gerekli ekipman", "bilgi bulunmuyor", "bileşen/test",
    "does not have that component", "invalid test", "no such component",
    "нет такого компонента", "недействителен", "没有这个部件", "无效",
]


SOFT_INVALID_RESPONSES = {
    "tr": "Bu işlemden sonra belirti değişmiyor. Eldeki bulgular hâlâ aynı noktayı işaret ediyor.",
    "en": "After that action, the symptom does not change. The clues still point in the same direction.",
    "ru": "После этого действия симптом не меняется. Имеющиеся признаки всё ещё указывают в том же направлении.",
    "zh": "做完这个操作后，故障现象没有变化。现有线索仍然指向同一个方向。",
}


def _soften_unhelpful_invalid_response(ai_text, lang_code):
    normalized = _normalize_repair_text(ai_text)
    terms = [_normalize_repair_text(term) for term in UNHELPFUL_INVALID_RESPONSE_TERMS]
    if not any(term in normalized for term in terms):
        return ai_text

    lang = "zh" if str(lang_code).startswith("zh") else lang_code
    return SOFT_INVALID_RESPONSES.get(lang, SOFT_INVALID_RESPONSES["tr"])


def _clean_mastery_feedback(feedback):
    forbidden_prefixes = ("```", "#", "-", "*", "Ustalık Değerlendirmesi:", "Mastery Review:")
    for prefix in forbidden_prefixes:
        if feedback.startswith(prefix):
            feedback = feedback[len(prefix):].strip()
    feedback = feedback.replace("```", "").strip()
    if len(feedback) > 700:
        feedback = feedback[:700].rsplit(" ", 1)[0].strip()
    return feedback


FAILED_ATTEMPT_MARKERS = [
    "cozulmedi", "degismiyor", "degismedi", "hala", "still", "does not change",
    "did not change", "not fixed", "not solve", "не меняется", "не измен", "没有变化",
]

BATTERY_RECOVERY_ATTEMPT_MARKERS = [
    "asit", "acid", "saf su", "water", "sarj", "sarz", "charge", "recharge",
    "takviye", "заряд", "кислот", "долей",
]

BATTERY_RECOVERY_FEEDBACK = {
    "tr": "Saf su, asit ve şarj denemesi mantıklı bir kurtarma hamlesiydi, ama voltaj değişmeyince doğru karar aküyü değiştirmekti.",
    "en": "The water, acid, and recharge attempt was a reasonable recovery idea, but once the voltage did not change, replacing the battery was the right call.",
    "ru": "Попытка с водой, кислотой и зарядкой была понятной идеей восстановления, но раз напряжение не изменилось, правильным решением стала замена аккумулятора.",
    "zh": "加水、补酸和充电是一个可以理解的抢救思路，但电压没有变化时，更换电瓶才是正确决定。",
}


def _improve_mastery_feedback(feedback, messages, lang_code):
    feedback = _rebalance_empty_mastery_praise(feedback, lang_code)
    if not _has_failed_battery_recovery_attempt(messages):
        return feedback

    normalized_feedback = _normalize_repair_text(feedback)
    mentions_attempt = any(
        _normalize_repair_text(marker) in normalized_feedback
        for marker in BATTERY_RECOVERY_ATTEMPT_MARKERS
    )
    if mentions_attempt:
        return feedback

    lang = "zh" if str(lang_code).startswith("zh") else lang_code
    return BATTERY_RECOVERY_FEEDBACK.get(lang, BATTERY_RECOVERY_FEEDBACK["tr"])


EMPTY_MASTERY_PRAISE_TERMS = [
    "mukemmel", "harika", "super", "bravo",
    "excellent", "great job", "perfect", "very clever",
    "отлично", "превосходно", "идеально",
    "太棒", "完美", "很聪明",
]

MASTERY_PRAISE_CLOSERS = {
    "tr": "Güzel teşhis, usta gibi toparladın.",
    "en": "Good diagnosis, you recovered like a pro.",
    "ru": "Хорошая диагностика, ты собрал всё как мастер.",
    "zh": "判断不错，收尾很有师傅范儿。",
}


def _rebalance_empty_mastery_praise(feedback, lang_code):
    sentences = [part.strip() for part in re.split(r"(?<=[.!?。])\s+", feedback) if part.strip()]
    if len(sentences) <= 1:
        return feedback

    kept = []
    replaced_empty_praise = False
    for sentence in sentences:
        normalized = _normalize_repair_text(sentence)
        has_empty_praise = any(
            _normalize_repair_text(term) in normalized
            for term in EMPTY_MASTERY_PRAISE_TERMS
        )
        has_specific_content = any(
            term in normalized
            for term in [
                "asit", "saf su", "sarj", "aku", "akuyu", "sigorta", "mars",
                "battery", "fuse", "starter", "charge", "acid", "voltage",
                "аккумулятор", "предохранитель", "стартер", "电瓶", "保险丝",
            ]
        )
        if has_empty_praise and not has_specific_content:
            replaced_empty_praise = True
            continue
        kept.append(sentence)

    if not kept:
        return feedback
    if replaced_empty_praise:
        lang = "zh" if str(lang_code).startswith("zh") else lang_code
        closer = MASTERY_PRAISE_CLOSERS.get(lang, MASTERY_PRAISE_CLOSERS["tr"])
        if not kept[-1].endswith(closer):
            kept.append(closer)
    return " ".join(kept)


def _has_failed_battery_recovery_attempt(messages):
    last_user = ""
    for message in messages:
        role = message.get("role")
        content = message.get("content", "")
        if role == "user":
            last_user = content
            continue
        if role != "assistant" or not last_user:
            continue

        normalized_user = _normalize_repair_text(last_user)
        normalized_reply = _normalize_repair_text(content)
        attempted_recovery = any(
            _normalize_repair_text(marker) in normalized_user
            for marker in BATTERY_RECOVERY_ATTEMPT_MARKERS
        )
        failed_attempt = any(
            _normalize_repair_text(marker) in normalized_reply
            for marker in FAILED_ATTEMPT_MARKERS
        )
        if attempted_recovery and failed_attempt:
            return True
    return False


REPAIR_VERBS = [
    "replace", "change", "fix", "repair", "install", "recharge", "recalibrate",
    "değiştir", "degistir", "yenile", "tamir", "onar", "tak", "doldur",
    "kalibre", "ayarla", "şarj et", "sarj et",
    "замени", "заменить", "поменяй", "поменять", "почини", "починить",
    "установи", "установить", "заправь", "заправить", "откалибруй",
    "更换", "换", "修理", "维修", "安装", "加注", "重新加注", "校准",
]

CORRECT_REPAIR_ALIASES = {
    1: ["battery", "akü", "aku", "akuyu", "aküyü", "аккумулятор", "电瓶", "蓄电池"],
    2: ["starter", "starter motor", "marş motor", "mars motor", "стартер", "起动机"],
    3: ["fuse", "sigorta", "#14", "15a", "15 a", "предохранитель", "保险丝"],
    4: ["wiper motor", "silecek motor", "мотор дворник", "雨刷电机"],
    5: ["ac line", "refrigerant", "klima hatt", "klima gaz", "kaçak", "kacak", "хладагент", "кондиционер", "制冷剂", "空调"],
    6: ["thermostat", "termostat", "термостат", "节温器"],
    7: ["spark plug", "buji", "cylinder 3", "silindir 3", "3. silindir", "свеч", "цилиндр 3", "火花塞", "3缸"],
    8: ["atf", "transmission fluid", "şanzıman yağı", "sanziman yagi", "şanzıman sıvısı", "трансмиссион", "atf", "变速箱油"],
    9: ["brake pad", "balata", "fren balata", "колод", "刹车片"],
    10: ["o2 sensor", "oxygen sensor", "lambda", "oksijen sensör", "oksijen sensor", "лямбда", "кислород", "氧传感器"],
    11: ["piston ring", "segman", "cylinder 2", "cylinder 3", "silindir 2", "silindir 3", "поршнев", "кольц", "活塞环"],
    12: ["head gasket", "conta", "silindir kapak", "проклад", "гбц", "汽缸垫", "缸垫"],
    13: ["water pump", "su pompa", "devirdaim", "помпа", "водян", "水泵"],
    14: ["timing belt", "triger", "zamanlama", "sente", "ремень грм", "грм", "正时皮带", "正时"],
    15: ["lpg ecu", "lpg harita", "lpg kalibr", "gaz ayar", "газов", "lpg", "燃气", "液化气"],
}
DEFAULT_REPAIR_VERBS_STRICT = [
    "replace", "change", "swap", "renew", "fix", "repair", "install",
    "degistir", "degis", "yenile", "tamir", "onar", "tak",
    "замени", "заменить", "поменяй", "поменять", "почини", "починить",
    "установи", "установить", "отремонтируй", "отремонтировать",
    "更换", "换", "修理", "维修", "安装",
]

REPLACEMENT_VERBS_STRICT = [
    "replace", "change", "swap", "renew",
    "degistir", "degis", "yenile",
    "замени", "заменить", "поменяй", "поменять",
    "更换", "换",
]

CORRECT_REPAIR_RULES_STRICT = {
    1: {
        "targets": ["battery", "aku", "akuyu", "akumulator", "аккумулятор", "电瓶", "蓄电池"],
        "verbs": REPLACEMENT_VERBS_STRICT,
        "blocked": [
            "charge", "recharge", "jump", "boost", "water", "acid",
            "sarj", "sarz", "takviye", "doldur", "asit", "заряд", "кислот", "долей",
        ],
    },
    2: {
        "targets": ["starter", "starter motor", "mars motor", "стартер", "起动机"],
        "verbs": DEFAULT_REPAIR_VERBS_STRICT,
    },
    3: {
        "targets": ["fuse", "sigorta", "#14", "15a", "15 a", "предохранитель", "保险丝"],
        "verbs": REPLACEMENT_VERBS_STRICT,
    },
    4: {"targets": ["wiper motor", "silecek motor"], "verbs": DEFAULT_REPAIR_VERBS_STRICT},
    5: {
        "targets": ["ac line", "refrigerant", "klima hatt", "klima gaz", "kacak"],
        "verbs": DEFAULT_REPAIR_VERBS_STRICT,
    },
    6: {"targets": ["thermostat", "termostat"], "verbs": DEFAULT_REPAIR_VERBS_STRICT},
    7: {
        "targets": ["spark plug", "buji", "cylinder 3", "silindir 3", "3. silindir"],
        "verbs": DEFAULT_REPAIR_VERBS_STRICT,
    },
    8: {
        "targets": ["atf", "transmission fluid", "sanziman yagi", "sanziman sivisi"],
        "verbs": DEFAULT_REPAIR_VERBS_STRICT,
    },
    9: {"targets": ["brake pad", "balata", "fren balata"], "verbs": DEFAULT_REPAIR_VERBS_STRICT},
    10: {
        "targets": ["o2 sensor", "oxygen sensor", "lambda", "oksijen sensor"],
        "verbs": DEFAULT_REPAIR_VERBS_STRICT,
    },
    11: {
        "targets": ["piston ring", "segman", "cylinder 2", "cylinder 3", "silindir 2", "silindir 3"],
        "verbs": DEFAULT_REPAIR_VERBS_STRICT,
    },
    12: {"targets": ["head gasket", "conta", "silindir kapak"], "verbs": DEFAULT_REPAIR_VERBS_STRICT},
    13: {"targets": ["water pump", "su pompa", "devirdaim"], "verbs": DEFAULT_REPAIR_VERBS_STRICT},
    14: {"targets": ["timing belt", "triger", "zamanlama", "sente"], "verbs": DEFAULT_REPAIR_VERBS_STRICT},
    15: {"targets": ["lpg ecu", "lpg harita", "lpg kalibr", "gaz ayar", "lpg"], "verbs": DEFAULT_REPAIR_VERBS_STRICT},
}


def _is_correct_repair_command(scenario, user_message):
    """Return True when the player's command clearly targets the correct repair."""
    scenario_id = int(scenario.get("id", 0))
    normalized = _normalize_repair_text(user_message)
    if not normalized:
        return False

    rule = CORRECT_REPAIR_RULES_STRICT.get(scenario_id)
    if not rule:
        return False

    if _contains_any_repair_term(normalized, rule.get("blocked", [])):
        return False

    return (
        _contains_any_repair_term(normalized, rule["targets"])
        and _contains_any_repair_term(normalized, rule["verbs"])
    )


def _contains_any_repair_term(text, values):
    return any(_normalize_repair_text(value) in text for value in values)


def _normalize_repair_text(text):
    text = (text or "").lower()
    replacements = {
        "ı": "i", "İ": "i", "ğ": "g", "Ğ": "g", "ü": "u", "Ü": "u",
        "ş": "s", "Ş": "s", "ö": "o", "Ö": "o", "ç": "c", "Ç": "c",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    return text
