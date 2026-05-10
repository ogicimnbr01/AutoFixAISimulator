#!/usr/bin/env python3
"""
Create/reuse a Firebase test user token for AutoFix QA scripts.

Default mode creates one persistent anonymous Firebase user and stores only its
refresh token locally in tester/.firebase_test_user.json. Later runs refresh the
same user and print a fresh ID token for prod_smoke_qa.py.

Examples:
  python tester/firebase_test_token.py
  python tester/firebase_test_token.py --write-powershell
  python tester/firebase_test_token.py --run-smoke
  python tester/firebase_test_token.py --email qa@example.com --password "..." --create
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any
from urllib import error, parse, request


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_FIREBASE_CONFIG = ROOT / "app" / "android" / "app" / "google-services.json"
DEFAULT_STORE = Path(__file__).resolve().parent / ".firebase_test_user.json"
DEFAULT_PS1 = Path(__file__).resolve().parent / ".autofix_token.ps1"


class FirebaseTokenError(Exception):
    pass


def load_api_key(config_path: Path) -> str:
    env_key = os.environ.get("FIREBASE_WEB_API_KEY")
    if env_key:
        return env_key

    try:
        config = json.loads(config_path.read_text(encoding="utf-8-sig"))
        clients = config.get("client", [])
        api_keys = clients[0].get("api_key", []) if clients else []
        key = api_keys[0].get("current_key") if api_keys else None
    except Exception as exc:
        raise FirebaseTokenError(f"Could not read Firebase API key from {config_path}: {exc}") from exc

    if not key:
        raise FirebaseTokenError(
            "Firebase API key not found. Set FIREBASE_WEB_API_KEY or check google-services.json."
        )
    return key


def post_json(url: str, payload: dict[str, Any]) -> dict[str, Any]:
    data = json.dumps(payload).encode("utf-8")
    req = request.Request(
        url,
        data=data,
        method="POST",
        headers={"Content-Type": "application/json"},
    )
    try:
        with request.urlopen(req, timeout=45) as res:
            return json.loads(res.read().decode("utf-8"))
    except error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        try:
            body = json.loads(raw)
            message = body.get("error", {}).get("message", raw)
        except json.JSONDecodeError:
            message = raw
        raise FirebaseTokenError(f"Firebase HTTP {exc.code}: {message}") from exc


def create_anonymous_user(api_key: str) -> dict[str, Any]:
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={api_key}"
    return post_json(url, {"returnSecureToken": True})


def create_email_user(api_key: str, email: str, password: str) -> dict[str, Any]:
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={api_key}"
    return post_json(
        url,
        {
            "email": email,
            "password": password,
            "returnSecureToken": True,
        },
    )


def sign_in_email_user(api_key: str, email: str, password: str) -> dict[str, Any]:
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
    return post_json(
        url,
        {
            "email": email,
            "password": password,
            "returnSecureToken": True,
        },
    )


def refresh_id_token(api_key: str, refresh_token: str) -> dict[str, Any]:
    url = f"https://securetoken.googleapis.com/v1/token?key={api_key}"
    data = parse.urlencode(
        {
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
        }
    ).encode("utf-8")
    req = request.Request(
        url,
        data=data,
        method="POST",
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    try:
        with request.urlopen(req, timeout=45) as res:
            body = json.loads(res.read().decode("utf-8"))
    except error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        raise FirebaseTokenError(f"Firebase refresh HTTP {exc.code}: {raw}") from exc

    return {
        "idToken": body["id_token"],
        "refreshToken": body["refresh_token"],
        "localId": body["user_id"],
        "expiresIn": body.get("expires_in"),
        "isNewUser": False,
    }


def load_store(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def save_store(path: Path, auth: dict[str, Any], account_type: str, email: str | None) -> None:
    path.write_text(
        json.dumps(
            {
                "accountType": account_type,
                "email": email,
                "localId": auth.get("localId"),
                "refreshToken": auth.get("refreshToken"),
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )


def write_powershell(path: Path, token: str) -> None:
    path.write_text(f'$env:AUTOFIX_AUTH_TOKEN="{token}"\n', encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Get a Firebase ID token for AutoFix prod QA scripts.",
    )
    parser.add_argument("--config", type=Path, default=DEFAULT_FIREBASE_CONFIG)
    parser.add_argument("--store", type=Path, default=DEFAULT_STORE)
    parser.add_argument("--email", default=os.environ.get("AUTOFIX_TEST_EMAIL"))
    parser.add_argument("--password", default=os.environ.get("AUTOFIX_TEST_PASSWORD"))
    parser.add_argument("--create", action="store_true", help="Create email/password user if provided.")
    parser.add_argument("--reset", action="store_true", help="Ignore stored refresh token and create/sign in again.")
    parser.add_argument("--write-powershell", action="store_true", help="Write tester/.autofix_token.ps1.")
    parser.add_argument("--ps1-path", type=Path, default=DEFAULT_PS1)
    parser.add_argument(
        "--run-smoke",
        action="store_true",
        help="Run prod_smoke_qa.py with this token. This can consume prod energy/stats.",
    )
    parser.add_argument("--smoke-scenarios", default="1,2,3")
    parser.add_argument("--quiet", action="store_true", help="Print only the ID token.")
    args = parser.parse_args()

    try:
        api_key = load_api_key(args.config)

        stored = None if args.reset else load_store(args.store)
        if stored and stored.get("refreshToken"):
            auth = refresh_id_token(api_key, stored["refreshToken"])
            account_type = stored.get("accountType", "anonymous")
            email = stored.get("email")
        elif args.email or args.password:
            if not args.email or not args.password:
                raise FirebaseTokenError("--email and --password must be used together.")
            auth = (
                create_email_user(api_key, args.email, args.password)
                if args.create
                else sign_in_email_user(api_key, args.email, args.password)
            )
            account_type = "email"
            email = args.email
            save_store(args.store, auth, account_type, email)
        else:
            auth = create_anonymous_user(api_key)
            account_type = "anonymous"
            email = None
            save_store(args.store, auth, account_type, email)

        token = auth["idToken"]
        if args.write_powershell:
            write_powershell(args.ps1_path, token)

        if args.run_smoke:
            env = os.environ.copy()
            env["AUTOFIX_AUTH_TOKEN"] = token
            smoke_script = Path(__file__).resolve().parent / "prod_smoke_qa.py"
            print("Firebase test token ready.")
            print(f"Account type : {account_type}")
            print(f"Firebase uid : {auth.get('localId')}")
            if email:
                print(f"Email        : {email}")
            print(f"Store file   : {args.store}")
            print(f"Running smoke: scenarios {args.smoke_scenarios}")
            return subprocess.call(
                [
                    sys.executable,
                    str(smoke_script),
                    "--scenarios",
                    args.smoke_scenarios,
                    "--yes",
                ],
                env=env,
            )

        if args.quiet:
            print(token)
        else:
            print("Firebase test token ready.")
            print(f"Account type : {account_type}")
            print(f"Firebase uid : {auth.get('localId')}")
            if email:
                print(f"Email        : {email}")
            print(f"Store file   : {args.store}")
            if args.write_powershell:
                print(f"PowerShell   : {args.ps1_path}")
                print(f"Run          : . {args.ps1_path}")
            else:
                print('PowerShell   : $env:AUTOFIX_AUTH_TOKEN="<token below>"')
                print("\nID token:")
                print(token)
        return 0
    except FirebaseTokenError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
