"""
User Handler Lambda — GET /user/profile, POST /user/login-bonus
Profile management and daily login bonus.
"""
import sys
sys.path.insert(0, "/opt")
from db import get_or_create_user, update_user, get_daily_reset, update_daily_reset, calculate_max_energy, delete_user_data
import json
from response import api_response


def lambda_handler(event, context):
    path = event.get("rawPath", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    user_id = event.get("requestContext", {}).get("authorizer", {}).get("lambda", {}).get("userId", "")

    if not user_id:
        return api_response(401, {"error": "unauthorized"})

    if path == "/user/profile" and method == "GET":
        return handle_profile(user_id)
    elif path == "/user/profile" and method == "PUT":
        return handle_update_profile(user_id, event)
    elif path == "/user/profile" and method == "DELETE":
        return handle_delete_profile(user_id)
    elif path == "/user/merge" and method == "POST":
        return handle_merge_profile(user_id, event)
    elif path == "/user/login-bonus" and method == "POST":
        return handle_login_bonus(user_id)
    else:
        return api_response(404, {"error": "not_found"})


def handle_profile(user_id):
    user = get_or_create_user(user_id)
    daily = get_daily_reset(user_id)
    energy_info = calculate_max_energy(user.get("createdAt", ""))
    return api_response(200, {
        "displayName": user["displayName"],
        "energy": user["energy"],
        "streakCount": user["streakCount"],
        "hintCredits": user["hintCredits"],
        "totalRepairs": user["totalRepairs"],
        "subscription": user["subscription"],
        "todayCasesPlayed": daily["casesPlayed"],
        "loginBonusClaimed": daily["loginBonusClaimed"],
        "maxEnergy": energy_info["maxEnergy"],
        "daysSinceInstall": energy_info["daysSinceInstall"],
        "installDate": user.get("createdAt", ""),
    })


def handle_update_profile(user_id, event):
    try:
        body = json.loads(event.get("body", "{}"))
    except Exception:
        body = {}
        
    display_name = body.get("displayName")
    if not display_name or len(display_name.strip()) == 0:
        return api_response(400, {"error": "invalid_name", "message": "Display name cannot be empty."})
        
    display_name = display_name.strip()[:20] # Limit to 20 characters
    update_user(user_id, {"displayName": display_name})
    
    return api_response(200, {"success": True, "displayName": display_name})


def handle_login_bonus(user_id):
    user = get_or_create_user(user_id)
    daily = get_daily_reset(user_id)

    if daily["loginBonusClaimed"]:
        return api_response(400, {"error": "already_claimed", "message": "Login bonus already claimed today."})

    new_energy = user["energy"] + 1
    new_hints = user["hintCredits"] + 1

    update_user(user_id, {"energy": new_energy, "hintCredits": new_hints})
    update_daily_reset(user_id, {"loginBonusClaimed": True})

    return api_response(200, {
        "bonusClaimed": True,
        "energy": new_energy,
        "hintCredits": new_hints,
        "message": "Welcome back! +1 Energy, +1 Hint Credit",
    })


def handle_merge_profile(user_id, event):
    try:
        body = json.loads(event.get("body", "{}"))
    except Exception:
        return api_response(400, {"error": "invalid_body"})

    local_data = body.get("localData", {})
    old_anonymous_id = body.get("oldAnonymousId")

    if not local_data or not old_anonymous_id:
        return api_response(400, {"error": "missing_data"})

    cloud_user = get_or_create_user(user_id)

    merged_updates = {
        "totalRepairs": max(cloud_user.get("totalRepairs", 0), local_data.get("totalRepairs", 0)),
        "streakCount": max(cloud_user.get("streakCount", 0), local_data.get("streakCount", 0)),
        "hintCredits": cloud_user.get("hintCredits", 0) + local_data.get("hintCredits", 0),
        "energy": max(cloud_user.get("energy", 0), local_data.get("energy", 0))
    }

    # Apply updates to the cloud user
    update_user(user_id, merged_updates)

    # Clean up the orphaned anonymous user
    try:
        delete_user_data(old_anonymous_id)
    except Exception as e:
        print(f"Warning: Failed to delete old anonymous user {old_anonymous_id}: {e}")

    return api_response(200, {"success": True, "merged": merged_updates})


def handle_delete_profile(user_id):
    try:
        delete_user_data(user_id)
        return api_response(200, {"success": True, "message": "User data deleted successfully."})
    except Exception as e:
        print(f"Error deleting user {user_id}: {e}")
        return api_response(500, {"error": "delete_failed"})

