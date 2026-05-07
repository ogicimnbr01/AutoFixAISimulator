"""
Ad Reward Handler Lambda — POST /ad/reward
Validates rewarded ad completion and grants energy.
"""
import json
import sys

sys.path.insert(0, "/opt")
from db import get_or_create_user, update_user
from response import api_response


def lambda_handler(event, context):
    user_id = event.get("requestContext", {}).get("authorizer", {}).get("lambda", {}).get("userId", "")
    if not user_id:
        return api_response(401, {"error": "unauthorized"})

    body = json.loads(event.get("body", "{}")) if isinstance(event.get("body"), str) else event.get("body", {})
    reward_type = body.get("rewardType", "energy")  # "energy" or "cooldown"

    # TODO: Validate AdMob SSVC (Server-Side Verification Callback)
    # For now, trust the client. In production, verify with AdMob server.
    ad_token = body.get("adToken", "")

    user = get_or_create_user(user_id)

    if reward_type == "energy":
        new_energy = user["energy"] + 1
        update_user(user_id, {"energy": new_energy})
        return api_response(200, {
            "rewardGranted": True,
            "energy": new_energy,
            "message": "+1 Energy! Get back to fixing!",
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
            # Reduce by 1 hour (3600 seconds)
            new_cooldown = cooldown_ends_at - 3600
            
            if new_cooldown <= now:
                new_limit = session.get("messageLimit", 18) + 18
                update_session(session_id, {"cooldownEndsAt": None, "messageLimit": new_limit})
                return api_response(200, {
                    "rewardGranted": True,
                    "cooldownCleared": True,
                    "messageLimit": new_limit,
                    "message": "Usta kendine geldi! 18 mesaj hakkın daha var.",
                })
            else:
                update_session(session_id, {"cooldownEndsAt": new_cooldown})
                return api_response(200, {
                    "rewardGranted": True,
                    "cooldownCleared": False,
                    "cooldownEndsAt": new_cooldown,
                    "message": "Usta rahatladı ama biraz daha dinlenmesi lazım.",
                })
        else:
            return api_response(400, {"error": "no_active_cooldown"})
    else:
        return api_response(400, {"error": "invalid_reward_type"})

