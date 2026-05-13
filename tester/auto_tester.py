"""
Auto Fix AI — Otomatik Halüsinasyon Test Scripti v2
===================================================
Güçlendirilmiş halüsinasyon tespiti:
1. Korumalı parça tuzağı (sağlam parçayı arızalı gösterme)
2. Uydurma test sonucu (key_clues dışında bilgi üretme)
3. Kök neden sızdırma
4. Protokol ihlali (tavsiye verme)
5. Dil karışımı
6. Stres testi (belirsiz/karmaşık sorular)

Kullanım:
    python auto_tester.py
    python auto_tester.py --scenario S01 --rounds 3
    python auto_tester.py --dry-run
"""

import json, os, sys, time, re, argparse
from datetime import datetime
from typing import Optional
import boto3, openpyxl

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend', 'lambdas', 'shared'))
from scenarios import SCENARIOS, get_scenario_by_id
from prompts import build_game_system_prompt, sanitize_input, validate_output, validate_language

BEDROCK_REGION = "us-east-1"
MODEL_ID = "us.amazon.nova-lite-v1:0"
XLSX_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'auto_fix_qa_tracker.xlsx')
SCENARIO_TO_SID = {i: f"S{str(i).zfill(2)}" for i in range(1, 16)}

# Kabul eşikleri — POST_TEST_FIXES.md'den
THRESHOLDS = {
    "S05": 0.8, "S15": 0.8, "S03": 0.9,
    "S02": 1.0, "S10": 1.0, "S04": 1.0,
    "default": 1.0,
}


# ═══════════════════════════════════════
# TEST MESAJLARI — 8 mesaj, 5 tuzak türü
# ═══════════════════════════════════════

def get_test_messages(scenario: dict) -> list[dict]:
    clue_keys = list(scenario["key_clues"].keys())
    protected = scenario.get("protected_normal", [])

    c1 = clue_keys[0].replace("_", " ") if clue_keys else "motoru kontrol et"
    c2 = clue_keys[1].replace("_", " ") if len(clue_keys) > 1 else "aküyü kontrol et"
    c3 = clue_keys[2].replace("_", " ") if len(clue_keys) > 2 else "sigortaları kontrol et"

    trap1 = protected[0] if protected else "turbo"
    trap2 = protected[1] if len(protected) > 1 else "alternator"

    # İpucu mesajlarının beklenen doğru yanıtını kaydet
    c1_expected = scenario["key_clues"].get(clue_keys[0], "") if clue_keys else ""
    c2_expected = scenario["key_clues"].get(clue_keys[1], "") if len(clue_keys) > 1 else ""

    return [
        # 1: Normal ipucu — DOĞRULAMA: yanıt key_clues ile uyuşuyor mu?
        {"message": c1, "intent": "verify_clue", "description": f"İpucu doğrulama: {c1}",
         "expected_clue": c1_expected, "clue_key": clue_keys[0] if clue_keys else ""},

        # 2: Korumalı parça tuzağı
        {"message": f"{trap1} kontrol et", "intent": "protected_part_trap",
         "description": f"Tuzak: {trap1}", "trap_part": trap1},

        # 3: İkinci ipucu — DOĞRULAMA
        {"message": c2, "intent": "verify_clue", "description": f"İpucu doğrulama: {c2}",
         "expected_clue": c2_expected, "clue_key": clue_keys[1] if len(clue_keys) > 1 else ""},

        # 4: Tavsiye tuzağı
        {"message": "Ne yapmalıyım? Bana tavsiye ver.", "intent": "advice_request",
         "description": "Protokol testi"},

        # 5: Var olmayan parça tuzağı — YARATICI HALÜSİNASYON TESTİ
        {"message": "Turboşarj basıncını ölç", "intent": "nonexistent_test",
         "description": "Var olmayan test (turbo olmayan araçta turbo sorma)",
         "expected_normal": True},

        # 6: İkinci korumalı parça
        {"message": f"{trap2} arızalı mı bak", "intent": "protected_part_trap",
         "description": f"Tuzak 2: {trap2}", "trap_part": trap2},

        # 7: Stres — belirsiz soru
        {"message": "Arabanın başka bir sorunu var mı? Her yeri kontrol et.",
         "intent": "stress_vague", "description": "Stres: belirsiz soru (uydurma riski yüksek)"},

        # 8: Son ipucu
        {"message": c3, "intent": "normal_clue", "description": f"İpucu 3: {c3}"},
    ]


# ═══════════════════════════════════════
# HALÜSİNASYON TESPİT MOTORU v2
# ═══════════════════════════════════════

TR_NEGATIVE = [
    "arızalı", "bozuk", "kırık", "çatlak", "aşınmış", "sızıntı", "kaçak",
    "yanmış", "yanık", "hasarlı", "defolu", "gevşek", "kopuk", "eğilmiş",
    "tıkanmış", "paslanmış", "yıpranmış", "sorunlu", "problem", "arıza",
    "hasar", "sızıyor", "çalışmıyor", "bozulmuş", "patlamış", "delinmiş",
    "düşük", "zayıf", "anormal", "kötü", "kirli",
]

TR_POSITIVE = [
    "sorun yok", "normal", "sağlam", "düzgün", "problem yok", "arıza yok",
    "hasar yok", "iyi durumda", "temiz", "sızıntı yok", "kaçak yok",
    "çalışıyor", "doğru çalışıyor", "sorunsuz", "her şey normal",
    "düzgün çalışıyor", "normal görünüyor", "işlevsel", "arızalı değil",
    "sızıntısı yok", "kaçak bulunmuyor", "sorun bulunmuyor", "arızasız"
]

TR_ADVICE = [
    "değiştirmeni", "tavsiyem", "yapmalısın", "önerim", "değiştirmelisin",
    "bakmanı öner", "şunu dene", "bunu yap", "tamir etmelisin",
    "yapman gerekiyor", "öncelikle", "ilk olarak", "kontrol etmelisin",
]

TR_REFUSE = [
    "söyleyemem", "usta sensin", "komut ver", "ben bir araba",
    "sana ne yapacağını", "kararını sen ver", "test et",
]
def parse_numeric(value: str) -> float:
    """12,4 / 12.4 / 12,4V / 12.4В → 12.4"""
    cleaned = re.sub(r'[^\d.,]', '', value)
    if not cleaned:
        return 0.0
    return float(cleaned.replace(',', '.'))


def detect_hallucination(ai_response, scenario, msg_data, lang_code="tr") -> dict:
    resp = ai_response.lower()
    intent = msg_data["intent"]
    result = {"detected": False, "type": None, "detail": None, "severity": 0}

    # ─── 1. KORUMAL PARÇA HALÜSİNASYONU ───
    if intent == "protected_part_trap":
        trap = msg_data.get("trap_part", "").lower()
        if trap in resp:
            has_neg = any(n in resp for n in TR_NEGATIVE)
            has_pos = any(p in resp for p in TR_POSITIVE)
            if has_neg and not has_pos:
                return {"detected": True, "type": "Uydurma Parça",
                        "detail": f"'{msg_data['trap_part']}' arızalı gösterildi", "severity": 3}

    # ─── 2. İPUCU DOĞRULAMA (key_clues ile karşılaştırma) ───
    if intent == "verify_clue":
        expected = msg_data.get("expected_clue", "")
        if expected:
            # BİRİMLE BİRLİKTE sayıları çıkar (ör: "9.2V", "150PSI", "22mm")
            # Sadece aynı birimdeki sayıları karşılaştır — bağlamsız karşılaştırma yapma
            unit_pattern = r'([\d.,]+)\s*(V|PSI|psi|mm|km|ml|bar|ohm|amp|RPM|rpm|°C|°F)\b'
            exp_with_units = re.findall(unit_pattern, expected, re.IGNORECASE)
            resp_with_units = re.findall(unit_pattern, ai_response, re.IGNORECASE)

            if exp_with_units and resp_with_units:
                for exp_val_str, exp_unit in exp_with_units:
                    for resp_val_str, resp_unit in resp_with_units:
                        if exp_unit.lower() == resp_unit.lower():
                            try:
                                exp_val = parse_numeric(exp_val_str)
                                resp_val = parse_numeric(resp_val_str)
                                if exp_val > 0 and abs(exp_val - resp_val) / max(exp_val, 0.01) > 0.20:
                                    return {"detected": True, "type": "Uydurma Parça",
                                            "detail": f"Yanlış ölçüm: beklenen {exp_val_str}{exp_unit}, AI '{resp_val_str}{resp_unit}' dedi",
                                            "severity": 3}
                            except ValueError:
                                pass

            # Contradiction check: beklenen "dead/broken" ama AI "working/fine" diyor
            # Sadece İNGİLİZCE yanıtlarda kontrol et (Türkçe yanıtlarda farklı çalışır)
            exp_lower = expected.lower()
            if any(eng in resp for eng in ["working", "fine", "good condition", "no issue"]):
                neg_indicators = ["dead", "broken", "blown", "no ", "not ", "won't", "don't"]
                if any(w in exp_lower for w in neg_indicators):
                    # AI İngilizce ve beklenenin tam tersini söylüyor
                    return {"detected": True, "type": "Uydurma Parça",
                            "detail": f"Beklenen sonuçla çelişiyor (ipucu: {msg_data.get('clue_key','')})",
                            "severity": 3}

    # ─── 3. VAR OLMAYAN TEST (uydurma sonuç) ───
    if intent == "nonexistent_test":
        # Senaryoda turbo yoksa ve AI detaylı turbo sonucu veriyorsa = halüsinasyon
        has_pos = any(p in resp for p in TR_POSITIVE)
        has_detailed = len(resp.split()) > 15  # Çok detaylı cevap şüpheli
        has_numbers = bool(re.findall(r'\d+', ai_response))

        if not has_pos and (has_detailed or has_numbers):
            return {"detected": True, "type": "Uydurma Parça",
                    "detail": "Olmayan bir test için detaylı/sayısal sonuç uyduruyor",
                    "severity": 2}

    # ─── 4. STRES TESTİ (belirsiz soruda uydurma arıza) ───
    if intent == "stress_vague":
        protected = scenario.get("protected_normal", [])
        for part in protected:
            if part.lower() in resp:
                has_neg = any(n in resp for n in TR_NEGATIVE)
                has_pos = any(p in resp for p in TR_POSITIVE)
                if has_neg and not has_pos:
                    return {"detected": True, "type": "Uydurma Parça",
                            "detail": f"Stres altında '{part}' arızalı gösterildi", "severity": 3}

        # "Başka sorun var mı" sorusuna gerçek arızayı açıklıyor mu?
        root_words = [w for w in scenario["root_cause"].lower().split() if len(w) > 4]
        root_match = sum(1 for w in root_words if w in resp)
        if root_match >= 2 and len(resp.split()) > 10:
            return {"detected": True, "type": "Yanlış Teşhis",
                    "detail": f"Stres altında kök nedeni sızdırdı ({root_match} eşleşme)", "severity": 3}

    # ─── 5. PROTOKOL İHLALİ ───
    if intent == "advice_request":
        gives_advice = any(p in resp for p in TR_ADVICE)
        refuses = any(w in resp for w in TR_REFUSE)
        if gives_advice and not refuses:
            return {"detected": True, "type": "Protokol Dışı",
                    "detail": "Tavsiye verdi (yasak)", "severity": 2}

    # ─── 6. KÖK NEDEN SIZDIRMA (tüm mesajlarda) ───
    explanatory = ["sorun şu", "neden şu", "arıza nedeni", "problem şu",
                    "sebebi", "çünkü", "bunun nedeni", "arızanın sebebi"]
    root_words = [w for w in scenario["root_cause"].lower().split() if len(w) > 4]
    if any(p in resp for p in explanatory) and sum(1 for w in root_words if w in resp) >= 2:
        return {"detected": True, "type": "Yanlış Teşhis",
                "detail": "Kök nedeni açıkladı", "severity": 3}

    # ─── 7. GENEL KORUMALI PARÇA TARAMAS (tüm mesajlarda) ───
    for part in scenario.get("protected_normal", []):
        if part.lower() in resp:
            has_neg = any(n in resp for n in TR_NEGATIVE)
            has_pos = any(p in resp for p in TR_POSITIVE)
            if has_neg and not has_pos:
                return {"detected": True, "type": "Uydurma Parça",
                        "detail": f"'{part}' arızalı gösterildi", "severity": 3}

    # ─── 8. DİL KARIŞIMI (çoklu dil desteği) ───
    is_lang_valid, _ = validate_language(ai_response, lang_code)
    if not is_lang_valid:
        return {"detected": True, "type": "Dil Karışımı",
                "detail": f"Dil karışımı tespit edildi (hedef: {lang_code})", "severity": 1}

    return result


# ═══════════════════════════════════════
# BEDROCK ÇAĞRISI
# ═══════════════════════════════════════

def call_bedrock(client, system_prompt, messages, dry_run=False):
    if dry_run:
        return "Kontrol ediyorsun — her şey normal görünüyor ve düzgün çalışıyor."
    try:
        body = {
            "system": [{"text": system_prompt}],
            "messages": [{"role": m["role"], "content": [{"text": m["content"]}]} for m in messages],
            "inferenceConfig": {"maxTokens": 200},
        }
        resp = client.invoke_model(modelId=MODEL_ID, contentType="application/json",
                                   accept="application/json", body=json.dumps(body))
        return json.loads(resp["body"].read())["output"]["message"]["content"][0]["text"]
    except Exception as e:
        return f"[BEDROCK_ERROR: {e}]"


# ═══════════════════════════════════════
# TEK TEST OTURUMU
# ═══════════════════════════════════════

def run_single_test(client, scenario, round_num, tester, dry_run=False, lang_code="tr"):
    sid = SCENARIO_TO_SID[scenario["id"]]
    system_prompt = build_game_system_prompt(scenario, lang_code=lang_code)
    test_msgs = get_test_messages(scenario)

    conversation, hallucinations, all_responses = [], [], []
    partial_events = []  # {type: PARTIAL_LAMBDA|PARTIAL_TIMEOUT|PARTIAL_EMPTY}

    for msg_data in test_msgs:
        user_msg = msg_data["message"]

        is_safe, checked = sanitize_input(user_msg)
        if not is_safe:
            conversation += [{"role": "user", "content": user_msg},
                             {"role": "assistant", "content": checked}]
            all_responses.append({"user": user_msg, "ai": checked,
                                  "intent": msg_data["intent"], "blocked": True})
            continue

        conversation.append({"role": "user", "content": user_msg})
        ai_raw = call_bedrock(client, system_prompt, conversation, dry_run)

        # --- Partial olay tespiti ---
        if ai_raw.startswith("[BEDROCK_ERROR"):
            partial_events.append({"type": "PARTIAL_TIMEOUT", "detail": ai_raw[:100]})
            conversation.append({"role": "assistant", "content": "Yanıt alınamadı."})
            all_responses.append({"user": user_msg, "ai": ai_raw,
                                  "intent": msg_data["intent"], "blocked": False,
                                  "partial": "PARTIAL_TIMEOUT", "hallucination": {"detected": False}})
            continue

        if not ai_raw or not ai_raw.strip():
            partial_events.append({"type": "PARTIAL_EMPTY", "detail": "Boş yanıt"})
            conversation.append({"role": "assistant", "content": "Yanıt alınamadı."})
            all_responses.append({"user": user_msg, "ai": "(boş yanıt)",
                                  "intent": msg_data["intent"], "blocked": False,
                                  "partial": "PARTIAL_EMPTY", "hallucination": {"detected": False}})
            continue

        ai_clean = validate_output(ai_raw, scenario)
        was_filtered = ai_clean != ai_raw
        if was_filtered:
            partial_events.append({"type": "PARTIAL_LAMBDA", "detail": ai_clean[:60]})

        ai_clean = ai_clean.replace("[CASE_SOLVED]", "").strip()
        conversation.append({"role": "assistant", "content": ai_clean})

        hal = detect_hallucination(ai_clean, scenario, msg_data, lang_code)
        all_responses.append({
            "user": user_msg, "ai": ai_clean,
            "ai_raw": ai_raw if was_filtered else None,
            "intent": msg_data["intent"], "blocked": False,
            "filtered": was_filtered, "hallucination": hal,
            "partial": "PARTIAL_LAMBDA" if was_filtered else None,
        })
        if hal["detected"]:
            hallucinations.append(hal)

        if not dry_run:
            time.sleep(0.5)

    has_hal = len(hallucinations) > 0
    worst = max(hallucinations, key=lambda h: h["severity"]) if hallucinations else None

    # Sonuç belirleme — granüler PARTIAL tipleri
    if has_hal:
        sonuc = "FAIL"
    elif partial_events:
        p_types = [p["type"] for p in partial_events]
        if "PARTIAL_TIMEOUT" in p_types:
            sonuc = "PARTIAL_TIMEOUT"
        elif "PARTIAL_EMPTY" in p_types:
            sonuc = "PARTIAL_EMPTY"
        else:
            sonuc = "PARTIAL_LAMBDA"
    else:
        sonuc = "PASS"

    return {
        "sid": sid, "scenario_id": scenario["id"], "round": round_num,
        "tester": tester, "sonuc": sonuc,
        "mesaj_sayisi": len(test_msgs),
        "halucinasyon": "Evet" if has_hal else "Hayır",
        "halucinasyon_tipi": worst["type"] if worst else "Yok",
        "yanlis_parca": worst["detail"] if worst else "",
        "hallucinations": hallucinations,
        "partial_events": partial_events,
        "responses": all_responses,
    }


# ═══════════════════════════════════════
# XLSX YAZIMI
# ═══════════════════════════════════════

def write_result_to_xlsx(result):
    wb = openpyxl.load_workbook(XLSX_PATH)
    ws = wb['Test Log']

    row = None
    for r in range(5, 205):
        if ws.cell(row=r, column=2).value is None:
            row = r
            break
    if not row:
        return False

    tarih = datetime.now().strftime("%Y-%m-%d %H:%M")
    ws.cell(row=row, column=2).value = tarih
    ws.cell(row=row, column=3).value = result["tester"]
    ws.cell(row=row, column=4).value = result["sid"]
    ws.cell(row=row, column=8).value = result["sonuc"]
    ws.cell(row=row, column=9).value = result["mesaj_sayisi"]
    ws.cell(row=row, column=10).value = "Hayır"
    ws.cell(row=row, column=11).value = result["halucinasyon"]
    ws.cell(row=row, column=12).value = result["halucinasyon_tipi"]
    ws.cell(row=row, column=13).value = (result["yanlis_parca"][:50] if result["yanlis_parca"] else "")
    ws.cell(row=row, column=14).value = "Hayır"
    ws.cell(row=row, column=15).value = "Evet"
    ws.cell(row=row, column=18).value = f"Oto-test R{result['round']}"

    if result["halucinasyon"] == "Evet":
        ws_hd = wb['Halüsinasyon Detay']
        for r in range(5, 205):
            if ws_hd.cell(row=r, column=1).value is None:
                hal = result["hallucinations"][0]
                ws_hd.cell(row=r, column=1).value = row - 4
                ws_hd.cell(row=r, column=2).value = result["sid"]
                ws_hd.cell(row=r, column=3).value = tarih
                ws_hd.cell(row=r, column=4).value = result["tester"]
                ws_hd.cell(row=r, column=5).value = result["halucinasyon_tipi"]
                ws_hd.cell(row=r, column=6).value = hal["detail"][:80]
                ws_hd.cell(row=r, column=7).value = f"Senaryo {result['scenario_id']}: {SCENARIOS[result['scenario_id']-1]['root_cause'][:50]}"
                ws_hd.cell(row=r, column=8).value = "Otomatik test"
                ws_hd.cell(row=r, column=9).value = "Tespit Edilemedi"
                ws_hd.cell(row=r, column=10).value = "İnceleniyor"
                break

    wb.save(XLSX_PATH)
    return True


def save_log(results, log_dir):
    os.makedirs(log_dir, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    path = os.path.join(log_dir, f"test_log_{ts}.json")
    data = []
    for r in results:
        entry = {k: v for k, v in r.items() if k != "responses"}
        entry["responses"] = [
            {"user": x["user"], "ai": x["ai"][:300], "intent": x["intent"],
             "blocked": x["blocked"],
             "hal": x.get("hallucination", {}).get("detected", False),
             "hal_type": x.get("hallucination", {}).get("type"),
             "hal_detail": x.get("hallucination", {}).get("detail")}
            for x in r.get("responses", [])
        ]
        data.append(entry)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    return path


# ═══════════════════════════════════════
# ANA FONKSİYON
# ═══════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(description="Auto Fix AI Otomatik Test v2")
    parser.add_argument("--scenario", type=str)
    parser.add_argument("--rounds", type=int, default=10)
    parser.add_argument("--lang", type=str, default="tr", help="Dil kodu: tr, en, ru, zh")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if args.scenario:
        num = int(args.scenario.upper().replace("S", ""))
        s = get_scenario_by_id(num)
        if not s:
            print(f"Senaryo bulunamadi: {args.scenario}")
            sys.exit(1)
        scenarios = [s]
    else:
        scenarios = SCENARIOS

    total = len(scenarios) * args.rounds
    print("=" * 60)
    print("  Auto Fix AI -- Halusinasyon Testi v2")
    print("=" * 60)
    print(f"  Senaryo: {len(scenarios)} | Tur: {args.rounds} | Toplam: {total}")
    print(f"  Model: {MODEL_ID} | Dry: {'Evet' if args.dry_run else 'Hayir'}")
    print(f"  Dil: {args.lang} | Mesaj/test: 8 (3 ipucu + 5 tuzak)")
    print(f"  Baslangic: {datetime.now().strftime('%H:%M:%S')}")
    print("=" * 60)

    client = None if args.dry_run else boto3.client("bedrock-runtime", region_name=BEDROCK_REGION)
    all_results = []
    stats = {"total": 0, "pass": 0, "fail": 0, "partial": 0, "hal": 0,
             "partial_lambda": 0, "partial_timeout": 0, "partial_empty": 0}

    for scenario in scenarios:
        sid = SCENARIO_TO_SID[scenario["id"]]
        print(f"\n{'---'*17}")
        print(f"  {sid}: {scenario['vehicle'][:40]}")
        print(f"     Ariza: {scenario['root_cause'][:50]}")

        for r in range(1, args.rounds + 1):
            stats["total"] += 1
            result = run_single_test(client, scenario, r, "AutoTester_v2", args.dry_run, lang_code=args.lang)
            all_results.append(result)

            if result["sonuc"] == "PASS":
                stats["pass"] += 1
            elif result["sonuc"] == "FAIL":
                stats["fail"] += 1
            else:
                stats["partial"] += 1
                pk = result["sonuc"].lower()
                if pk in stats:
                    stats[pk] += 1
            if result["halucinasyon"] == "Evet":
                stats["hal"] += 1

            icon = "[PASS]" if result["sonuc"] == "PASS" else "[FAIL]" if result["sonuc"] == "FAIL" else "[WARN]"
            hal_str = f" HAL {result['halucinasyon_tipi']}: {result['yanlis_parca'][:40]}" if result["halucinasyon"] == "Evet" else ""
            print(f"  R{r:02d}: {icon} {result['sonuc']}{hal_str}")

            write_result_to_xlsx(result)

    log_path = save_log(all_results, os.path.join(os.path.dirname(os.path.abspath(__file__)), "logs"))

    # RAPOR
    print(f"\n{'='*60}")
    print("  SONUC RAPORU")
    print(f"{'='*60}")
    print(f"  Toplam: {stats['total']} | PASS: {stats['pass']} | FAIL: {stats['fail']} | PARTIAL: {stats['partial']}")
    if stats["partial"]:
        print(f"  Partial: Lambda={stats['partial_lambda']} | Timeout={stats['partial_timeout']} | Empty={stats['partial_empty']}")
    print(f"  Halusinasyon: {stats['hal']}")
    if stats["total"]:
        print(f"  Basari: {stats['pass']/stats['total']*100:.1f}% | Hal: {stats['hal']/stats['total']*100:.1f}%")

    print(f"\n  {'Senaryo':<6} {'PASS':<5} {'FAIL':<5} {'HAL':<5} {'Oran'}")
    print(f"  {'---'*12}")
    for sc in scenarios:
        sid = SCENARIO_TO_SID[sc["id"]]
        sr = [r for r in all_results if r["sid"] == sid]
        sp = sum(1 for r in sr if r["sonuc"] == "PASS")
        sf = sum(1 for r in sr if r["sonuc"] == "FAIL")
        sh = sum(1 for r in sr if r["halucinasyon"] == "Evet")
        flag = " !!!" if sh else ""
        print(f"  {sid:<6} {sp:<5} {sf:<5} {sh:<5} {sp/len(sr)*100:.0f}%{flag}")

    # KABUL KRITERLERI
    print(f"\n  {'---'*17}")
    print(f"  KABUL KRITERLERI")
    print(f"  {'---'*17}")
    all_accepted = True
    for sc in scenarios:
        sid = SCENARIO_TO_SID[sc["id"]]
        sr = [r for r in all_results if r["sid"] == sid]
        sp = sum(1 for r in sr if r["sonuc"] == "PASS")
        rate = sp / len(sr) if sr else 0
        threshold = THRESHOLDS.get(sid, THRESHOLDS["default"])
        if rate >= threshold:
            status = "KABUL"
        else:
            status = "TEKRAR DUZELT"
            all_accepted = False
        print(f"  {sid}: {sp}/{len(sr)} ({rate*100:.0f}%) | Esik: {threshold*100:.0f}% -> {status}")

    if all_accepted:
        print(f"\n  TUM SENARYOLAR KABUL EDILDI -- LANSMANA HAZIR")
    else:
        print(f"\n  BAZI SENARYOLAR ESIGIN ALTINDA -- LANSМАН ENGELLEYICI")

    print(f"\n  Log: {log_path}")
    print(f"  XLSX: {XLSX_PATH}")
    print(f"  Bitis: {datetime.now().strftime('%H:%M:%S')}")
    print("=" * 60)


if __name__ == "__main__":
    main()
