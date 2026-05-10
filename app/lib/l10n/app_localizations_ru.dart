// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class SRu extends S {
  SRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'AutoFix AI Симулятор';

  @override
  String get tabGarage => 'Гараж';

  @override
  String get tabLeaderboard => 'Рейтинг';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get retry => 'Повторить';

  @override
  String get cancel => 'Отмена';

  @override
  String get send => 'Отправить';

  @override
  String get close => 'Закрыть';

  @override
  String customerComplaint(Object complaint) {
    return '🧑‍🔧 Клиент: \"$complaint\"';
  }

  @override
  String get noEnergy =>
      '⚡ Энергия закончилась! Посмотрите рекламу или подождите.';

  @override
  String get fallbackError => '⚡ В гараже выбило пробки. Попробуйте снова.';

  @override
  String get caseSolved => '✅ Дело решено!';

  @override
  String get repairSuccess => '🏆 Ремонт успешен!';

  @override
  String seriesInfo(Object streak) {
    return 'Серия: $streak | +1 очко репутации';
  }

  @override
  String get bonusEnergyTag => ' | 🎁 +1 Бонусная энергия!';

  @override
  String get backToGarage => 'Вернуться в гараж';

  @override
  String messageCount(Object count, Object limit) {
    return '$count/$limit сообщений';
  }

  @override
  String cooldownLabel(Object remaining) {
    return '⏰ Перерыв: $remaining';
  }

  @override
  String cooldownMessage(Object limit) {
    return 'Достигнут лимит в $limit сообщений';
  }

  @override
  String get watchAdContinue => 'Смотреть рекламу → Продолжить';

  @override
  String get cooldownCleared => '🎬 Перерыв сброшен! Продолжайте.';

  @override
  String cooldownReduced(Object remaining) {
    return '🎬 1 час снят! Осталось: $remaining';
  }

  @override
  String get giveUpTitle => '🏳️ Сдаться?';

  @override
  String get giveUpMessage =>
      'Ваша серия не прервётся, но этот случай не будет решён. Вы уверены?';

  @override
  String get giveUpButton => 'Сдаться';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get hintTimeTitle => 'Время подсказки!';

  @override
  String get hintTimeMessage =>
      'Вы отправили более 15 сообщений и не решили. Хотите спросить Мастера?';

  @override
  String get getHint => 'Получить подсказку';

  @override
  String get no => 'Нет';

  @override
  String get helpButton => 'Помощь';

  @override
  String get hintsEmpty => 'Подсказки закончились!';

  @override
  String get hintsEmptyMessage =>
      'Вам нужна мудрость Мастера, но у вас нет подсказок! Купите подсказки, чтобы решить дело.';

  @override
  String get hintsPromo => '💡 3 подсказки всего за 29₽!';

  @override
  String get hintStore => 'МАГАЗИН ПОДСКАЗОК';

  @override
  String get continueAlone => 'Продолжу сам';

  @override
  String get reportTitle => '🚨 Пожаловаться';

  @override
  String get reportMessage =>
      'Вы собираетесь сообщить о неуместном сообщении ИИ. Сессия будет записана для проверки.';

  @override
  String get reportSuccess => 'Ваша жалоба принята и будет рассмотрена.';

  @override
  String get reportFailed => 'Не удалось отправить жалобу.';

  @override
  String get chatPlaceholder => 'Проверить, протестировать, починить...';

  @override
  String get examining => 'Осматриваю...';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileLoadError => 'Не удалось загрузить профиль';

  @override
  String get energy => 'Энергия';

  @override
  String get repairs => 'Ремонт';

  @override
  String get series => 'Серия';

  @override
  String get hints => 'Подсказки';

  @override
  String get accountLinked => '✅ Аккаунт привязан';

  @override
  String get accountAnonymous => '⚠️ Анонимный аккаунт';

  @override
  String get linkAccount => 'Привязать аккаунт';

  @override
  String get linkAccountMessage =>
      'Войдите через Google или Apple.\nСохраните покупки и прогресс!';

  @override
  String get signInGoogle => 'Войти через Google';

  @override
  String get signInApple => 'Войти через Apple';

  @override
  String get signInGoogleSuccess => '✅ Google аккаунт привязан!';

  @override
  String get signInAppleSuccess => '✅ Apple аккаунт привязан!';

  @override
  String get signInCancelled => 'Вход отменён';

  @override
  String get dailyBonus => 'Ежедневный бонус';

  @override
  String get dailyBonusClaimed => 'Получен сегодня ✅';

  @override
  String get dailyBonusReward => '+1 Энергия, +1 Подсказка';

  @override
  String get dailyBonusSuccess => '🎁 Бонус получен! +1 Энергия, +1 Подсказка';

  @override
  String get dailyBonusAlready => 'Бонус уже получен';

  @override
  String get watchAd => 'Смотреть рекламу';

  @override
  String get watchAdReward => 'Получить +1 Энергию';

  @override
  String get watchAdSuccess => '🎬 +1 Энергия получена!';

  @override
  String get watchAdFailed => 'Не удалось загрузить рекламу';

  @override
  String get premium => 'Премиум';

  @override
  String get premiumFree => 'Безлимитная энергия, без рекламы';

  @override
  String get premiumComingSoon => '🚧 Скоро! Премиум функции в разработке...';

  @override
  String get restorePurchases => 'Восстановить покупки';

  @override
  String get restorePurchasesSub => 'Загрузить предыдущие покупки';

  @override
  String get restoreSuccess => '✅ Покупки проверены и восстановлены!';

  @override
  String get restoreEmpty => 'Покупки не найдены.';

  @override
  String get settings => 'Настройки';

  @override
  String get settingsSub => 'Язык, уведомления';

  @override
  String get language => 'Язык';

  @override
  String get signOut => 'Выйти';

  @override
  String get signOutSub => 'Вернуться к анонимному аккаунту';

  @override
  String get signOutConfirm => 'Выйти?';

  @override
  String get signOutMessage =>
      'Вы вернётесь к анонимному аккаунту. Данные восстановятся при повторном входе.';

  @override
  String get difficultyEasy => 'Легко';

  @override
  String get difficultyMedium => 'Средне';

  @override
  String get difficultyHard => 'Сложно';

  @override
  String get difficultyEasySub => 'Аккумулятор, стартер, свечи';

  @override
  String get difficultyMediumSub => 'ГБО, топливный насос, датчики';

  @override
  String get difficultyHardSub => 'Прокладка, турбина, трансмиссия';

  @override
  String get casesCount => '5 случаев';

  @override
  String get selectCase => 'Выберите новое дело';

  @override
  String get garageWelcome => 'Гараж ждет тебя, мастер.';

  @override
  String streakProgress(Object current, Object total) {
    return 'Серия: $current/$total';
  }

  @override
  String get bonusEnergyShort => '🎁 +1 Энергия';

  @override
  String get weeklyTab => 'Неделя';

  @override
  String get monthlyTab => 'Месяц';

  @override
  String get yearlyTab => 'Год';

  @override
  String get leaderboardEmpty => 'Пока никого нет в рейтинге';

  @override
  String get leaderboardBeFirst => 'Будь первым! 🔧';

  @override
  String get casesTitle => 'Дела';

  @override
  String get goPro => 'Перейти на Pro';

  @override
  String get rankNovice => 'Новичок';

  @override
  String get rankApprentice => 'Подмастерье';

  @override
  String get rankJourneyman => 'Опытный';

  @override
  String get rankMaster => 'Мастер';

  @override
  String get tip1 =>
      'Совет: Сначала выслушайте клиента, затем осмотрите. Не чините без диагностики!';

  @override
  String get tip2 =>
      'Совет: Сканер OBD-II — ваш лучший друг. Всегда подключайте его первым.';

  @override
  String get tip3 =>
      'Совет: Если стартер крутит, но двигатель не заводится — проблема в зажигании или топливе.';

  @override
  String get tip4 =>
      'Совет: Закончились подсказки? Спросите Мастера. В Pro-версии подсказки безлимитны.';

  @override
  String get tip5 =>
      'Совет: Сначала проверяйте дешевые детали. Замена наугад снизит вашу репутацию.';

  @override
  String get tip6 =>
      'Совет: Скрип тормозов обычно идет от колодок, но не забывайте проверять барабаны.';

  @override
  String get paywallTitle => 'PRO МЕХАНИК';

  @override
  String get paywallHero => 'Стань Боссом Гаража!';

  @override
  String get paywallFeature1 => 'Безлимитная энергия (Без ожиданий)';

  @override
  String get paywallFeature2 => 'Безлимитные подсказки для всех дел';

  @override
  String get paywallFeature3 => 'Отключение всей рекламы';

  @override
  String get weeklyPlan => 'План на неделю';

  @override
  String get weeklyPlanSub => 'Краткосрочное мастерство';

  @override
  String get monthlyPlan => 'План на месяц';

  @override
  String get monthlyPlanSub => 'Всего 40 ₽ / день';

  @override
  String get monthlyPlanTag => 'ХИТ ПРОДАЖ — ВЫГОДА 61%';

  @override
  String get yearlyPlan => 'План на год';

  @override
  String get yearlyPlanSub => 'Долгосрочная инвестиция';

  @override
  String get upgradeNow => 'УЛУЧШИТЬ СЕЙЧАС';

  @override
  String get termsOfUse => 'Условия использования';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get restore => 'Восстановить';

  @override
  String get paywallSuccess => 'Покупка успешна! Pro функции разблокированы.';

  @override
  String get case1Vehicle => '2002 Японский седан 1.6';

  @override
  String get case1Complaint =>
      'Машина вообще не заводится, при повороте ключа нет звука.';

  @override
  String get case2Vehicle => '2006 Американский хэтчбек 1.6';

  @override
  String get case2Complaint =>
      'Щелчки при повороте ключа, но двигатель не крутит.';

  @override
  String get case3Vehicle => '2008 Немецкий хэтчбек 1.4';

  @override
  String get case3Complaint => 'Левая фара не работает, правая в порядке.';

  @override
  String get case4Vehicle => '2010 Французский седан 1.5';

  @override
  String get case4Complaint => 'Дворники не двигаются, но омывайка брызгает.';

  @override
  String get case5Vehicle => '2004 Немецкий хэтчбек 1.6';

  @override
  String get case5Complaint =>
      'Кондиционер дует, но воздух совсем не холодный.';

  @override
  String get case6Vehicle => '2015 Корейский хэтчбек 1.4';

  @override
  String get case6Complaint =>
      'Температура двигателя уходит в красную зону за 15 минут.';

  @override
  String get case7Vehicle => '1998 Итальянский хэтчбек 1.6';

  @override
  String get case7Complaint =>
      'Трудно заводится по утрам, сильно трясется на холостых.';

  @override
  String get case8Vehicle => '2012 Японский седан 1.6';

  @override
  String get case8Complaint =>
      'Переключение передач, особенно с 1 на 2, очень жесткое.';

  @override
  String get case9Vehicle => '2009 Французский хэтчбек 1.4';

  @override
  String get case9Complaint =>
      'Пронзительный писк от передних колес при торможении на малой скорости.';

  @override
  String get case10Vehicle => '2007 Японский хэтчбек 1.5';

  @override
  String get case10Complaint =>
      'Загорелся Check Engine. Машина стала вялой и расходует больше топлива.';

  @override
  String get case11Vehicle => '2003 BMW 320i E46';

  @override
  String get case11Complaint =>
      'Двигатель расходует масло. Доливаю каждые 1000 км, при разгоне из выхлопа идет синий дым.';

  @override
  String get case12Vehicle => '2007 Volkswagen Passat 1.9 TDI';

  @override
  String get case12Complaint =>
      'В холодные утра тяжело заводится, несколько минут идет белый дым и медленно уходит антифриз.';

  @override
  String get case13Vehicle => '2013 Renault Megane 1.5 dCi';

  @override
  String get case13Complaint =>
      'Со стороны двигателя слышен вой, утром под машиной увидел небольшую зеленоватую лужу.';

  @override
  String get case14Vehicle => '2004 Fiat Doblo 1.9 JTD';

  @override
  String get case14Complaint =>
      'Двигатель сильно потерял мощность. Едва тянет в гору и иногда глохнет при нажатии на газ.';

  @override
  String get case15Vehicle => '2010 Hyundai Accent Era 1.5 CRDi';

  @override
  String get case15Complaint =>
      'На бензине работает нормально, но на LPG дергается, троит и заметно теряет мощность.';

  @override
  String get analyzing => 'Анализ...';

  @override
  String get master => 'Мастер';

  @override
  String get claimBonus => 'Забрать бонус!';

  @override
  String get bonusEnergy => '+1 Энергия';

  @override
  String get bonusHint => '+1 Подсказка';

  @override
  String get watchAdButton => 'Смотреть';

  @override
  String get adEnergySuccess => '🎬 +1 Энергия получена!';

  @override
  String get adApiFail => 'Ошибка API награды';

  @override
  String get adLoadFail => 'Реклама не загрузилась или была прервана.';

  @override
  String get hintError => 'Ошибка подсказки';

  @override
  String get splashTitle => 'АВТОМАСТЕР';

  @override
  String get splashSubtitle => 'Гараж ждёт тебя';

  @override
  String get fomoTitle => 'СЕКРЕТНОЕ ПРЕДЛОЖЕНИЕ!';

  @override
  String get fomoBody =>
      'Доступно только сейчас! Безлимитная энергия и все функции мастерства ждут вас. Не упустите!';

  @override
  String get fomoPopupTitle => 'СЕКРЕТНОЕ ПРЕДЛОЖЕНИЕ';

  @override
  String get fomoOffer =>
      '1 Неделя безлимитной энергии\n🎁 +5 Подсказок бесплатно!';

  @override
  String get fomoDiscount => 'СКИДКА 80%!';

  @override
  String fomoViewers(String count) {
    return '$count человек смотрят предложение';
  }

  @override
  String get fomoBuy => 'УСПЕЙ КУПИТЬ';

  @override
  String get fomoSkip => 'Пропустить и продолжить';

  @override
  String cooldownAdSuccess(String remaining) {
    return '🎬 1 Час снят! Осталось: $remaining';
  }

  @override
  String get googleLinked => '✅ Аккаунт Google привязан!';

  @override
  String get appleLinked => '✅ Аккаунт Apple привязан!';

  @override
  String get loginCancelled => 'Вход отменён';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get enterNewName => 'Введите новое имя';

  @override
  String get saveSuccess => 'Успешно обновлено!';

  @override
  String get save => 'Сохранить';
}
