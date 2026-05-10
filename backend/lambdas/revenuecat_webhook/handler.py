"""
RevenueCat Webhook Handler — POST /webhook/revenuecat
Processes server-to-server notifications from RevenueCat for in-app purchases and subscriptions.
"""
import json
import sys
import os
sys.path.insert(0, "/opt")
from db import get_or_create_user, update_user, check_transaction
from response import api_response

def lambda_handler(event, context):
    try:
        # Check authorization header if you configured a webhook auth token in RevenueCat
        # auth_header = event.get("headers", {}).get("authorization", "")
        # if auth_header != "Bearer YOUR_SECRET_TOKEN":
        #     return api_response(401, {"error": "unauthorized"})

        body = json.loads(event.get("body", "{}"))
        rc_event = body.get("event", {})
        
        event_type = rc_event.get("type")
        user_id = rc_event.get("app_user_id")
        product_id = rc_event.get("product_id")
        transaction_id = rc_event.get("transaction_id", rc_event.get("id")) # fallback to event id
        
        if not user_id or not product_id or not event_type or not transaction_id:
            return api_response(400, {"error": "Invalid payload: missing fields"})
            
        # Idempotency Check
        if not check_transaction(transaction_id):
            print(f"[REVENUECAT] Duplicate transaction ignored: {transaction_id}")
            return api_response(200, {"status": "success", "message": "Already processed"})
            
        print(f"[REVENUECAT] Event: {event_type} | User: {user_id} | Product: {product_id} | Transaction: {transaction_id}")
        
        user = get_or_create_user(user_id)
        updates = {}
        
        # Consumable Hint Packages
        if event_type == "NON_RENEWING_PURCHASE":
            hints_to_add = 0
            if "hint_pack_3" in product_id:
                hints_to_add = 3
            elif "hint_pack_10" in product_id:
                hints_to_add = 10
            elif "hint_pack_25" in product_id:
                hints_to_add = 25
            elif "hint_pack_50" in product_id:
                hints_to_add = 50
                
            if hints_to_add > 0:
                current_hints = user.get("hintCredits", 0)
                updates["hintCredits"] = current_hints + hints_to_add
                print(f"[REVENUECAT] Added {hints_to_add} hints. New total: {updates['hintCredits']}")
                
        # Subscriptions
        elif event_type in ["INITIAL_PURCHASE", "RENEWAL"]:
            if "pro" in product_id:
                updates["subscription"] = "pro"
                print("[REVENUECAT] User upgraded to PRO subscription")
                
        elif event_type in ["CANCELLATION", "EXPIRATION"]:
            if "pro" in product_id:
                updates["subscription"] = "free"
                print("[REVENUECAT] User PRO subscription expired/cancelled")
                
        if updates:
            update_user(user_id, updates)
            
        return api_response(200, {"status": "success", "message": "Webhook processed successfully"})
        
    except Exception as e:
        print(f"[REVENUECAT_ERROR] {e}")
        return api_response(500, {"error": "Internal server error"})
