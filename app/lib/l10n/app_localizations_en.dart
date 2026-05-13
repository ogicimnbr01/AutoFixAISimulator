// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AutoFix AI Simulator';

  @override
  String get tabGarage => 'Garage';

  @override
  String get tabLeaderboard => 'Leaderboard';

  @override
  String get tabStore => 'Store';

  @override
  String get tabProfile => 'Profile';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get send => 'Send';

  @override
  String get close => 'Close';

  @override
  String customerComplaint(Object complaint) {
    return '🧑‍🔧 Customer: \"$complaint\"';
  }

  @override
  String get noEnergy => '⚡ No energy left! Watch an ad or wait.';

  @override
  String get fallbackError => '⚡ The garage blew a fuse. Try again.';

  @override
  String get caseSolved => '✅ Case Solved!';

  @override
  String get repairSuccess => '🏆 Repair Successful!';

  @override
  String seriesInfo(Object streak) {
    return 'Streak: $streak | +1 Rep Point';
  }

  @override
  String get bonusEnergyTag => ' | 🎁 +1 Bonus Energy!';

  @override
  String get backToGarage => 'Back to Garage';

  @override
  String messageCount(Object count, Object limit) {
    return '$count/$limit messages';
  }

  @override
  String cooldownLabel(Object remaining) {
    return '⏰ Cooldown: $remaining';
  }

  @override
  String cooldownMessage(Object limit) {
    return 'You\'ve reached the $limit message limit';
  }

  @override
  String get cooldownTitle => 'Case is taking longer';

  @override
  String get cooldownBody =>
      'This case has stretched a bit. When the timer ends, 18 more messages unlock; you can watch an ad to shorten the wait or return to the garage.';

  @override
  String get watchAdContinue => 'Watch Ad → Reduce 1 Hour';

  @override
  String get cooldownCleared => '🎬 Cooldown cleared! Continue.';

  @override
  String cooldownReduced(Object remaining) {
    return '🎬 1 hour reduced! Remaining: $remaining';
  }

  @override
  String get giveUpTitle => '🏳️ Give Up?';

  @override
  String get giveUpMessage =>
      'Your streak won\'t break, but this case won\'t count as solved. Are you sure?';

  @override
  String get giveUpButton => 'Give Up';

  @override
  String get continueButton => 'Continue';

  @override
  String get hintTimeTitle => 'Hint Time!';

  @override
  String get hintTimeMessage =>
      'You\'ve passed 15 messages but couldn\'t solve it. Want to consult the Master?';

  @override
  String get getHint => 'Get Hint';

  @override
  String get no => 'No';

  @override
  String get helpButton => 'Help';

  @override
  String get hintsEmpty => 'Out of Hints!';

  @override
  String get hintsEmptyMessage =>
      'You need the Master\'s wisdom but you\'re out of hint credits! Buy hints now to crack the case.';

  @override
  String get hintsPromo => '💡 3 hints for only \$0.99!';

  @override
  String get hintStore => 'HINT STORE';

  @override
  String get continueAlone => 'Continue on My Own';

  @override
  String get reportTitle => '🚨 Report';

  @override
  String get reportMessage =>
      'You are about to report an inappropriate AI message. This session will be logged for review.';

  @override
  String get reportSuccess =>
      'Your report has been received. It will be reviewed.';

  @override
  String get reportFailed => 'Failed to send report.';

  @override
  String get chatPlaceholder => 'Check, test, repair...';

  @override
  String get examining => 'Examining...';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLoadError => 'Failed to load profile';

  @override
  String get energy => 'Energy';

  @override
  String get repairs => 'Repairs';

  @override
  String get series => 'Streak';

  @override
  String get hints => 'Hints';

  @override
  String get accountLinked => '✅ Account Linked';

  @override
  String get accountAnonymous => '⚠️ Anonymous Account';

  @override
  String get linkAccount => 'Link Your Account';

  @override
  String get linkAccountMessage =>
      'Sign in with Google or Apple.\nKeep your purchases and progress safe!';

  @override
  String get signInGoogle => 'Sign in with Google';

  @override
  String get signInApple => 'Sign in with Apple';

  @override
  String get signInGoogleSuccess => '✅ Google account linked!';

  @override
  String get signInAppleSuccess => '✅ Apple account linked!';

  @override
  String get signInCancelled => 'Sign-in cancelled';

  @override
  String get dailyBonus => 'Daily Bonus';

  @override
  String get dailyBonusClaimed => 'Claimed today ✅';

  @override
  String get dailyBonusReward => '+1 Energy, +1 Hint';

  @override
  String get dailyBonusSuccess => '🎁 Bonus claimed! +1 Energy, +1 Hint';

  @override
  String get dailyBonusAlready => 'Bonus already claimed';

  @override
  String get watchAd => 'Watch Ad';

  @override
  String get watchAdReward => 'Earn +1 Energy';

  @override
  String get watchAdSuccess => '🎬 +1 Energy earned!';

  @override
  String get watchAdFailed => 'Failed to load ad';

  @override
  String get premium => 'Premium';

  @override
  String get premiumFree => 'Unlimited energy, no ads';

  @override
  String get premiumComingSoon =>
      '🚧 Coming soon! Premium features on the way...';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get restorePurchasesSub => 'Restore your previous purchases';

  @override
  String get restoreSuccess => '✅ Purchases checked and restored!';

  @override
  String get restoreEmpty => 'No purchases found.';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSub => 'Language, notifications';

  @override
  String get language => 'Language';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutSub => 'Return to anonymous account';

  @override
  String get signOutConfirm => 'Sign Out?';

  @override
  String get signOutMessage =>
      'You\'ll return to an anonymous account. Your data will come back when you sign in again.';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyEasySub => 'Battery, starter, spark plugs';

  @override
  String get difficultyMediumSub => 'LPG, fuel pump, sensors';

  @override
  String get difficultyHardSub => 'Gasket, turbo, transmission';

  @override
  String get casesCount => '5 cases';

  @override
  String get selectCase => 'Select a New Case';

  @override
  String get garageWelcome => 'The garage is waiting for you, master.';

  @override
  String streakProgress(Object current, Object total) {
    return 'Streak: $current/$total';
  }

  @override
  String get bonusEnergyShort => '🎁 +1 Energy';

  @override
  String get weeklyTab => 'Weekly';

  @override
  String get monthlyTab => 'Monthly';

  @override
  String get yearlyTab => 'Yearly';

  @override
  String get leaderboardEmpty => 'No one has entered the leaderboard yet';

  @override
  String get leaderboardBeFirst => 'Be the first! 🔧';

  @override
  String get casesTitle => 'Cases';

  @override
  String get goPro => 'Go Pro';

  @override
  String get rankNovice => 'Novice';

  @override
  String get rankApprentice => 'Apprentice';

  @override
  String get rankJourneyman => 'Journeyman';

  @override
  String get rankMaster => 'Master Mechanic';

  @override
  String get tip1 =>
      'Tip: Listen to the customer first, then observe. Don\'t repair without a diagnosis!';

  @override
  String get tip2 =>
      'Tip: The OBD-II scanner is your best friend. Always plug it in first.';

  @override
  String get tip3 =>
      'Tip: If the engine cranks but won\'t start, it might be an ignition or fuel issue.';

  @override
  String get tip4 =>
      'Tip: If you run out of hints, ask the Master. Pro users have unlimited hints.';

  @override
  String get tip5 =>
      'Tip: Test cheap parts first. Guessing parts will cost you reputation points.';

  @override
  String get tip6 =>
      'Tip: Brake noises usually come from pads, but don\'t forget to check the drums.';

  @override
  String get paywallTitle => 'PRO MECHANIC';

  @override
  String get paywallHero => 'Become the Boss of the Garage!';

  @override
  String get paywallFeature1 => 'Unlimited Energy (No waiting)';

  @override
  String get paywallFeature2 => 'Unlimited hints for every case';

  @override
  String get paywallFeature3 => 'Remove All Ads';

  @override
  String get weeklyPlan => 'Weekly Plan';

  @override
  String get weeklyPlanSub => 'Short-term mastery';

  @override
  String get monthlyPlan => 'Monthly Plan';

  @override
  String get monthlyPlanSub => 'Only \$0.50 / Day';

  @override
  String get monthlyPlanTag => 'BEST SELLER — 61% OFF';

  @override
  String get yearlyPlan => 'Yearly Plan';

  @override
  String get yearlyPlanSub => 'Long-term investment';

  @override
  String get upgradeNow => 'UPGRADE NOW';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get restore => 'Restore';

  @override
  String get paywallSuccess => 'Purchase successful! Pro features unlocked.';

  @override
  String get case1Vehicle => '2002 Japanese Sedan 1.6';

  @override
  String get case1Complaint =>
      'Car doesn\'t start at all, no sound when turning the key.';

  @override
  String get case2Vehicle => '2006 American Hatchback 1.6';

  @override
  String get case2Complaint =>
      'Clicking sound when turning key but engine won\'t crank.';

  @override
  String get case3Vehicle => '2008 German Hatchback 1.4';

  @override
  String get case3Complaint => 'Left headlight doesn\'t work, right is fine.';

  @override
  String get case4Vehicle => '2010 French Sedan 1.5';

  @override
  String get case4Complaint =>
      'Wipers not moving at all, but washer fluid sprays.';

  @override
  String get case5Vehicle => '2004 German Hatchback 1.6';

  @override
  String get case5Complaint => 'A/C blows air but it\'s not cold at all.';

  @override
  String get case6Vehicle => '2015 Korean Hatchback 1.4';

  @override
  String get case6Complaint =>
      'Engine temperature hits the red zone in 15 minutes.';

  @override
  String get case7Vehicle => '1998 Italian Hatchback 1.6';

  @override
  String get case7Complaint =>
      'Hard to start in mornings, shakes wildly at idle.';

  @override
  String get case8Vehicle => '2012 Japanese Sedan 1.6';

  @override
  String get case8Complaint =>
      'Gear shifts, especially 1st to 2nd, are very rough.';

  @override
  String get case9Vehicle => '2009 French Hatchback 1.4';

  @override
  String get case9Complaint =>
      'High-pitched squeak from front wheels when braking at low speed.';

  @override
  String get case10Vehicle => '2007 Japanese Hatchback 1.5';

  @override
  String get case10Complaint =>
      'The check engine light came on. The car feels sluggish and uses more fuel than usual.';

  @override
  String get case11Vehicle => '2003 BMW 320i E46';

  @override
  String get case11Complaint =>
      'The engine is burning oil. I top it up every 1000 km and blue smoke comes from the exhaust under acceleration.';

  @override
  String get case12Vehicle => '2007 Volkswagen Passat 1.9 TDI';

  @override
  String get case12Complaint =>
      'Hard to start on cold mornings. It makes white smoke for a few minutes and slowly loses coolant.';

  @override
  String get case13Vehicle => '2013 Renault Megane 1.5 dCi';

  @override
  String get case13Complaint =>
      'There is a whining noise from the engine area and I saw a small greenish puddle under the car this morning.';

  @override
  String get case14Vehicle => '2004 Fiat Doblo 1.9 JTD';

  @override
  String get case14Complaint =>
      'The engine has lost a lot of power. It barely climbs hills and sometimes stalls when I press the gas.';

  @override
  String get case15Vehicle => '2010 Hyundai Accent Era 1.5 CRDi';

  @override
  String get case15Complaint =>
      'It runs fine on gasoline, but on LPG it hesitates, misfires, and has noticeably less power.';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get master => 'Master';

  @override
  String get claimBonus => 'Claim Bonus!';

  @override
  String get bonusEnergy => '+1 Energy';

  @override
  String get bonusHint => '+1 Hint';

  @override
  String get watchAdButton => 'Watch';

  @override
  String get adEnergySuccess => '🎬 +1 Energy earned!';

  @override
  String get adApiFail => 'Reward API error';

  @override
  String get adLoadFail => 'Ad failed to load or was interrupted.';

  @override
  String get rewardVerifyingTitle => 'Verifying reward';

  @override
  String get rewardVerifyingBody =>
      'We are safely processing your ad reward. This can take a few seconds.';

  @override
  String get hintError => 'Hint error';

  @override
  String get splashTitle => 'AUTOFIX AI';

  @override
  String get splashSubtitle => 'The Garage Awaits You';

  @override
  String get fomoTitle => 'SECRET OFFER!';

  @override
  String get fomoBody =>
      'Only available right now! Unlimited energy and all mastery features await you. Don\'t miss this!';

  @override
  String get fomoPopupTitle => 'SECRET OFFER';

  @override
  String get fomoOffer => '1 Week Unlimited Energy\n🎁 +5 Hints Free!';

  @override
  String get fomoDiscount => '80% OFF!';

  @override
  String fomoViewers(String count) {
    return '$count people viewing this offer';
  }

  @override
  String get fomoBuy => 'GET IT BEFORE IT\'S GONE';

  @override
  String get fomoSkip => 'Skip Offer and Continue';

  @override
  String cooldownAdSuccess(String remaining) {
    return '🎬 1 Hour reduced! Remaining: $remaining';
  }

  @override
  String get googleLinked => '✅ Google account linked!';

  @override
  String get appleLinked => '✅ Apple account linked!';

  @override
  String get loginCancelled => 'Login cancelled';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get enterNewName => 'Enter new name';

  @override
  String get saveSuccess => 'Successfully updated!';

  @override
  String get mergeProfileSuccess => '✅ Device progress merged!';

  @override
  String get save => 'Save';

  @override
  String get guestDeleteDisabledInfo =>
      'Anonymous accounts cannot be deleted inside the app. To delete your data, first link a Google or Apple account from Profile; then the account deletion option will appear.';

  @override
  String get guestDeleteDisabledSnack =>
      'Anonymous accounts cannot be deleted. Link a Google or Apple account first.';

  @override
  String get profileLoadingRetry =>
      'Profile is loading. Try again when energy info is ready.';

  @override
  String get storeTitle => 'Store';

  @override
  String get storeSubtitle => 'Energy and hint packs';

  @override
  String get energyPacks => 'Energy Packs';

  @override
  String get hintPacks => 'Hint Packs';

  @override
  String get noEnergyPacks => 'Energy packs are not visible in RevenueCat yet.';

  @override
  String get noHintPacks => 'Hint packs are not visible in RevenueCat yet.';

  @override
  String get purchaseSuccess => 'Purchase successful.';

  @override
  String get purchaseFailed => 'Purchase was cancelled or failed.';

  @override
  String get serviceIntake => 'Service Intake';

  @override
  String get solved => 'Solved';

  @override
  String get solvedViewChat => 'Solved · View Chat';
}
