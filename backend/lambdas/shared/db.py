"""
DynamoDB helper functions for AutoFix AI Simulator backend.
All table operations centralized here.
"""
import os
import boto3
from datetime import datetime, timezone, timedelta
import uuid

dynamodb = boto3.resource("dynamodb")

TABLE_USERS = os.environ.get("TABLE_USERS", "MechanicMaster_Users")
TABLE_SESSIONS = os.environ.get("TABLE_SESSIONS", "MechanicMaster_Sessions")
TABLE_DAILY_RESETS = os.environ.get("TABLE_DAILY_RESETS", "MechanicMaster_DailyResets")
TABLE_LEADERBOARD = os.environ.get("TABLE_LEADERBOARD", "MechanicMaster_Leaderboard")
TABLE_REPORTS = os.environ.get("TABLE_REPORTS", "MechanicMaster_Reports")
TABLE_TRANSACTIONS = os.environ.get("TABLE_TRANSACTIONS", "MechanicMaster_Transactions")


def _now_iso():
    return datetime.now(timezone.utc).isoformat()


def _today_str():
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


# ============== USERS ==============

def get_or_create_user(user_id: str) -> dict:
    """Get user profile, create if doesn't exist."""
    table = dynamodb.Table(TABLE_USERS)
    resp = table.get_item(Key={"userId": user_id})
    if "Item" in resp:
        return resp["Item"]

    # New user
    user = {
        "userId": user_id,
        "displayName": f"Mechanic_{user_id[:6]}",
        "energy": 5,
        "streakCount": 0,
        "hintCredits": 1,
        "totalRepairs": 0,
        "subscription": "free",
        "createdAt": _now_iso(),
        "lastLoginDate": _today_str(),
        "languageCode": "tr",
        "languageSource": "profile",
    }
    table.put_item(Item=user)
    return user


def calculate_max_energy(created_at: str) -> dict:
    """Graduated honeymoon energy system.
    Day 1-3: 5 energy/day (hook phase)
    Day 4-7: 4 energy/day (transition)
    Day 8+:  3 energy/day (real economy)
    """
    try:
        install_dt = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
        days = (datetime.now(timezone.utc) - install_dt).days
    except (ValueError, TypeError):
        days = 999  # Fallback: assume veteran

    if days <= 2:      # Day 1-3
        max_energy = 5
    elif days <= 6:    # Day 4-7
        max_energy = 4
    else:              # Day 8+
        max_energy = 3

    return {"maxEnergy": max_energy, "daysSinceInstall": days}


def update_user(user_id: str, updates: dict):
    """Update specific user fields."""
    table = dynamodb.Table(TABLE_USERS)
    expr_parts = []
    expr_values = {}
    expr_names = {}
    for i, (key, val) in enumerate(updates.items()):
        alias = f"#k{i}"
        placeholder = f":v{i}"
        expr_parts.append(f"{alias} = {placeholder}")
        expr_values[placeholder] = val
        expr_names[alias] = key

    table.update_item(
        Key={"userId": user_id},
        UpdateExpression="SET " + ", ".join(expr_parts),
        ExpressionAttributeValues=expr_values,
        ExpressionAttributeNames=expr_names,
    )


def delete_user_data(user_id: str):
    """Delete all data for a user across all tables."""
    # 1. Delete main user profile
    dynamodb.Table(TABLE_USERS).delete_item(Key={"userId": user_id})

    # 2. Delete daily resets — key is userId_date (e.g. uid#2026-05-10)
    # We need to scan/query by prefix since we don't know the exact dates
    daily_table = dynamodb.Table(TABLE_DAILY_RESETS)
    result = daily_table.scan(
        FilterExpression="begins_with(userId_date, :uid)",
        ExpressionAttributeValues={":uid": f"{user_id}#"},
        ProjectionExpression="userId_date",
    )
    for item in result.get("Items", []):
        daily_table.delete_item(Key={"userId_date": item["userId_date"]})

    # 3. Delete leaderboard entries across all periods
    lb_table = dynamodb.Table(TABLE_LEADERBOARD)
    lb_result = lb_table.scan(
        FilterExpression="#uid = :uid",
        ExpressionAttributeNames={"#uid": "userId"},
        ExpressionAttributeValues={":uid": user_id},
        ProjectionExpression="#uid, period, score_userId",
    )
    for item in lb_result.get("Items", []):
        lb_table.delete_item(
            Key={"period": item["period"], "score_userId": item["score_userId"]}
        )


# ============== SESSIONS ==============

def create_session(user_id: str, scenario_id: int) -> dict:
    """Create a new game session."""
    table = dynamodb.Table(TABLE_SESSIONS)
    session_id = str(uuid.uuid4())
    expires = int((datetime.now(timezone.utc) + timedelta(hours=24)).timestamp())

    session = {
        "sessionId": session_id,
        "userId": user_id,
        "scenarioId": scenario_id,
        "messages": [],
        "messageCount": 0,
        "status": "active",
        "startedAt": _now_iso(),
        "solvedAt": None,
        "expiresAt": expires,
    }
    table.put_item(Item=session)
    return session


def get_session(session_id: str) -> dict | None:
    """Get session by ID."""
    table = dynamodb.Table(TABLE_SESSIONS)
    resp = table.get_item(Key={"sessionId": session_id})
    return resp.get("Item")


def update_session(session_id: str, updates: dict):
    """Update session fields."""
    table = dynamodb.Table(TABLE_SESSIONS)
    expr_parts = []
    expr_values = {}
    expr_names = {}
    for i, (key, val) in enumerate(updates.items()):
        alias = f"#k{i}"
        placeholder = f":v{i}"
        expr_parts.append(f"{alias} = {placeholder}")
        expr_values[placeholder] = val
        expr_names[alias] = key

    table.update_item(
        Key={"sessionId": session_id},
        UpdateExpression="SET " + ", ".join(expr_parts),
        ExpressionAttributeValues=expr_values,
        ExpressionAttributeNames=expr_names,
    )


# ============== DAILY RESETS ==============

def get_daily_reset(user_id: str) -> dict:
    """Get or create today's daily reset record."""
    table = dynamodb.Table(TABLE_DAILY_RESETS)
    key = f"{user_id}#{_today_str()}"
    resp = table.get_item(Key={"userId_date": key})
    if "Item" in resp:
        return resp["Item"]

    expires = int((datetime.now(timezone.utc) + timedelta(hours=48)).timestamp())
    record = {
        "userId_date": key,
        "energyUsed": 0,
        "casesPlayed": 0,
        "loginBonusClaimed": False,
        "hintBonusClaimed": False,
        "expiresAt": expires,
    }
    table.put_item(Item=record)
    return record


def update_daily_reset(user_id: str, updates: dict):
    """Update today's daily reset record."""
    table = dynamodb.Table(TABLE_DAILY_RESETS)
    key = f"{user_id}#{_today_str()}"
    expr_parts = []
    expr_values = {}
    expr_names = {}
    for i, (k, v) in enumerate(updates.items()):
        alias = f"#k{i}"
        placeholder = f":v{i}"
        expr_parts.append(f"{alias} = {placeholder}")
        expr_values[placeholder] = v
        expr_names[alias] = k

    table.update_item(
        Key={"userId_date": key},
        UpdateExpression="SET " + ", ".join(expr_parts),
        ExpressionAttributeValues=expr_values,
        ExpressionAttributeNames=expr_names,
    )


# ============== LEADERBOARD ==============

def add_leaderboard_point(user_id: str, display_name: str):
    """Add +1 reputation point to weekly, monthly, yearly leaderboards."""
    table = dynamodb.Table(TABLE_LEADERBOARD)
    now = datetime.now(timezone.utc)

    periods = [
        f"weekly#{now.strftime('%Y-W%V')}",
        f"monthly#{now.strftime('%Y-%m')}",
        f"yearly#{now.strftime('%Y')}",
    ]

    for period in periods:
        # Try to update existing entry
        try:
            resp = table.update_item(
                Key={"period": period, "score_userId": f"temp#{user_id}"},
                UpdateExpression="SET repPoints = if_not_exists(repPoints, :zero) + :one, displayName = :name, userId = :uid",
                ExpressionAttributeValues={":one": 1, ":zero": 0, ":name": display_name, ":uid": user_id},
                ReturnValues="UPDATED_NEW",
            )
            # Update the sort key with new padded score
            new_score = int(resp["Attributes"]["repPoints"])
            padded = str(new_score).zfill(6)

            # Delete old entry and create new with updated sort key
            table.delete_item(Key={"period": period, "score_userId": f"temp#{user_id}"})
            table.put_item(Item={
                "period": period,
                "score_userId": f"{padded}#{user_id}",
                "userId": user_id,
                "displayName": display_name,
                "repPoints": new_score,
            })
        except Exception:
            # First time entry
            table.put_item(Item={
                "period": period,
                "score_userId": f"000001#{user_id}",
                "userId": user_id,
                "displayName": display_name,
                "repPoints": 1,
            })


def get_leaderboard(period: str, limit: int = 100) -> list:
    """Get top N players for a given period."""
    table = dynamodb.Table(TABLE_LEADERBOARD)
    resp = table.query(
        KeyConditionExpression="period = :p",
        ExpressionAttributeValues={":p": period},
        ScanIndexForward=False,  # Descending (highest first)
        Limit=limit,
    )
    results = []
    for i, item in enumerate(resp.get("Items", []), 1):
        results.append({
            "rank": i,
            "displayName": item.get("displayName", "Unknown"),
            "repPoints": int(item.get("repPoints", 0)),
        })
    return results

# ============== REPORTS ==============

def create_report(user_id: str, session_id: str, message_content: str, reason: str):
    table = dynamodb.Table(TABLE_REPORTS)
    report_id = str(uuid.uuid4())
    table.put_item(Item={
        "reportId": report_id,
        "userId": user_id,
        "sessionId": session_id,
        "messageContent": message_content,
        "reason": reason,
        "createdAt": _now_iso(),
    })

# ============== TRANSACTIONS ==============

def check_transaction(transaction_id: str) -> bool:
    """Idempotency check: Returns True if this is a NEW transaction, False if already processed."""
    table = dynamodb.Table(TABLE_TRANSACTIONS)
    import time
    expire_at = int(time.time()) + (7 * 24 * 3600)  # 7 days TTL
    
    try:
        table.put_item(
            Item={
                "transactionId": transaction_id,
                "expiresAt": expire_at,
                "createdAt": _now_iso()
            },
            ConditionExpression="attribute_not_exists(transactionId)"
        )
        return True
    except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
        return False
