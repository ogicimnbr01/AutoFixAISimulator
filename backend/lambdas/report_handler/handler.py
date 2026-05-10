"""
Report Handler Lambda — POST /report
Stores user reports of inappropriate AI messages in DynamoDB.
"""
import json
import sys
sys.path.insert(0, "/opt")
from db import create_report
from response import api_response

def lambda_handler(event, context):
    user_id = event.get("requestContext", {}).get("authorizer", {}).get("lambda", {}).get("userId", "")
    if not user_id:
        return api_response(401, {"error": "unauthorized"})

    try:
        body = json.loads(event.get("body", "{}"))
        session_id = body.get("sessionId")
        message_content = body.get("messageContent")
        reason = body.get("reason", "Inappropriate AI behavior")

        if not session_id or not message_content:
            return api_response(400, {"error": "missing_parameters"})

        create_report(user_id, session_id, message_content, reason)
        return api_response(200, {"status": "success", "message": "Report logged."})
    except Exception as e:
        print(f"[ERROR] Failed to log report: {e}")
        return api_response(500, {"error": "internal_error"})
