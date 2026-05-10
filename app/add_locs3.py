import json

translations = {
    "tr": {
        "claimBonus": "Bonus Al!",
        "bonusEnergy": "+1 Enerji",
        "bonusHint": "+1 İpucu",
        "watchAdButton": "İzle",
        "adEnergySuccess": "🎬 +1 Enerji kazandın!",
        "adApiFail": "Ödül API hatası",
        "adLoadFail": "Reklam yüklenemedi veya yarıda kesildi.",
        "hintError": "İpucu hatası"
    },
    "en": {
        "claimBonus": "Claim Bonus!",
        "bonusEnergy": "+1 Energy",
        "bonusHint": "+1 Hint",
        "watchAdButton": "Watch",
        "adEnergySuccess": "🎬 +1 Energy earned!",
        "adApiFail": "Reward API error",
        "adLoadFail": "Ad failed to load or was interrupted.",
        "hintError": "Hint error"
    },
    "ru": {
        "claimBonus": "Забрать бонус!",
        "bonusEnergy": "+1 Энергия",
        "bonusHint": "+1 Подсказка",
        "watchAdButton": "Смотреть",
        "adEnergySuccess": "🎬 +1 Энергия получена!",
        "adApiFail": "Ошибка API награды",
        "adLoadFail": "Реклама не загрузилась или была прервана.",
        "hintError": "Ошибка подсказки"
    },
    "zh": {
        "claimBonus": "领取奖励！",
        "bonusEnergy": "+1 能量",
        "bonusHint": "+1 提示",
        "watchAdButton": "观看",
        "adEnergySuccess": "🎬 获得 +1 能量！",
        "adApiFail": "奖励 API 错误",
        "adLoadFail": "广告加载失败或被中断。",
        "hintError": "提示错误"
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

print("Done!")
