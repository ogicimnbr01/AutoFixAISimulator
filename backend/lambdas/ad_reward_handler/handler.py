"""
Ad Reward Handler Lambda — POST /ad/reward, GET /webhook/admob-ssv
Validates rewarded ad completion and grants energy.
"""
import json
import sys
import os

sys.path.insert(0, "/opt")
from db import get_or_create_user, update_user
from response import api_response


def lambda_handler(event, context):
    path = event.get("rawPath", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")

    if method == "GET" and path == "/webhook/admob-ssv":
        return handle_admob_ssv(event)

    if method == "POST" and path == "/ad/reward":
        return handle_client_reward(event)

    return api_response(404, {"error": "not_found"})


def handle_admob_ssv(event):
    """Handles Server-Side Verification from AdMob."""
    query_params = event.get("queryStringParameters") or {}
    
    custom_data = query_params.get("custom_data")
    signature = query_params.get("signature")
    key_id = query_params.get("key_id")
    
    # 1. IP Whitelist / Basic Rate Limit Check
    source_ip = event.get("requestContext", {}).get("http", {}).get("sourceIp", "")
    # In production, verify against Google's IP ranges (e.g. 8.8.8.8 or specific AdMob ranges). 
    # For now, we log it to monitor brute-force attempts.
    print(f"[ADMOB_SSV] Request from IP: {source_ip}")
    
    if not custom_data:
        print("[ADMOB_SSV] Error: Missing custom_data. Ignoring silently to prevent retries.")
        # Edge Case Handled: Return 200 so AdMob stops retrying this broken payload
        return api_response(200, {"status": "ignored", "reason": "missing_custom_data"})

    # Parse custom_data (format: "userId|rewardType|sessionId")
    parts = custom_data.split("|")
    user_id = parts[0]
    reward_type = parts[1] if len(parts) > 1 else "energy"
    
    try:
        user = get_or_create_user(user_id)
        if not user:
            raise ValueError("User not found")
    except Exception as e:
        print(f"[ADMOB_SSV] Invalid/Unknown userId '{user_id}'. Error: {e}")
        # Return 200 silently to prevent infinite retries for a deleted/invalid user
        return api_response(200, {"status": "ignored", "reason": "invalid_user"})
    
    # 2. ECDSA Verification Placeholder
    # Production: Fetch Google's AdMob verifier keys and verify signature/key_id.
    # Until that verifier is implemented, only non-production/demo environments
    # should allow unverified SSV payloads.
    allow_unverified_ssv = os.environ.get("ALLOW_UNVERIFIED_ADMOB_SSV", "false").lower() == "true"
    is_valid_signature = allow_unverified_ssv
    
    if not is_valid_signature:
        print("[ADMOB_SSV] Error: Invalid signature.")
        # Return 200 to drop the request intentionally (AdMob guidelines)
        return api_response(200, {"status": "ignored", "reason": "invalid_signature"})

    # Grant Reward
    try:
        if reward_type == "energy":
            new_energy = user.get("energy", 0) + 1
            update_user(user_id, {"energy": new_energy})
            print(f"[ADMOB_SSV] Granted energy to {user_id}")
            
        elif reward_type == "cooldown":
            if len(parts) > 2:
                session_id = parts[2]
                from db import get_session, update_session
                session = get_session(session_id)
                if session and session["userId"] == user_id:
                    cooldown_ends_at = session.get("cooldownEndsAt")
                    now = __import__("datetime").datetime.now(__import__("datetime").timezone.utc).timestamp()
                    if cooldown_ends_at and cooldown_ends_at > now:
                        new_cooldown = cooldown_ends_at - 3600
                        update_session(session_id, {"cooldownEndsAt": new_cooldown if new_cooldown > now else None})
                        print(f"[ADMOB_SSV] Reduced cooldown for {user_id}")
        
        return api_response(200, {"status": "success"})
    except Exception as e:
        print(f"[ADMOB_SSV] Processing error: {e}")
        return api_response(200, {"status": "ignored", "reason": "processing_error"})


def handle_client_reward(event):
    """
    Called by the app immediately after watching an ad.
    Because SSV might take a few seconds, we can either:
    1. Trust the client (vulnerable to hacking)
    2. Tell the client "Reward is pending" and let them wait for a refresh.
    For this MVP, we will still grant it instantly for UX, but in production, we should only return success if SSV completed.
    """
    user_id = event.get("requestContext", {}).get("authorizer", {}).get("lambda", {}).get("userId", "")
    if not user_id:
        return api_response(401, {"error": "unauthorized"})

    body = json.loads(event.get("body", "{}")) if isinstance(event.get("body"), str) else event.get("body", {})
    reward_type = body.get("rewardType", "energy")
    
    allow_client_grant = os.environ.get("ALLOW_CLIENT_AD_REWARD", "false").lower() == "true"
    if not allow_client_grant:
        return api_response(202, {
            "rewardGranted": False,
            "pendingVerification": True,
            "message": "Waiting for server-side ad verification.",
        })

    user = get_or_create_user(user_id)

    if reward_type == "energy":
        new_energy = user["energy"] + 1
        update_user(user_id, {"energy": new_energy})
        return api_response(200, {
            "rewardGranted": True,
            "energy": new_energy,
            "message": "+1 Energy! Get back to fixing! (Client-Side Granted)",
        })
    elif reward_type == "cooldown":
        session_id = body.get("sessionId")
        if not session_id:
            return api_response(400, {"error": "sessionId required for cooldown reward"})
            
        from db import get_session, update_session
        session = get_session(session_id)
        if not session or session["userId"] != user_id:
            return api_response(404, {"error": "session_not_found"})
            
        cooldown_ends_at = session.get("cooldownEndsAt")
        now = __import__("datetime").datetime.now(__import__("datetime").timezone.utc).timestamp()
        
        if cooldown_ends_at and cooldown_ends_at > now:
            new_cooldown = cooldown_ends_at - 3600
            if new_cooldown <= now:
                new_limit = session.get("messageLimit", 18) + 18
                update_session(session_id, {"cooldownEndsAt": None, "messageLimit": new_limit})
                return api_response(200, {
                    "rewardGranted": True,
                    "cooldownCleared": True,
                    "messageLimit": new_limit,
                    "message": "Usta kendine geldi! (Client-Side)",
                })
            else:
                update_session(session_id, {"cooldownEndsAt": new_cooldown})
                return api_response(200, {
                    "rewardGranted": True,
                    "cooldownCleared": False,
                    "cooldownEndsAt": new_cooldown,
                    "message": "Usta rahatladı. (Client-Side)",
                })
        else:
            return api_response(400, {"error": "no_active_cooldown"})
    else:
        return api_response(400, {"error": "invalid_reward_type"})
