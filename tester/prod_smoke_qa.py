#!/usr/bin/env python3
"""
Production API smoke tester for AutoFix AI Simulator.

This script calls the real game API, so it can consume energy and update the
test user's stats/leaderboard. Use a Firebase ID token from a test account.

Examples:
  set AUTOFIX_AUTH_TOKEN=eyJ...
  python tester/prod_smoke_qa.py --scenarios 1,2 --yes
  python tester/prod_smoke_qa.py --scenarios 1,2 --dry-run
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Any
from urllib import error, request


DEFAULT_BASE_URL = "https://kw9p0x0sz4.execute-api.us-east-1.amazonaws.com"

BAD_FALLBACKS = [
    "gecersiz",
    "geçersiz",
    "bulunmuyor",
    "bilesen/test bulunmuyor",
    "bileşen/test bulunmuyor",
    "gerekli ekipman",
    "bilgi bulunmuyor",
    "test yapip bulman gerekiyor",
    "test yapıp bulman gerekiyor",
]


SMOKE_CASES: dict[int, dict[str, Any]] = {
    1: {
        "name": "S01 - Dead battery",
        "goal": "Akü ölçümü kabul edilmeli ve akü değişince vaka çözülmeli.",
        "steps": [
            {
                "message": "aküyü ölç",
                "must_contain_any": ["9.2", "9,2", "volt", "akü", "aku"],
                "must_not_contain_any": BAD_FALLBACKS,
            },
            {
                "message": "aküye saf su ve asit takviyesi yapıp başka akü ile şarj edelim",
                "expect_solved": False,
                "must_not_contain_any": BAD_FALLBACKS,
            },
            {
                "message": "aküyü değiştir",
                "expect_solved": True,
                "must_contain_any": ["çalış", "calis", "tamam", "sorunsuz", "başar", "basar"],
                "must_not_contain_any": BAD_FALLBACKS,
            },
        ],
    },
    2: {
        "name": "S02 - Starter motor",
        "goal": "Marş motoru komutları kabul edilmeli ve tamir/değişim çözmeli.",
        "steps": [
            {
                "message": "marş motorunu kontrol et",
                "must_contain_any": ["marş", "mars", "starter", "tık", "tik", "solenoid"],
                "must_not_contain_any": BAD_FALLBACKS,
            },
            {
                "message": "marş motorunu değiştir",
                "expect_solved": True,
                "must_contain_any": ["çalış", "calis", "sorunsuz", "başar", "basar"],
                "must_not_contain_any": BAD_FALLBACKS,
            },
        ],
    },
    3: {
        "name": "S03 - Left headlight fuse",
        "goal": "Sağlam parça halüsinasyonu yapmadan sigorta çözümüne gitmeli.",
        "steps": [
            {
                "message": "sağ farı test edelim",
                "must_contain_any": ["sağ", "sag", "çalış", "calis"],
                "must_not_contain_any": ["sağ far arızalı", "sag far arizali"],
            },
            {
                "message": "sol far ampulünü kontrol edelim",
                "must_contain_any": ["ampul", "filament", "sağlam", "saglam"],
                "must_not_contain_any": ["ampul arızalı", "ampul arizali", "ampul bozuk"],
            },
            {
                "message": "sol far sigortasını değiştir",
                "expect_solved": True,
                "must_contain_any": ["çalış", "calis", "sigorta", "başar", "basar"],
                "must_not_contain_any": BAD_FALLBACKS,
            },
        ],
    },
}


class QaFailure(Exception):
    pass


def normalize(text: str) -> str:
    return text.casefold().replace("\u0131", "i")


def parse_scenarios(value: str) -> list[int]:
    scenario_ids: list[int] = []
    for part in value.split(","):
        part = part.strip()
        if not part:
            continue
        try:
            scenario_id = int(part)
        except ValueError as exc:
            raise argparse.ArgumentTypeError(f"Invalid scenario id: {part}") from exc
        if scenario_id not in SMOKE_CASES:
            known = ", ".join(str(key) for key in sorted(SMOKE_CASES))
            raise argparse.ArgumentTypeError(
                f"Scenario {scenario_id} is not scripted yet. Known: {known}"
            )
        scenario_ids.append(scenario_id)
    if not scenario_ids:
        raise argparse.ArgumentTypeError("At least one scenario id is required")
    return scenario_ids


def api_request(
    method: str,
    base_url: str,
    path: str,
    token: str,
    payload: dict[str, Any] | None = None,
    timeout: int = 45,
) -> tuple[int, dict[str, Any]]:
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    req = request.Request(
        base_url.rstrip("/") + path,
        data=body,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    try:
        with request.urlopen(req, timeout=timeout) as res:
            raw = res.read().decode("utf-8")
            return res.status, json.loads(raw) if raw else {}
    except error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        try:
            parsed = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            parsed = {"raw": raw}
        return exc.code, parsed


def assert_step(step: dict[str, Any], response: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    text = str(response.get("response", ""))
    normalized_text = normalize(text)

    expected_solved = step.get("expect_solved")
    if expected_solved is not None and response.get("solved") is not expected_solved:
        failures.append(f"solved expected {expected_solved}, got {response.get('solved')}")

    must_contain_any = step.get("must_contain_any", [])
    if must_contain_any and not any(normalize(item) in normalized_text for item in must_contain_any):
        failures.append(f"missing any of: {', '.join(must_contain_any)}")

    must_not_contain_any = step.get("must_not_contain_any", [])
    blocked_terms = [item for item in must_not_contain_any if normalize(item) in normalized_text]
    if blocked_terms:
        failures.append(f"contains blocked text: {', '.join(blocked_terms)}")

    return failures


def run_case(
    scenario_id: int,
    case: dict[str, Any],
    base_url: str,
    token: str,
    lang: str,
    delay: float,
) -> dict[str, Any]:
    case_log: dict[str, Any] = {
        "scenarioId": scenario_id,
        "name": case["name"],
        "goal": case["goal"],
        "steps": [],
        "ok": True,
    }

    status, start_body = api_request(
        "POST",
        base_url,
        "/game/start",
        token,
        {"scenarioId": scenario_id},
    )
    case_log["start"] = {"status": status, "body": start_body}
    if status != 200:
        case_log["ok"] = False
        case_log["error"] = f"start failed with HTTP {status}"
        return case_log

    session_id = start_body.get("sessionId")
    if not session_id:
        case_log["ok"] = False
        case_log["error"] = "start response did not include sessionId"
        return case_log

    for index, step in enumerate(case["steps"], start=1):
        if delay > 0:
            time.sleep(delay)

        status, body = api_request(
            "POST",
            base_url,
            "/game/message",
            token,
            {
                "sessionId": session_id,
                "message": step["message"],
                "langCode": lang,
            },
        )
        failures = [] if status == 200 else [f"message failed with HTTP {status}"]
        warnings = []
        if status == 200:
            failures.extend(assert_step(step, body))
            if body.get("solved") is True and not str(body.get("masteryFeedback", "")).strip():
                warnings.append("solved response did not include masteryFeedback")

        step_log = {
            "index": index,
            "message": step["message"],
            "status": status,
            "body": body,
            "failures": failures,
            "warnings": warnings,
            "ok": not failures,
        }
        case_log["steps"].append(step_log)

        if failures:
            case_log["ok"] = False
            break
        if body.get("solved"):
            break

    return case_log


def print_plan(scenario_ids: list[int]) -> None:
    print("QA plan:")
    for scenario_id in scenario_ids:
        case = SMOKE_CASES[scenario_id]
        print(f"- {case['name']}: {case['goal']}")
        for step in case["steps"]:
            print(f"  > {step['message']}")


def save_log(log: dict[str, Any]) -> Path:
    logs_dir = Path(__file__).resolve().parent / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    path = logs_dir / f"prod_smoke_{stamp}.json"
    path.write_text(json.dumps(log, ensure_ascii=False, indent=2), encoding="utf-8")
    return path


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Run production smoke QA against AutoFix game API.",
    )
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--token", default=os.environ.get("AUTOFIX_AUTH_TOKEN"))
    parser.add_argument("--scenarios", type=parse_scenarios, default=parse_scenarios("1,2"))
    parser.add_argument("--lang", default="tr")
    parser.add_argument("--delay", type=float, default=0.8)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Required for live API calls because this can consume energy.",
    )
    args = parser.parse_args()

    print_plan(args.scenarios)

    if args.dry_run:
        print("\nDry run only. No API calls were made.")
        return 0

    if not args.yes:
        print("\nRefusing to call prod without --yes. This can consume energy/stats.")
        return 2

    if not args.token:
        print("\nMissing Firebase ID token. Set AUTOFIX_AUTH_TOKEN or pass --token.")
        return 2

    full_log: dict[str, Any] = {
        "startedAt": datetime.now().isoformat(timespec="seconds"),
        "baseUrl": args.base_url,
        "lang": args.lang,
        "scenarioIds": args.scenarios,
        "cases": [],
    }

    for scenario_id in args.scenarios:
        case = SMOKE_CASES[scenario_id]
        print(f"\nRunning {case['name']}...")
        case_log = run_case(
            scenario_id=scenario_id,
            case=case,
            base_url=args.base_url,
            token=args.token,
            lang=args.lang,
            delay=args.delay,
        )
        full_log["cases"].append(case_log)

        if case_log["ok"]:
            print(f"PASS {case['name']}")
            for step in case_log.get("steps", []):
                for warning in step.get("warnings", []):
                    print(f"  WARN Step {step['index']}: {warning}")
        else:
            print(f"FAIL {case['name']}: {case_log.get('error', 'step assertion failed')}")
            for step in case_log.get("steps", []):
                if step.get("failures"):
                    print(f"  Step {step['index']} ({step['message']}):")
                    for failure in step["failures"]:
                        print(f"    - {failure}")
                    response_text = step.get("body", {}).get("response")
                    if response_text:
                        print(f"    response: {response_text}")

    full_log["finishedAt"] = datetime.now().isoformat(timespec="seconds")
    full_log["ok"] = all(case["ok"] for case in full_log["cases"])
    log_path = save_log(full_log)

    print(f"\nLog written: {log_path}")
    return 0 if full_log["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
