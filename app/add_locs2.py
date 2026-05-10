import json

translations = {
    "tr": {
        "analyzing": "İnceleniyor...",
        "master": "Usta"
    },
    "en": {
        "analyzing": "Analyzing...",
        "master": "Master"
    },
    "ru": {
        "analyzing": "Анализ...",
        "master": "Мастер"
    },
    "zh": {
        "analyzing": "分析中...",
        "master": "师傅"
    }
}

for lang in translations:
    filepath = f"c:/Proje/Sanayi Ustasu/app/lib/l10n/app_{lang}.arb"
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    for k, v in translations[lang].items():
        data[k] = v
        
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

print("Added new keys successfully!")
