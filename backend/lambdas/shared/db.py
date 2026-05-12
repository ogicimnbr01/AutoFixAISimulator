"""
DynamoDB helper functions for AutoFix AI Simulator backend.
All table operations centralized here.
"""
import os
import boto3
from datetime import datetime, timezone, timedelta
import uuid
import hashlib
from boto3.dynamodb.conditions import Key, Attr

dynamodb = boto3.resource("dynamodb")

TABLE_USERS = os.environ.get("TABLE_USERS", "MechanicMaster_Users")
TABLE_SESSIONS = os.environ.get("TABLE_SESSIONS", "MechanicMaster_Sessions")
TABLE_DAILY_RESETS = os.environ.get("TABLE_DAILY_RESETS", "MechanicMaster_DailyResets")
TABLE_LEADERBOARD = os.environ.get("TABLE_LEADERBOARD", "MechanicMaster_Leaderboard")
TABLE_REPORTS = os.environ.get("TABLE_REPORTS", "MechanicMaster_Reports")
TABLE_TRANSACTIONS = os.environ.get("TABLE_TRANSACTIONS", "MechanicMaster_Transactions")
TABLE_DEVICE_STATES = os.environ.get("TABLE_DEVICE_STATES", "MechanicMaster_DeviceStates")


def _now_iso():
    return datetime.now(timezone.utc).isoformat()


def _today_str():
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def hash_install_id(install_id: str | None) -> str | None:
    if not install_id:
        return None
    normalized = install_id.strip()
    if len(normalized) < 12:
        return None
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


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

    # 4. Delete game sessions and archived chats.
    sessions_table = dynamodb.Table(TABLE_SESSIONS)
    session_result = sessions_table.query(
        IndexName="userId-index",
        KeyConditionExpression=Key("userId").eq(user_id),
        ProjectionExpression="sessionId",
    )
    for item in session_result.get("Items", []):
        sessions_table.delete_item(Key={"sessionId": item["sessionId"]})

    # 5. Delete user reports.
    reports_table = dynamodb.Table(TABLE_REPORTS)
    report_result = reports_table.query(
        IndexName="userId-index",
        KeyConditionExpression=Key("userId").eq(user_id),
        ProjectionExpression="reportId",
    )
    for item in report_result.get("Items", []):
        reports_table.delete_item(Key={"reportId": item["reportId"]})


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


def archive_session(session_id: str, updates: dict):
    """Mark a solved session as archived and remove short-lived TTL."""
    table = dynamodb.Table(TABLE_SESSIONS)
    expr_parts = []
    expr_values = {}
    expr_names = {"#ttl": "expiresAt"}
    for i, (key, val) in enumerate(updates.items()):
        alias = f"#k{i}"
        placeholder = f":v{i}"
        expr_parts.append(f"{alias} = {placeholder}")
        expr_values[placeholder] = val
        expr_names[alias] = key

    table.update_item(
        Key={"sessionId": session_id},
        UpdateExpression="SET " + ", ".join(expr_parts) + " REMOVE #ttl",
        ExpressionAttributeValues=expr_values,
        ExpressionAttributeNames=expr_names,
    )


def get_completed_scenarios(user_id: str) -> list[dict]:
    """Return latest solved session per scenario for a user."""
    table = dynamodb.Table(TABLE_SESSIONS)
    resp = table.query(
        IndexName="userId-index",
        KeyConditionExpression=Key("userId").eq(user_id),
        FilterExpression=Attr("status").eq("solved"),
    )
    latest_by_scenario = {}
    for item in resp.get("Items", []):
        scenario_id = int(item.get("scenarioId", 0))
        if not scenario_id:
            continue
        existing = latest_by_scenario.get(scenario_id)
        if not existing or str(item.get("solvedAt", "")) > str(existing.get("solvedAt", "")):
            latest_by_scenario[scenario_id] = item

    return sorted(
        [
            {
                "scenarioId": scenario_id,
                "sessionId": item["sessionId"],
                "solvedAt": item.get("solvedAt"),
                "messageCount": item.get("messageCount", 0),
            }
            for scenario_id, item in latest_by_scenario.items()
        ],
        key=lambda x: x["scenarioId"],
    )


def get_solved_session_for_scenario(user_id: str, scenario_id: int) -> dict | None:
    """Return the archived solved session for a scenario, if any."""
    table = dynamodb.Table(TABLE_SESSIONS)
    resp = table.query(
        IndexName="userId-index",
        KeyConditionExpression=Key("userId").eq(user_id),
        FilterExpression=Attr("status").eq("solved") & Attr("scenarioId").eq(scenario_id),
    )
    items = resp.get("Items", [])
    if not items:
        return None
    return max(items, key=lambda item: str(item.get("solvedAt", "")))


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
        "archiveViews": 0,
        "archiveViewedScenarioIds": [],
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


# ============== DEVICE ECONOMY STATE ==============

def get_device_state(install_id: str | None) -> dict | None:
    device_hash = hash_install_id(install_id)
    if not device_hash:
        return None
    resp = dynamodb.Table(TABLE_DEVICE_STATES).get_item(Key={"deviceHash": device_hash})
    return resp.get("Item")


def save_device_state_from_user(install_id: str | None, user: dict, daily: dict):
    device_hash = hash_install_id(install_id)
    if not device_hash:
        return

    expires = int((datetime.now(timezone.utc) + timedelta(days=7)).timestamp())
    dynamodb.Table(TABLE_DEVICE_STATES).put_item(Item={
        "deviceHash": device_hash,
        "energy": int(user.get("energy", 0)),
        "casesPlayed": int(daily.get("casesPlayed", 0)),
        "energyUsed": int(daily.get("energyUsed", 0)),
        "archiveViews": int(daily.get("archiveViews", 0)),
        "archiveViewedScenarioIds": daily.get("archiveViewedScenarioIds", []),
        "createdAt": user.get("createdAt"),
        "deletedAt": _now_iso(),
        "expiresAt": expires,
    })


def apply_device_state_to_new_user(install_id: str | None, user: dict):
    state = get_device_state(install_id)
    if not state or user.get("deviceStateApplied"):
        return user

    updates = {
        "energy": min(int(user.get("energy", 0)), int(state.get("energy", 0))),
        "deviceStateApplied": True,
    }
    if state.get("createdAt"):
        updates["createdAt"] = state["createdAt"]
    update_user(user["userId"], updates)

    daily_updates = {
        "casesPlayed": int(state.get("casesPlayed", 0)),
        "energyUsed": int(state.get("energyUsed", 0)),
        "archiveViews": int(state.get("archiveViews", 0)),
        "archiveViewedScenarioIds": state.get("archiveViewedScenarioIds", []),
    }
    update_daily_reset(user["userId"], daily_updates)
    user.update(updates)
    return user


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
        existing_entries = _get_user_leaderboard_entries(table, period, user_id)
        current_score = max([int(item.get("repPoints", 0)) for item in existing_entries] or [0])
        new_score = current_score + 1

        # The score is part of the sort key, so old rows must be replaced.
        # Delete all matching rows to also clean up any duplicates from older versions.
        for item in existing_entries:
            table.delete_item(Key={"period": period, "score_userId": item["score_userId"]})

        table.put_item(Item={
            "period": period,
            "score_userId": f"{str(new_score).zfill(6)}#{user_id}",
            "userId": user_id,
            "displayName": display_name,
            "repPoints": new_score,
        })


def _get_user_leaderboard_entries(table, period: str, user_id: str) -> list:
    """Find existing leaderboard rows for a user in one period."""
    items = []
    query_kwargs = {
        "KeyConditionExpression": "period = :p",
        "FilterExpression": "#uid = :uid",
        "ExpressionAttributeNames": {"#uid": "userId"},
        "ExpressionAttributeValues": {":p": period, ":uid": user_id},
    }

    while True:
        resp = table.query(**query_kwargs)
        items.extend(resp.get("Items", []))
        last_key = resp.get("LastEvaluatedKey")
        if not last_key:
            return items
        query_kwargs["ExclusiveStartKey"] = last_key


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
