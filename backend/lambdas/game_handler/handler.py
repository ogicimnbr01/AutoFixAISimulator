"""
Game Handler Lambda — POST /game/start, POST /game/message
Core gameplay: session management, AI calls, repair detection.
"""
import json
import os
import boto3
import sys

# Add shared layer to path
sys.path.insert(0, "/opt")
from db import (get_or_create_user, update_user, create_session,
                get_session, update_session, get_daily_reset,
                update_daily_reset, add_leaderboard_point)
from prompts import (build_game_system_prompt, build_hint_system_prompt,
                     sanitize_input, validate_output, validate_language)
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
    else:
        return api_response(404, {"error": "not_found"})


def handle_start(event, user_id):
    """Start a new game session."""
    body = _parse_body(event)
    scenario_id = body.get("scenarioId")

    if not scenario_id:
        return api_response(400, {"error": "scenarioId required"})

    # Get user and check energy
    user = get_or_create_user(user_id)
    is_pro = user.get("subscription") == "pro"
    if not is_pro and user["energy"] <= 0:
        return api_response(403, {"error": "no_energy", "message": "Watch an ad or wait for daily reset."})

    # Get scenario
    scenario = get_scenario_by_id(scenario_id)
    if not scenario:
        return api_response(404, {"error": "scenario_not_found"})

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

    # Check [CASE_SOLVED]
    case_solved = "[CASE_SOLVED]" in ai_text
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

    update_session(session_id, session_updates)
    return api_response(200, response_data)


def _parse_body(event):
    body = event.get("body", "{}")
    if isinstance(body, str):
        try:
            return json.loads(body)
        except Exception:
            return {}
    return body
