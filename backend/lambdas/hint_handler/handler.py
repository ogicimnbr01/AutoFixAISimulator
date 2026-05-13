"""
Hint Handler Lambda — POST /hint
Consultant Master hint system with credit management.
"""
import json
import os
import sys
import boto3

sys.path.insert(0, "/opt")
from db import get_or_create_user, update_user, get_session, update_session
from prompts import build_hint_system_prompt, validate_language
from scenarios import get_scenario_by_id
from response import api_response

bedrock = boto3.client("bedrock-runtime", region_name=os.environ.get("BEDROCK_REGION", "us-east-1"))
MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "us.amazon.nova-lite-v1:0")


def lambda_handler(event, context):
    user_id = event.get("requestContext", {}).get("authorizer", {}).get("lambda", {}).get("userId", "")
    if not user_id:
        return api_response(401, {"error": "unauthorized"})

    body = json.loads(event.get("body", "{}")) if isinstance(event.get("body"), str) else event.get("body", {})
    session_id = body.get("sessionId")

    if not session_id:
        return api_response(400, {"error": "sessionId required"})

    # Check credits
    user = get_or_create_user(user_id)
    is_pro = user.get("subscription") == "pro"
    if not is_pro and user["hintCredits"] <= 0:
        return api_response(403, {"error": "no_hints", "message": "No hint credits left. Log in tomorrow or buy a pack."})

    # Load session
    session = get_session(session_id)
    if not session or session["userId"] != user_id or session["status"] != "active":
        return api_response(400, {"error": "invalid_session"})

    # Build hint prompt
    lang_code = _normalize_lang(body.get("lang") or body.get("langCode") or user.get("languageCode", "tr"))
    scenario = get_scenario_by_id(session["scenarioId"])
    hint_prompt = build_hint_system_prompt(scenario, lang_code=lang_code)

    # Prepare messages for hint context
    hint_msgs = [{"role": m["role"], "content": [{"text": m["content"]}]} for m in session["messages"]]
    hint_msgs.append({"role": "user", "content": [{"text": _localized_hint_request(lang_code)}]})

    # Call Bedrock
    try:
        nova_body = {
            "system": [{"text": hint_prompt}],
            "messages": hint_msgs[-10:],  # Last 10 messages for context
            "inferenceConfig": {"maxTokens": 100},
        }
        response = bedrock.invoke_model(
            modelId=MODEL_ID, contentType="application/json",
            accept="application/json", body=json.dumps(nova_body),
        )
        result = json.loads(response["body"].read())
        hint_text = result["output"]["message"]["content"][0]["text"]
    except Exception:
        hint_text = _localized_hint_fallback(lang_code)

    is_lang_valid, _ = validate_language(hint_text, lang_code)
    if not is_lang_valid:
        hint_text = _localized_hint_fallback(lang_code)

    # Deduct credit for free users only. Pro users have unlimited hints.
    remaining_credits = user["hintCredits"] if is_pro else user["hintCredits"] - 1
    if not is_pro:
        update_user(user_id, {"hintCredits": remaining_credits})

    # Add hint to session
    new_messages = session["messages"] + [
        {"role": "user", "content": "Hint request", "isHint": True},
        {"role": "assistant", "content": hint_text, "isHint": True},
    ]
    update_session(session_id, {"messages": new_messages})

    return api_response(200, {
        "hint": hint_text,
        "remainingCredits": remaining_credits,
        "isPro": is_pro,
    })


def _normalize_lang(lang_code):
    lang = (lang_code or "tr").lower()
    if lang.startswith("zh"):
        return "zh"
    if lang.startswith("ru"):
        return "ru"
    if lang.startswith("en"):
        return "en"
    return "tr"


def _localized_hint_request(lang_code):
    if lang_code == "en":
        return "I'm stuck. Give me one short hint in English only."
    if lang_code == "ru":
        return "Я застрял. Дай одну короткую подсказку только на русском."
    if lang_code == "zh":
        return "我卡住了。请只用中文给我一个简短提示。"
    return "Takıldım. Sadece Türkçe, kısa bir usta ipucu ver."


def _localized_hint_fallback(lang_code):
    if lang_code == "en":
        return "Start with the next basic comparison test; separate what works from what does not."
    if lang_code == "ru":
        return "Начни со следующей простой проверки: отдели то, что работает, от того, что не работает."
    if lang_code == "zh":
        return "先做下一个基础对比测试，把正常工作的部分和异常部分分开。"
    return "Bir sonraki temel karşılaştırma testinden başla; çalışan parça ile çalışmayan tarafı ayır."
