"""
Ad Reward Handler Lambda — POST /ad/reward, GET /webhook/admob-ssv
Validates rewarded ad completion and grants energy.
"""
import json
import sys
import os
import base64
import time
import urllib.request
import urllib.parse

sys.path.insert(0, "/opt")

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.exceptions import InvalidSignature

from db import get_or_create_user, update_user, check_transaction
from response import api_response

ADMOB_KEYS_URL = "https://www.gstatic.com/admob/reward/verifier-keys.json"
_KEY_CACHE = {"expires_at": 0, "keys": {}}


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
    transaction_id = query_params.get("transaction_id")
    user_id_param = query_params.get("user_id")
    
    # 1. IP Whitelist / Basic Rate Limit Check
    source_ip = event.get("requestContext", {}).get("http", {}).get("sourceIp", "")
    # In production, verify against Google's IP ranges (e.g. 8.8.8.8 or specific AdMob ranges). 
    # For now, we log it to monitor brute-force attempts.
    print(f"[ADMOB_SSV] Request from IP: {source_ip}")
    
    if not custom_data:
        print("[ADMOB_SSV] Error: Missing custom_data. Ignoring silently to prevent retries.")
        # Edge Case Handled: Return 200 so AdMob stops retrying this broken payload
        return api_response(200, {"status": "ignored", "reason": "missing_custom_data"})

    if not signature or not key_id or not transaction_id:
        print("[ADMOB_SSV] Error: Missing signature, key_id, or transaction_id.")
        return api_response(200, {"status": "ignored", "reason": "missing_verification_fields"})

    raw_query = event.get("rawQueryString") or _rebuild_raw_query(event)
    if not _verify_admob_signature(raw_query, signature, key_id):
        print("[ADMOB_SSV] Error: Invalid signature.")
        return api_response(200, {"status": "ignored", "reason": "invalid_signature"})

    if not check_transaction(f"admob:{transaction_id}"):
        print(f"[ADMOB_SSV] Duplicate transaction ignored: {transaction_id}")
        return api_response(200, {"status": "duplicate"})

    # Parse custom_data (format: "userId|rewardType|sessionId")
    parts = custom_data.split("|")
    user_id = parts[0]
    reward_type = parts[1] if len(parts) > 1 else "energy"
    if user_id_param and user_id_param != user_id:
        print("[ADMOB_SSV] user_id/custom_data mismatch.")
        return api_response(200, {"status": "ignored", "reason": "user_mismatch"})
    
    try:
        user = get_or_create_user(user_id)
        if not user:
            raise ValueError("User not found")
    except Exception as e:
        print(f"[ADMOB_SSV] Invalid/Unknown userId '{user_id}'. Error: {e}")
        # Return 200 silently to prevent infinite retries for a deleted/invalid user
        return api_response(200, {"status": "ignored", "reason": "invalid_user"})
    
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


def _verify_admob_signature(raw_query: str, signature: str, key_id: str) -> bool:
    """Verify AdMob SSV signature using Google's rotating ECDSA public keys."""
    try:
        marker = "signature="
        signature_index = raw_query.index(marker)
        content_to_verify = raw_query[:signature_index]
        if content_to_verify.endswith("&"):
            content_to_verify = content_to_verify[:-1]
        sig = _urlsafe_b64decode(signature)
        public_key = _get_admob_public_keys().get(str(key_id))
        if public_key is None:
            print(f"[ADMOB_SSV] Unknown key_id: {key_id}")
            return False

        candidates = [
            content_to_verify,
            urllib.parse.unquote(content_to_verify),
        ]
        for candidate in dict.fromkeys(candidates):
            try:
                public_key.verify(
                    sig,
                    candidate.encode("utf-8"),
                    ec.ECDSA(hashes.SHA256()),
                )
                return True
            except InvalidSignature:
                continue
        print("[ADMOB_SSV] Signature did not match raw or decoded query content.")
        return False
    except (ValueError, InvalidSignature) as e:
        print(f"[ADMOB_SSV] Signature verification failed: {e}")
        return False
    except Exception as e:
        print(f"[ADMOB_SSV] Signature verification error: {e}")
        return False


def _get_admob_public_keys():
    now = int(time.time())
    if _KEY_CACHE["keys"] and _KEY_CACHE["expires_at"] > now:
        return _KEY_CACHE["keys"]

    with urllib.request.urlopen(ADMOB_KEYS_URL, timeout=5) as response:
        payload = json.loads(response.read().decode("utf-8"))

    keys = {}
    for item in payload.get("keys", []):
        key_id = str(item.get("keyId"))
        if key_id == "None":
            continue
        if item.get("pem"):
            public_key = serialization.load_pem_public_key(item["pem"].encode("utf-8"))
        elif item.get("base64"):
            der = base64.b64decode(item["base64"])
            public_key = serialization.load_der_public_key(der)
        else:
            continue
        keys[key_id] = public_key

    _KEY_CACHE["keys"] = keys
    _KEY_CACHE["expires_at"] = now + 23 * 60 * 60
    return keys


def _urlsafe_b64decode(value: str) -> bytes:
    padded = value + "=" * (-len(value) % 4)
    return base64.urlsafe_b64decode(padded)


def _rebuild_raw_query(event):
    # Fallback for local/manual invocations; API Gateway normally provides rawQueryString.
    params = event.get("queryStringParameters") or {}
    return "&".join(f"{key}={value}" for key, value in params.items())


def handle_client_reward(event):
    """
    Called by the app immediately after watching an ad.
    In production this never grants directly; it only lets the app wait while
    AdMob SSV performs the real server-side reward grant.
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
