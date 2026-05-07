"""
Leaderboard Handler Lambda — GET /leaderboard/{period}
Returns top 100 players for weekly, monthly, or yearly periods.
"""
import json
import sys
from datetime import datetime, timezone

sys.path.insert(0, "/opt")
from db import get_leaderboard
from response import api_response


def lambda_handler(event, context):
    user_id = event.get("requestContext", {}).get("authorizer", {}).get("lambda", {}).get("userId", "")
    if not user_id:
        return api_response(401, {"error": "unauthorized"})

    # Get period from path: /leaderboard/weekly or /leaderboard/monthly or /leaderboard/yearly
    path_params = event.get("pathParameters", {}) or {}
    period_type = path_params.get("period", "weekly")

    now = datetime.now(timezone.utc)
    period_map = {
        "weekly": f"weekly#{now.strftime('%Y-W%V')}",
        "monthly": f"monthly#{now.strftime('%Y-%m')}",
        "yearly": f"yearly#{now.strftime('%Y')}",
    }

    if period_type not in period_map:
        return api_response(400, {"error": "invalid_period", "valid": ["weekly", "monthly", "yearly"]})

    period_key = period_map[period_type]
    rankings = get_leaderboard(period_key, limit=100)

    return api_response(200, {
        "period": period_type,
        "periodKey": period_key,
        "rankings": rankings,
        "totalPlayers": len(rankings),
    })

