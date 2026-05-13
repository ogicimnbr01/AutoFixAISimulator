import json

translations = {
    "tr": {
        "splashTitle": "SANAYİ USTASI",
        "splashSubtitle": "Garajın Seni Bekliyor",
        "fomoTitle": "GİZLİ TEKLİF!",
        "fomoBody": "Sadece şu an için geçerli! Sınırsız enerji ve tüm ustalık özellikleri seni bekliyor. Bu fırsatı kaçırma!",
        "fomoPopupTitle": "GİZLİ TEKLİF",
        "fomoOffer": "1 Haftalık Sınırsız Enerji\n🎁 +5 İpucu Hediye!",
        "fomoDiscount": "%80 İNDİRİM!",
        "fomoViewers": "{count} kişi teklifi inceliyor",
        "fomoBuy": "TÜKENMEDEN AL",
        "fomoSkip": "Fırsatı Kaçır ve Normal Devam Et",
        "cooldownAdSuccess": "🎬 1 Saat düştü! Kalan: {remaining}",
        "googleLinked": "✅ Google hesabı bağlandı!",
        "appleLinked": "✅ Apple hesabı bağlandı!",
        "loginCancelled": "Giriş iptal edildi"
    },
    "en": {
        "splashTitle": "AUTO FIX AI",
        "splashSubtitle": "The Garage Awaits You",
        "fomoTitle": "SECRET OFFER!",
        "fomoBody": "Only available right now! Unlimited energy and all mastery features await you. Don't miss this!",
        "fomoPopupTitle": "SECRET OFFER",
        "fomoOffer": "1 Week Unlimited Energy\n🎁 +5 Hints Free!",
        "fomoDiscount": "80% OFF!",
        "fomoViewers": "{count} people viewing this offer",
        "fomoBuy": "GET IT BEFORE IT'S GONE",
        "fomoSkip": "Skip Offer and Continue",
        "cooldownAdSuccess": "🎬 1 Hour reduced! Remaining: {remaining}",
        "googleLinked": "✅ Google account linked!",
        "appleLinked": "✅ Apple account linked!",
        "loginCancelled": "Login cancelled"
    },
    "ru": {
        "splashTitle": "АВТОМАСТЕР",
        "splashSubtitle": "Гараж ждёт тебя",
        "fomoTitle": "СЕКРЕТНОЕ ПРЕДЛОЖЕНИЕ!",
        "fomoBody": "Доступно только сейчас! Безлимитная энергия и все функции мастерства ждут вас. Не упустите!",
        "fomoPopupTitle": "СЕКРЕТНОЕ ПРЕДЛОЖЕНИЕ",
        "fomoOffer": "1 Неделя безлимитной энергии\n🎁 +5 Подсказок бесплатно!",
        "fomoDiscount": "СКИДКА 80%!",
        "fomoViewers": "{count} человек смотрят предложение",
        "fomoBuy": "УСПЕЙ КУПИТЬ",
        "fomoSkip": "Пропустить и продолжить",
        "cooldownAdSuccess": "🎬 1 Час снят! Осталось: {remaining}",
        "googleLinked": "✅ Аккаунт Google привязан!",
        "appleLinked": "✅ Аккаунт Apple привязан!",
        "loginCancelled": "Вход отменён"
    },
    "zh": {
        "splashTitle": "汽修大师",
        "splashSubtitle": "车库在等你",
        "fomoTitle": "限时优惠！",
        "fomoBody": "仅限现在！无限能量和所有大师功能等着你。不要错过！",
        "fomoPopupTitle": "限时优惠",
        "fomoOffer": "1 周无限能量\n🎁 +5 提示免费赠送！",
        "fomoDiscount": "8折优惠！",
        "fomoViewers": "{count} 人正在查看此优惠",
        "fomoBuy": "立即抢购",
        "fomoSkip": "跳过优惠，继续游戏",
        "cooldownAdSuccess": "🎬 减少1小时！剩余：{remaining}",
        "googleLinked": "✅ Google 账号已关联！",
        "appleLinked": "✅ Apple 账号已关联！",
        "loginCancelled": "登录已取消"
    }
}

for lang in translations:
    filepath = f"c:/Proje/Sanayi Ustasu/app/lib/l10n/app_{lang}.arb"
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    for k, v in translations[lang].items():
        data[k] = v
    
    # Add @annotations for parameterized strings
    if "fomoViewers" in data and "@fomoViewers" not in data:
        data["@fomoViewers"] = {"placeholders": {"count": {"type": "String"}}}
    if "cooldownAdSuccess" in data and "@cooldownAdSuccess" not in data:
        data["@cooldownAdSuccess"] = {"placeholders": {"remaining": {"type": "String"}}}
        
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

print("Done!")
