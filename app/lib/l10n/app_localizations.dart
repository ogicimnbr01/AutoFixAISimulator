import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'AutoFix AI Simülatör'**
  String get appTitle;

  /// No description provided for @tabGarage.
  ///
  /// In tr, this message translates to:
  /// **'Garaj'**
  String get tabGarage;

  /// No description provided for @tabLeaderboard.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama'**
  String get tabLeaderboard;

  /// No description provided for @tabProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get send;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @customerComplaint.
  ///
  /// In tr, this message translates to:
  /// **'🧑‍🔧 Müşteri: \"{complaint}\"'**
  String customerComplaint(Object complaint);

  /// No description provided for @noEnergy.
  ///
  /// In tr, this message translates to:
  /// **'⚡ Enerji bitti! Reklam izle veya bekle.'**
  String get noEnergy;

  /// No description provided for @fallbackError.
  ///
  /// In tr, this message translates to:
  /// **'⚡ Garajın şartelleri attı. Tekrar dene.'**
  String get fallbackError;

  /// No description provided for @caseSolved.
  ///
  /// In tr, this message translates to:
  /// **'✅ Vaka Çözüldü!'**
  String get caseSolved;

  /// No description provided for @repairSuccess.
  ///
  /// In tr, this message translates to:
  /// **'🏆 Tamir Başarılı!'**
  String get repairSuccess;

  /// No description provided for @seriesInfo.
  ///
  /// In tr, this message translates to:
  /// **'Seri: {streak} | +1 Ün Puanı'**
  String seriesInfo(Object streak);

  /// No description provided for @bonusEnergyTag.
  ///
  /// In tr, this message translates to:
  /// **' | 🎁 +1 Bonus Enerji!'**
  String get bonusEnergyTag;

  /// No description provided for @backToGarage.
  ///
  /// In tr, this message translates to:
  /// **'Garaja Dön'**
  String get backToGarage;

  /// No description provided for @messageCount.
  ///
  /// In tr, this message translates to:
  /// **'{count}/{limit} mesaj'**
  String messageCount(Object count, Object limit);

  /// No description provided for @cooldownLabel.
  ///
  /// In tr, this message translates to:
  /// **'⏰ Cooldown: {remaining}'**
  String cooldownLabel(Object remaining);

  /// No description provided for @cooldownMessage.
  ///
  /// In tr, this message translates to:
  /// **'{limit} mesaj limitine ulaştın'**
  String cooldownMessage(Object limit);

  /// No description provided for @watchAdContinue.
  ///
  /// In tr, this message translates to:
  /// **'Reklam İzle → Devam Et'**
  String get watchAdContinue;

  /// No description provided for @cooldownCleared.
  ///
  /// In tr, this message translates to:
  /// **'🎬 Cooldown sıfırlandı! Devam et.'**
  String get cooldownCleared;

  /// No description provided for @cooldownReduced.
  ///
  /// In tr, this message translates to:
  /// **'🎬 1 Saat düştü! Kalan: {remaining}'**
  String cooldownReduced(Object remaining);

  /// No description provided for @giveUpTitle.
  ///
  /// In tr, this message translates to:
  /// **'🏳️ Teslim Ol?'**
  String get giveUpTitle;

  /// No description provided for @giveUpMessage.
  ///
  /// In tr, this message translates to:
  /// **'Seri puanın kırılmaz, ama bu vaka çözülmüş sayılmaz. Devam etmek istediğine emin misin?'**
  String get giveUpMessage;

  /// No description provided for @giveUpButton.
  ///
  /// In tr, this message translates to:
  /// **'Teslim Ol'**
  String get giveUpButton;

  /// No description provided for @continueButton.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueButton;

  /// No description provided for @hintTimeTitle.
  ///
  /// In tr, this message translates to:
  /// **'İpucu Zamanı!'**
  String get hintTimeTitle;

  /// No description provided for @hintTimeMessage.
  ///
  /// In tr, this message translates to:
  /// **'15 mesajı geçtin ama çözememedin. Ustaya danışmak ister misin?'**
  String get hintTimeMessage;

  /// No description provided for @getHint.
  ///
  /// In tr, this message translates to:
  /// **'İpucu Al'**
  String get getHint;

  /// No description provided for @no.
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get no;

  /// No description provided for @helpButton.
  ///
  /// In tr, this message translates to:
  /// **'Yardım'**
  String get helpButton;

  /// No description provided for @hintsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'İpuçların Bitti!'**
  String get hintsEmpty;

  /// No description provided for @hintsEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Ustanın bilgeliğine ihtiyacın var ama ipucu hakkın kalmadı! Hemen ipucu satın al ve vakayı çöz.'**
  String get hintsEmptyMessage;

  /// No description provided for @hintsPromo.
  ///
  /// In tr, this message translates to:
  /// **'💡 3 ipucu sadece 29.99 ₺!'**
  String get hintsPromo;

  /// No description provided for @hintStore.
  ///
  /// In tr, this message translates to:
  /// **'İPUCU MAĞAZASI'**
  String get hintStore;

  /// No description provided for @continueAlone.
  ///
  /// In tr, this message translates to:
  /// **'Kendi Başıma Devam Et'**
  String get continueAlone;

  /// No description provided for @reportTitle.
  ///
  /// In tr, this message translates to:
  /// **'🚨 Şikayet Et'**
  String get reportTitle;

  /// No description provided for @reportMessage.
  ///
  /// In tr, this message translates to:
  /// **'AI tarafından üretilen rahatsız edici veya uygunsuz bir mesajı rapor etmek üzeresiniz. Bu oturum incelenmek üzere kaydedilecektir.'**
  String get reportMessage;

  /// No description provided for @reportSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Şikayetiniz alınmıştır. İncelenecektir.'**
  String get reportSuccess;

  /// No description provided for @reportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Şikayet gönderilemedi.'**
  String get reportFailed;

  /// No description provided for @chatPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'Kontrol et, test et, tamir et...'**
  String get chatPlaceholder;

  /// No description provided for @examining.
  ///
  /// In tr, this message translates to:
  /// **'İnceleniyor...'**
  String get examining;

  /// No description provided for @profileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profileLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Profil yüklenemedi'**
  String get profileLoadError;

  /// No description provided for @energy.
  ///
  /// In tr, this message translates to:
  /// **'Enerji'**
  String get energy;

  /// No description provided for @repairs.
  ///
  /// In tr, this message translates to:
  /// **'Tamir'**
  String get repairs;

  /// No description provided for @series.
  ///
  /// In tr, this message translates to:
  /// **'Seri'**
  String get series;

  /// No description provided for @hints.
  ///
  /// In tr, this message translates to:
  /// **'İpucu'**
  String get hints;

  /// No description provided for @accountLinked.
  ///
  /// In tr, this message translates to:
  /// **'✅ Hesap Bağlı'**
  String get accountLinked;

  /// No description provided for @accountAnonymous.
  ///
  /// In tr, this message translates to:
  /// **'⚠️ Anonim Hesap'**
  String get accountAnonymous;

  /// No description provided for @linkAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabını Bağla'**
  String get linkAccount;

  /// No description provided for @linkAccountMessage.
  ///
  /// In tr, this message translates to:
  /// **'Google veya Apple hesabınla giriş yap.\nSatın alımların ve ilerlemen güvende olsun!'**
  String get linkAccountMessage;

  /// No description provided for @signInGoogle.
  ///
  /// In tr, this message translates to:
  /// **'Google ile Giriş Yap'**
  String get signInGoogle;

  /// No description provided for @signInApple.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile Giriş Yap'**
  String get signInApple;

  /// No description provided for @signInGoogleSuccess.
  ///
  /// In tr, this message translates to:
  /// **'✅ Google hesabı bağlandı!'**
  String get signInGoogleSuccess;

  /// No description provided for @signInAppleSuccess.
  ///
  /// In tr, this message translates to:
  /// **'✅ Apple hesabı bağlandı!'**
  String get signInAppleSuccess;

  /// No description provided for @signInCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Giriş iptal edildi'**
  String get signInCancelled;

  /// No description provided for @dailyBonus.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Bonus Al'**
  String get dailyBonus;

  /// No description provided for @dailyBonusClaimed.
  ///
  /// In tr, this message translates to:
  /// **'Bugün alındı ✅'**
  String get dailyBonusClaimed;

  /// No description provided for @dailyBonusReward.
  ///
  /// In tr, this message translates to:
  /// **'+1 Enerji, +1 İpucu'**
  String get dailyBonusReward;

  /// No description provided for @dailyBonusSuccess.
  ///
  /// In tr, this message translates to:
  /// **'🎁 Bonus alındı! +1 Enerji, +1 İpucu'**
  String get dailyBonusSuccess;

  /// No description provided for @dailyBonusAlready.
  ///
  /// In tr, this message translates to:
  /// **'Bonus zaten alınmış'**
  String get dailyBonusAlready;

  /// No description provided for @watchAd.
  ///
  /// In tr, this message translates to:
  /// **'Reklam İzle'**
  String get watchAd;

  /// No description provided for @watchAdReward.
  ///
  /// In tr, this message translates to:
  /// **'+1 Enerji kazan'**
  String get watchAdReward;

  /// No description provided for @watchAdSuccess.
  ///
  /// In tr, this message translates to:
  /// **'🎬 +1 Enerji kazandın!'**
  String get watchAdSuccess;

  /// No description provided for @watchAdFailed.
  ///
  /// In tr, this message translates to:
  /// **'Reklam yüklenemedi'**
  String get watchAdFailed;

  /// No description provided for @premium.
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @premiumFree.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız enerji, reklamsız'**
  String get premiumFree;

  /// No description provided for @premiumComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'🚧 Yakında! Premium özellikler geliyor...'**
  String get premiumComingSoon;

  /// No description provided for @restorePurchases.
  ///
  /// In tr, this message translates to:
  /// **'Satın Alımları Geri Yükle'**
  String get restorePurchases;

  /// No description provided for @restorePurchasesSub.
  ///
  /// In tr, this message translates to:
  /// **'Önceki satın alımlarını yükle'**
  String get restorePurchasesSub;

  /// No description provided for @restoreSuccess.
  ///
  /// In tr, this message translates to:
  /// **'✅ Satın alımlar kontrol edildi ve geri yüklendi!'**
  String get restoreSuccess;

  /// No description provided for @restoreEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Satın alım bulunamadı.'**
  String get restoreEmpty;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @settingsSub.
  ///
  /// In tr, this message translates to:
  /// **'Dil, bildirimler'**
  String get settingsSub;

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @signOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get signOut;

  /// No description provided for @signOutSub.
  ///
  /// In tr, this message translates to:
  /// **'Anonim hesaba dön'**
  String get signOutSub;

  /// No description provided for @signOutConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap?'**
  String get signOutConfirm;

  /// No description provided for @signOutMessage.
  ///
  /// In tr, this message translates to:
  /// **'Anonim hesaba döneceksin. Tekrar giriş yaparsan veriler geri gelir.'**
  String get signOutMessage;

  /// No description provided for @difficultyEasy.
  ///
  /// In tr, this message translates to:
  /// **'Kolay'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In tr, this message translates to:
  /// **'Zor'**
  String get difficultyHard;

  /// No description provided for @difficultyEasySub.
  ///
  /// In tr, this message translates to:
  /// **'Akü, marş motoru, bujiler'**
  String get difficultyEasySub;

  /// No description provided for @difficultyMediumSub.
  ///
  /// In tr, this message translates to:
  /// **'LPG, yakıt pompası, sensörler'**
  String get difficultyMediumSub;

  /// No description provided for @difficultyHardSub.
  ///
  /// In tr, this message translates to:
  /// **'Conta, turbo, şanzıman'**
  String get difficultyHardSub;

  /// No description provided for @casesCount.
  ///
  /// In tr, this message translates to:
  /// **'5 vaka'**
  String get casesCount;

  /// No description provided for @selectCase.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Vaka Seç'**
  String get selectCase;

  /// No description provided for @garageWelcome.
  ///
  /// In tr, this message translates to:
  /// **'Garaj seni bekliyor, usta.'**
  String get garageWelcome;

  /// No description provided for @streakProgress.
  ///
  /// In tr, this message translates to:
  /// **'Seri: {current}/{total}'**
  String streakProgress(Object current, Object total);

  /// No description provided for @bonusEnergyShort.
  ///
  /// In tr, this message translates to:
  /// **'🎁 +1 Enerji'**
  String get bonusEnergyShort;

  /// No description provided for @weeklyTab.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get weeklyTab;

  /// No description provided for @monthlyTab.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get monthlyTab;

  /// No description provided for @yearlyTab.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık'**
  String get yearlyTab;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kimse sıralamaya girmedi'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardBeFirst.
  ///
  /// In tr, this message translates to:
  /// **'İlk sen ol! 🔧'**
  String get leaderboardBeFirst;

  /// No description provided for @casesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Vakalar'**
  String get casesTitle;

  /// No description provided for @goPro.
  ///
  /// In tr, this message translates to:
  /// **'Pro\'ya Geç'**
  String get goPro;

  /// No description provided for @rankNovice.
  ///
  /// In tr, this message translates to:
  /// **'Acemi'**
  String get rankNovice;

  /// No description provided for @rankApprentice.
  ///
  /// In tr, this message translates to:
  /// **'Çırak'**
  String get rankApprentice;

  /// No description provided for @rankJourneyman.
  ///
  /// In tr, this message translates to:
  /// **'Kalfa'**
  String get rankJourneyman;

  /// No description provided for @rankMaster.
  ///
  /// In tr, this message translates to:
  /// **'Usta Tamirci'**
  String get rankMaster;

  /// No description provided for @tip1.
  ///
  /// In tr, this message translates to:
  /// **'İpucu: Önce müşteriyi dinle, sonra gözle. Teşhis koymadan tamir yapma!'**
  String get tip1;

  /// No description provided for @tip2.
  ///
  /// In tr, this message translates to:
  /// **'İpucu: OBD-II tarayıcı her zaman en iyi dostundur. İlk iş olarak bağla.'**
  String get tip2;

  /// No description provided for @tip3.
  ///
  /// In tr, this message translates to:
  /// **'İpucu: Eğer motor dönüyor ama çalışmıyorsa, ateşleme veya yakıt sorunu olabilir.'**
  String get tip3;

  /// No description provided for @tip4.
  ///
  /// In tr, this message translates to:
  /// **'İpucu: İpuçları tükenirse ustadan yardım isteyebilirsin. Pro pakette sınırsızdır.'**
  String get tip4;

  /// No description provided for @tip5.
  ///
  /// In tr, this message translates to:
  /// **'İpucu: Ucuz parçaları önce test et. Rastgele parça değiştirmek sana eksi puan getirir.'**
  String get tip5;

  /// No description provided for @tip6.
  ///
  /// In tr, this message translates to:
  /// **'İpucu: Fren sesleri genelde balatalardan gelir, ancak kampanaları da kontrol etmeyi unutma.'**
  String get tip6;

  /// No description provided for @paywallTitle.
  ///
  /// In tr, this message translates to:
  /// **'PRO TAMİRCİ'**
  String get paywallTitle;

  /// No description provided for @paywallHero.
  ///
  /// In tr, this message translates to:
  /// **'Garajın Yeni Patronu Ol!'**
  String get paywallHero;

  /// No description provided for @paywallFeature1.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız Enerji (Beklemek yok)'**
  String get paywallFeature1;

  /// No description provided for @paywallFeature2.
  ///
  /// In tr, this message translates to:
  /// **'Her vaka için sınırsız ipucu'**
  String get paywallFeature2;

  /// No description provided for @paywallFeature3.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Reklamları Kaldır'**
  String get paywallFeature3;

  /// No description provided for @weeklyPlan.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık Plan'**
  String get weeklyPlan;

  /// No description provided for @weeklyPlanSub.
  ///
  /// In tr, this message translates to:
  /// **'Kısa süreli ustalık'**
  String get weeklyPlanSub;

  /// No description provided for @monthlyPlan.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Plan'**
  String get monthlyPlan;

  /// No description provided for @monthlyPlanSub.
  ///
  /// In tr, this message translates to:
  /// **'Sadece 13 ₺ / Gün'**
  String get monthlyPlanSub;

  /// No description provided for @monthlyPlanTag.
  ///
  /// In tr, this message translates to:
  /// **'EN ÇOK SATAN — %61 KÂR'**
  String get monthlyPlanTag;

  /// No description provided for @yearlyPlan.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık Plan'**
  String get yearlyPlan;

  /// No description provided for @yearlyPlanSub.
  ///
  /// In tr, this message translates to:
  /// **'Uzun vadeli yatırım'**
  String get yearlyPlanSub;

  /// No description provided for @upgradeNow.
  ///
  /// In tr, this message translates to:
  /// **'ŞİMDİ YÜKSELT'**
  String get upgradeNow;

  /// No description provided for @termsOfUse.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicy;

  /// No description provided for @restore.
  ///
  /// In tr, this message translates to:
  /// **'Geri Yükle'**
  String get restore;

  /// No description provided for @paywallSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma başarılı! Pro özellikler açıldı.'**
  String get paywallSuccess;

  /// No description provided for @case1Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2002 Japon Sedan 1.6'**
  String get case1Vehicle;

  /// No description provided for @case1Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Araba hiç çalışmıyor, anahtar çevirince ses yok.'**
  String get case1Complaint;

  /// No description provided for @case2Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2006 Amerikan Hatchback 1.6'**
  String get case2Vehicle;

  /// No description provided for @case2Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Anahtar çevirince tıklama sesi var ama motor dönmüyor.'**
  String get case2Complaint;

  /// No description provided for @case3Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2008 Alman Hatchback 1.4'**
  String get case3Vehicle;

  /// No description provided for @case3Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Sol far çalışmıyor, sağ far sorunsuz.'**
  String get case3Complaint;

  /// No description provided for @case4Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2010 Fransız Sedan 1.5'**
  String get case4Vehicle;

  /// No description provided for @case4Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Silecekler hiç hareket etmiyor, cam suyu fışkırıyor.'**
  String get case4Complaint;

  /// No description provided for @case5Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2004 Alman Hatchback 1.6'**
  String get case5Vehicle;

  /// No description provided for @case5Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Klima hava üflüyor ama hiç soğutmuyor.'**
  String get case5Complaint;

  /// No description provided for @case6Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2015 Kore Hatchback 1.4'**
  String get case6Vehicle;

  /// No description provided for @case6Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Motor harareti 15 dakikada kırmızıya çıkıyor.'**
  String get case6Complaint;

  /// No description provided for @case7Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'1998 İtalyan Hatchback 1.6'**
  String get case7Vehicle;

  /// No description provided for @case7Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Sabahları zor çalışıyor, rölantide sallanıyor.'**
  String get case7Complaint;

  /// No description provided for @case8Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2012 Japon Sedan 1.6'**
  String get case8Vehicle;

  /// No description provided for @case8Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Vites geçişleri, özellikle 1-2 arası çok sert ve sarsıntılı.'**
  String get case8Complaint;

  /// No description provided for @case9Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2009 Fransız Hatchback 1.4'**
  String get case9Vehicle;

  /// No description provided for @case9Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Düşük hızda frene basınca ön tekerlerden tiz bir gıcırtı geliyor.'**
  String get case9Complaint;

  /// No description provided for @case10Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2007 Japon Hatchback 1.5'**
  String get case10Vehicle;

  /// No description provided for @case10Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Gaza basınca devir artıyor ama araç hızlanmıyor (bağırıyor ama gitmiyor).'**
  String get case10Complaint;

  /// No description provided for @case11Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2005 Premium Alman Sedan 2.0'**
  String get case11Vehicle;

  /// No description provided for @case11Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Motor uyarı lambası yanıyor ve araç 3000 deviri geçmiyor.'**
  String get case11Complaint;

  /// No description provided for @case12Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2011 Premium Alman Sedan 2.1'**
  String get case12Vehicle;

  /// No description provided for @case12Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Motor suyuna yağ karışmış, antifriz kabı tahin gibi olmuş.'**
  String get case12Complaint;

  /// No description provided for @case13Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2003 Premium Alman Sedan 1.8'**
  String get case13Vehicle;

  /// No description provided for @case13Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Ön camdan ve sunroof çevresinden yağmurlu havalarda su alıyor.'**
  String get case13Complaint;

  /// No description provided for @case14Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2014 Premium İsveç Sedan 2.0'**
  String get case14Vehicle;

  /// No description provided for @case14Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Direksiyon çok ağırlaştı, döndürmek neredeyse imkansız.'**
  String get case14Complaint;

  /// No description provided for @case15Vehicle.
  ///
  /// In tr, this message translates to:
  /// **'2016 Çek Sedan 1.6'**
  String get case15Vehicle;

  /// No description provided for @case15Complaint.
  ///
  /// In tr, this message translates to:
  /// **'Hız sabitleyici ve şerit takip asistanı devre dışı kaldı uyarısı.'**
  String get case15Complaint;

  /// No description provided for @analyzing.
  ///
  /// In tr, this message translates to:
  /// **'İnceleniyor...'**
  String get analyzing;

  /// No description provided for @master.
  ///
  /// In tr, this message translates to:
  /// **'Usta'**
  String get master;

  /// No description provided for @claimBonus.
  ///
  /// In tr, this message translates to:
  /// **'Bonus Al!'**
  String get claimBonus;

  /// No description provided for @bonusEnergy.
  ///
  /// In tr, this message translates to:
  /// **'+1 Enerji'**
  String get bonusEnergy;

  /// No description provided for @bonusHint.
  ///
  /// In tr, this message translates to:
  /// **'+1 İpucu'**
  String get bonusHint;

  /// No description provided for @watchAdButton.
  ///
  /// In tr, this message translates to:
  /// **'İzle'**
  String get watchAdButton;

  /// No description provided for @adEnergySuccess.
  ///
  /// In tr, this message translates to:
  /// **'🎬 +1 Enerji kazandın!'**
  String get adEnergySuccess;

  /// No description provided for @adApiFail.
  ///
  /// In tr, this message translates to:
  /// **'Ödül API hatası'**
  String get adApiFail;

  /// No description provided for @adLoadFail.
  ///
  /// In tr, this message translates to:
  /// **'Reklam yüklenemedi veya yarıda kesildi.'**
  String get adLoadFail;

  /// No description provided for @hintError.
  ///
  /// In tr, this message translates to:
  /// **'İpucu hatası'**
  String get hintError;

  /// No description provided for @splashTitle.
  ///
  /// In tr, this message translates to:
  /// **'SANAYİ USTASI'**
  String get splashTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Garajın Seni Bekliyor'**
  String get splashSubtitle;

  /// No description provided for @fomoTitle.
  ///
  /// In tr, this message translates to:
  /// **'GİZLİ TEKLİF!'**
  String get fomoTitle;

  /// No description provided for @fomoBody.
  ///
  /// In tr, this message translates to:
  /// **'Sadece şu an için geçerli! Sınırsız enerji ve tüm ustalık özellikleri seni bekliyor. Bu fırsatı kaçırma!'**
  String get fomoBody;

  /// No description provided for @fomoPopupTitle.
  ///
  /// In tr, this message translates to:
  /// **'GİZLİ TEKLİF'**
  String get fomoPopupTitle;

  /// No description provided for @fomoOffer.
  ///
  /// In tr, this message translates to:
  /// **'1 Haftalık Sınırsız Enerji\n🎁 +5 İpucu Hediye!'**
  String get fomoOffer;

  /// No description provided for @fomoDiscount.
  ///
  /// In tr, this message translates to:
  /// **'%80 İNDİRİM!'**
  String get fomoDiscount;

  /// No description provided for @fomoViewers.
  ///
  /// In tr, this message translates to:
  /// **'{count} kişi teklifi inceliyor'**
  String fomoViewers(String count);

  /// No description provided for @fomoBuy.
  ///
  /// In tr, this message translates to:
  /// **'TÜKENMEDEN AL'**
  String get fomoBuy;

  /// No description provided for @fomoSkip.
  ///
  /// In tr, this message translates to:
  /// **'Fırsatı Kaçır ve Normal Devam Et'**
  String get fomoSkip;

  /// No description provided for @cooldownAdSuccess.
  ///
  /// In tr, this message translates to:
  /// **'🎬 1 Saat düştü! Kalan: {remaining}'**
  String cooldownAdSuccess(String remaining);

  /// No description provided for @googleLinked.
  ///
  /// In tr, this message translates to:
  /// **'✅ Google hesabı bağlandı!'**
  String get googleLinked;

  /// No description provided for @appleLinked.
  ///
  /// In tr, this message translates to:
  /// **'✅ Apple hesabı bağlandı!'**
  String get appleLinked;

  /// No description provided for @loginCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Giriş iptal edildi'**
  String get loginCancelled;

  /// No description provided for @editProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profili Düzenle'**
  String get editProfile;

  /// No description provided for @enterNewName.
  ///
  /// In tr, this message translates to:
  /// **'Yeni ismini gir'**
  String get enterNewName;

  /// No description provided for @saveSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Başarıyla güncellendi!'**
  String get saveSuccess;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'tr', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'ru':
      return SRu();
    case 'tr':
      return STr();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
