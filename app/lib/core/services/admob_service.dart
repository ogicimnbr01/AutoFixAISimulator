import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';
import 'dart:io';
import 'dart:async';

final adMobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});

class AdMobService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  // Test Ad Unit ID for Rewarded Ads
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      _loadRewardedAd();
    } catch (e) {
      AppLogger.e('AdMob Init Error', e);
    }
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          AppLogger.i('Rewarded Ad Loaded.');
        },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
          _rewardedAd = null;
          AppLogger.e('Rewarded Ad Failed to Load', error);
          // Retry after a delay
          Future.delayed(const Duration(seconds: 15), _loadRewardedAd);
        },
      ),
    );
  }

  /// Shows the rewarded ad. Returns true if the user watched the ad and got the reward.
  Future<bool> showRewardedAd() async {
    if (!_isAdLoaded || _rewardedAd == null) {
      AppLogger.i('Ad not ready yet.');
      // Fallback: If ad isn't loaded, we might want to just give the reward or tell them to wait.
      // For now, we return false so the UI knows no reward was given.
      return false;
    }

    bool rewardEarned = false;

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => AppLogger.i('Ad showed fullscreen.'),
      onAdDismissedFullScreenContent: (ad) {
        AppLogger.i('Ad dismissed.');
        ad.dispose();
        _loadRewardedAd(); // Load the next ad
        if (!completer.isCompleted) completer.complete(rewardEarned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLogger.e('Ad failed to show.', error);
        ad.dispose();
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        AppLogger.i('User earned reward: ${reward.amount} ${reward.type}');
        rewardEarned = true;
      },
    );

    return completer.future;
  }
}
