"""
User Handler Lambda — GET /user/profile, POST /user/login-bonus
Profile management and daily login bonus.
"""
import sys
sys.path.insert(0, "/opt")
from db import get_or_create_user, update_user, get_daily_reset, update_daily_reset, calculate_max_energy
from response import api_response


def lambda_handler(event, context):
    path = event.get("rawPath", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    user_id = event.get("requestContext", {}).get("authorizer", {}).get("lambda", {}).get("userId", "")

    if not user_id:
        return api_response(401, {"error": "unauthorized"})

    if path == "/user/profile" and method == "GET":
        return handle_profile(user_id)
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
