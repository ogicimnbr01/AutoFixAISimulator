"""
Firebase Auth Lambda Authorizer for API Gateway.
Validates Firebase ID tokens and extracts userId.
"""
import json
import sys
sys.path.insert(0, "/opt")
from google.oauth2 import id_token
from google.auth.transport import requests

# Firebase Project ID from google-services.json
PROJECT_ID = "mechanic-master-64642"

def lambda_handler(event, context):
    """API Gateway v2 Lambda Authorizer (simple response)."""
    try:
        token = _extract_token(event)
        if not token:
            print("No token found")
            return {"isAuthorized": False}

        # Verify the Firebase ID token
        request = requests.Request()
        claims = id_token.verify_firebase_token(token, request, audience=PROJECT_ID)

        print(f"Authorized user: {claims['sub']}")
        return {
            "isAuthorized": True,
            "context": {
                "userId": claims["sub"],  # Firebase UID
            }
        }
    except Exception as e:
        print(f"Auth error: {e}")
        return {"isAuthorized": False}

def _extract_token(event):
    """Extract Bearer token from Authorization header."""
    headers = event.get("headers", {})
    auth = headers.get("authorization", "") or headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        return auth[7:]
    return None

