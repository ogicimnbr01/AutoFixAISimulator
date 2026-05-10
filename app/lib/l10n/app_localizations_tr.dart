// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class STr extends S {
  STr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'AutoFix AI Simülatör';

  @override
  String get tabGarage => 'Garaj';

  @override
  String get tabLeaderboard => 'Sıralama';

  @override
  String get tabProfile => 'Profil';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get error => 'Hata';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get cancel => 'İptal';

  @override
  String get send => 'Gönder';

  @override
  String get close => 'Kapat';

  @override
  String customerComplaint(Object complaint) {
    return '🧑‍🔧 Müşteri: \"$complaint\"';
  }

  @override
  String get noEnergy => '⚡ Enerji bitti! Reklam izle veya bekle.';

  @override
  String get fallbackError => '⚡ Garajın şartelleri attı. Tekrar dene.';

  @override
  String get caseSolved => '✅ Vaka Çözüldü!';

  @override
  String get repairSuccess => '🏆 Tamir Başarılı!';

  @override
  String seriesInfo(Object streak) {
    return 'Seri: $streak | +1 Ün Puanı';
  }

  @override
  String get bonusEnergyTag => ' | 🎁 +1 Bonus Enerji!';

  @override
  String get backToGarage => 'Garaja Dön';

  @override
  String messageCount(Object count, Object limit) {
    return '$count/$limit mesaj';
  }

  @override
  String cooldownLabel(Object remaining) {
    return '⏰ Cooldown: $remaining';
  }

  @override
  String cooldownMessage(Object limit) {
    return '$limit mesaj limitine ulaştın';
  }

  @override
  String get watchAdContinue => 'Reklam İzle → Devam Et';

  @override
  String get cooldownCleared => '🎬 Cooldown sıfırlandı! Devam et.';

  @override
  String cooldownReduced(Object remaining) {
    return '🎬 1 Saat düştü! Kalan: $remaining';
  }

  @override
  String get giveUpTitle => '🏳️ Teslim Ol?';

  @override
  String get giveUpMessage =>
      'Seri puanın kırılmaz, ama bu vaka çözülmüş sayılmaz. Devam etmek istediğine emin misin?';

  @override
  String get giveUpButton => 'Teslim Ol';

  @override
  String get continueButton => 'Devam Et';

  @override
  String get hintTimeTitle => 'İpucu Zamanı!';

  @override
  String get hintTimeMessage =>
      '15 mesajı geçtin ama çözememedin. Ustaya danışmak ister misin?';

  @override
  String get getHint => 'İpucu Al';

  @override
  String get no => 'Hayır';

  @override
  String get helpButton => 'Yardım';

  @override
  String get hintsEmpty => 'İpuçların Bitti!';

  @override
  String get hintsEmptyMessage =>
      'Ustanın bilgeliğine ihtiyacın var ama ipucu hakkın kalmadı! Hemen ipucu satın al ve vakayı çöz.';

  @override
  String get hintsPromo => '💡 3 ipucu sadece 29.99 ₺!';

  @override
  String get hintStore => 'İPUCU MAĞAZASI';

  @override
  String get continueAlone => 'Kendi Başıma Devam Et';

  @override
  String get reportTitle => '🚨 Şikayet Et';

  @override
  String get reportMessage =>
      'AI tarafından üretilen rahatsız edici veya uygunsuz bir mesajı rapor etmek üzeresiniz. Bu oturum incelenmek üzere kaydedilecektir.';

  @override
  String get reportSuccess => 'Şikayetiniz alınmıştır. İncelenecektir.';

  @override
  String get reportFailed => 'Şikayet gönderilemedi.';

  @override
  String get chatPlaceholder => 'Kontrol et, test et, tamir et...';

  @override
  String get examining => 'İnceleniyor...';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileLoadError => 'Profil yüklenemedi';

  @override
  String get energy => 'Enerji';

  @override
  String get repairs => 'Tamir';

  @override
  String get series => 'Seri';

  @override
  String get hints => 'İpucu';

  @override
  String get accountLinked => '✅ Hesap Bağlı';

  @override
  String get accountAnonymous => '⚠️ Anonim Hesap';

  @override
  String get linkAccount => 'Hesabını Bağla';

  @override
  String get linkAccountMessage =>
      'Google veya Apple hesabınla giriş yap.\nSatın alımların ve ilerlemen güvende olsun!';

  @override
  String get signInGoogle => 'Google ile Giriş Yap';

  @override
  String get signInApple => 'Apple ile Giriş Yap';

  @override
  String get signInGoogleSuccess => '✅ Google hesabı bağlandı!';

  @override
  String get signInAppleSuccess => '✅ Apple hesabı bağlandı!';

  @override
  String get signInCancelled => 'Giriş iptal edildi';

  @override
  String get dailyBonus => 'Günlük Bonus Al';

  @override
  String get dailyBonusClaimed => 'Bugün alındı ✅';

  @override
  String get dailyBonusReward => '+1 Enerji, +1 İpucu';

  @override
  String get dailyBonusSuccess => '🎁 Bonus alındı! +1 Enerji, +1 İpucu';

  @override
  String get dailyBonusAlready => 'Bonus zaten alınmış';

  @override
  String get watchAd => 'Reklam İzle';

  @override
  String get watchAdReward => '+1 Enerji kazan';

  @override
  String get watchAdSuccess => '🎬 +1 Enerji kazandın!';

  @override
  String get watchAdFailed => 'Reklam yüklenemedi';

  @override
  String get premium => 'Premium';

  @override
  String get premiumFree => 'Sınırsız enerji, reklamsız';

  @override
  String get premiumComingSoon => '🚧 Yakında! Premium özellikler geliyor...';

  @override
  String get restorePurchases => 'Satın Alımları Geri Yükle';

  @override
  String get restorePurchasesSub => 'Önceki satın alımlarını yükle';

  @override
  String get restoreSuccess =>
      '✅ Satın alımlar kontrol edildi ve geri yüklendi!';

  @override
  String get restoreEmpty => 'Satın alım bulunamadı.';

  @override
  String get settings => 'Ayarlar';

  @override
  String get settingsSub => 'Dil, bildirimler';

  @override
  String get language => 'Dil';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get signOutSub => 'Anonim hesaba dön';

  @override
  String get signOutConfirm => 'Çıkış Yap?';

  @override
  String get signOutMessage =>
      'Anonim hesaba döneceksin. Tekrar giriş yaparsan veriler geri gelir.';

  @override
  String get difficultyEasy => 'Kolay';

  @override
  String get difficultyMedium => 'Orta';

  @override
  String get difficultyHard => 'Zor';

  @override
  String get difficultyEasySub => 'Akü, marş motoru, bujiler';

  @override
  String get difficultyMediumSub => 'LPG, yakıt pompası, sensörler';

  @override
  String get difficultyHardSub => 'Conta, turbo, şanzıman';

  @override
  String get casesCount => '5 vaka';

  @override
  String get selectCase => 'Yeni Vaka Seç';

  @override
  String get garageWelcome => 'Garaj seni bekliyor, usta.';

  @override
  String streakProgress(Object current, Object total) {
    return 'Seri: $current/$total';
  }

  @override
  String get bonusEnergyShort => '🎁 +1 Enerji';

  @override
  String get weeklyTab => 'Haftalık';

  @override
  String get monthlyTab => 'Aylık';

  @override
  String get yearlyTab => 'Yıllık';

  @override
  String get leaderboardEmpty => 'Henüz kimse sıralamaya girmedi';

  @override
  String get leaderboardBeFirst => 'İlk sen ol! 🔧';

  @override
  String get casesTitle => 'Vakalar';

  @override
  String get goPro => 'Pro\'ya Geç';

  @override
  String get rankNovice => 'Acemi';

  @override
  String get rankApprentice => 'Çırak';

  @override
  String get rankJourneyman => 'Kalfa';

  @override
  String get rankMaster => 'Usta Tamirci';

  @override
  String get tip1 =>
      'İpucu: Önce müşteriyi dinle, sonra gözle. Teşhis koymadan tamir yapma!';

  @override
  String get tip2 =>
      'İpucu: OBD-II tarayıcı her zaman en iyi dostundur. İlk iş olarak bağla.';

  @override
  String get tip3 =>
      'İpucu: Eğer motor dönüyor ama çalışmıyorsa, ateşleme veya yakıt sorunu olabilir.';

  @override
  String get tip4 =>
      'İpucu: İpuçları tükenirse ustadan yardım isteyebilirsin. Pro pakette sınırsızdır.';

  @override
  String get tip5 =>
      'İpucu: Ucuz parçaları önce test et. Rastgele parça değiştirmek sana eksi puan getirir.';

  @override
  String get tip6 =>
      'İpucu: Fren sesleri genelde balatalardan gelir, ancak kampanaları da kontrol etmeyi unutma.';

  @override
  String get paywallTitle => 'PRO TAMİRCİ';

  @override
  String get paywallHero => 'Garajın Yeni Patronu Ol!';

  @override
  String get paywallFeature1 => 'Sınırsız Enerji (Beklemek yok)';

  @override
  String get paywallFeature2 => 'Her vaka için sınırsız ipucu';

  @override
  String get paywallFeature3 => 'Tüm Reklamları Kaldır';

  @override
  String get weeklyPlan => 'Haftalık Plan';

  @override
  String get weeklyPlanSub => 'Kısa süreli ustalık';

  @override
  String get monthlyPlan => 'Aylık Plan';

  @override
  String get monthlyPlanSub => 'Sadece 13 ₺ / Gün';

  @override
  String get monthlyPlanTag => 'EN ÇOK SATAN — %61 KÂR';

  @override
  String get yearlyPlan => 'Yıllık Plan';

  @override
  String get yearlyPlanSub => 'Uzun vadeli yatırım';

  @override
  String get upgradeNow => 'ŞİMDİ YÜKSELT';

  @override
  String get termsOfUse => 'Kullanım Koşulları';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get restore => 'Geri Yükle';

  @override
  String get paywallSuccess => 'Satın alma başarılı! Pro özellikler açıldı.';

  @override
  String get case1Vehicle => '2002 Japon Sedan 1.6';

  @override
  String get case1Complaint =>
      'Araba hiç çalışmıyor, anahtar çevirince ses yok.';

  @override
  String get case2Vehicle => '2006 Amerikan Hatchback 1.6';

  @override
  String get case2Complaint =>
      'Anahtar çevirince tıklama sesi var ama motor dönmüyor.';

  @override
  String get case3Vehicle => '2008 Alman Hatchback 1.4';

  @override
  String get case3Complaint => 'Sol far çalışmıyor, sağ far sorunsuz.';

  @override
  String get case4Vehicle => '2010 Fransız Sedan 1.5';

  @override
  String get case4Complaint =>
      'Silecekler hiç hareket etmiyor, cam suyu fışkırıyor.';

  @override
  String get case5Vehicle => '2004 Alman Hatchback 1.6';

  @override
  String get case5Complaint => 'Klima hava üflüyor ama hiç soğutmuyor.';

  @override
  String get case6Vehicle => '2015 Kore Hatchback 1.4';

  @override
  String get case6Complaint => 'Motor harareti 15 dakikada kırmızıya çıkıyor.';

  @override
  String get case7Vehicle => '1998 İtalyan Hatchback 1.6';

  @override
  String get case7Complaint => 'Sabahları zor çalışıyor, rölantide sallanıyor.';

  @override
  String get case8Vehicle => '2012 Japon Sedan 1.6';

  @override
  String get case8Complaint =>
      'Vites geçişleri, özellikle 1-2 arası çok sert ve sarsıntılı.';

  @override
  String get case9Vehicle => '2009 Fransız Hatchback 1.4';

  @override
  String get case9Complaint =>
      'Düşük hızda frene basınca ön tekerlerden tiz bir gıcırtı geliyor.';

  @override
  String get case10Vehicle => '2007 Japon Hatchback 1.5';

  @override
  String get case10Complaint =>
      'Motor uyarı lambası yandı. Araç biraz hantal ve yakıtı fazla tüketiyor.';

  @override
  String get case11Vehicle => '2003 BMW 320i E46';

  @override
  String get case11Complaint =>
      'Motor yağ yakıyor. 1000 km\'de bir yağ ekliyorum ve hızlanırken egzozdan mavi duman çıkıyor.';

  @override
  String get case12Vehicle => '2007 Volkswagen Passat 1.9 TDI';

  @override
  String get case12Complaint =>
      'Soğuk sabahlarda zor çalışıyor, çalışınca birkaç dakika beyaz duman atıyor ve su eksiltiyor.';

  @override
  String get case13Vehicle => '2013 Renault Megane 1.5 dCi';

  @override
  String get case13Complaint =>
      'Motor tarafından uğultu geliyor ve sabah arabanın altında yeşilimsi sıvı birikintisi gördüm.';

  @override
  String get case14Vehicle => '2004 Fiat Doblo 1.9 JTD';

  @override
  String get case14Complaint =>
      'Motor çok güç kaybetti. Yokuş çıkmakta zorlanıyor, bazen gaz verince stop ediyor.';

  @override
  String get case15Vehicle => '2010 Hyundai Accent Era 1.5 CRDi';

  @override
  String get case15Complaint =>
      'Benzinde sorunsuz ama LPG\'de tekliyor, güçsüzleşiyor ve gaz yemiyor.';

  @override
  String get analyzing => 'İnceleniyor...';

  @override
  String get master => 'Usta';

  @override
  String get claimBonus => 'Bonus Al!';

  @override
  String get bonusEnergy => '+1 Enerji';

  @override
  String get bonusHint => '+1 İpucu';

  @override
  String get watchAdButton => 'İzle';

  @override
  String get adEnergySuccess => '🎬 +1 Enerji kazandın!';

  @override
  String get adApiFail => 'Ödül API hatası';

  @override
  String get adLoadFail => 'Reklam yüklenemedi veya yarıda kesildi.';

  @override
  String get hintError => 'İpucu hatası';

  @override
  String get splashTitle => 'SANAYİ USTASI';

  @override
  String get splashSubtitle => 'Garajın Seni Bekliyor';

  @override
  String get fomoTitle => 'GİZLİ TEKLİF!';

  @override
  String get fomoBody =>
      'Sadece şu an için geçerli! Sınırsız enerji ve tüm ustalık özellikleri seni bekliyor. Bu fırsatı kaçırma!';

  @override
  String get fomoPopupTitle => 'GİZLİ TEKLİF';

  @override
  String get fomoOffer => '1 Haftalık Sınırsız Enerji\n🎁 +5 İpucu Hediye!';

  @override
  String get fomoDiscount => '%80 İNDİRİM!';

  @override
  String fomoViewers(String count) {
    return '$count kişi teklifi inceliyor';
  }

  @override
  String get fomoBuy => 'TÜKENMEDEN AL';

  @override
  String get fomoSkip => 'Fırsatı Kaçır ve Normal Devam Et';

  @override
  String cooldownAdSuccess(String remaining) {
    return '🎬 1 Saat düştü! Kalan: $remaining';
  }

  @override
  String get googleLinked => '✅ Google hesabı bağlandı!';

  @override
  String get appleLinked => '✅ Apple hesabı bağlandı!';

  @override
  String get loginCancelled => 'Giriş iptal edildi';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get enterNewName => 'Yeni ismini gir';

  @override
  String get saveSuccess => 'Başarıyla güncellendi!';

  @override
  String get save => 'Kaydet';
}
