import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';
import 'dart:io';
import 'dart:async';

final adMobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});

class AdMobService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isLoadingAd = false;
  Completer<bool>? _loadCompleter;

  // Test Ad Unit ID for Rewarded Ads
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-8589168892678914/2257454677'
      : 'ca-app-pub-3940256099942544/1712485313';

  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      unawaited(_loadRewardedAd());
    } catch (e) {
      AppLogger.e('AdMob Init Error', e);
    }
  }

  Future<bool> _loadRewardedAd() {
    if (_isAdLoaded && _rewardedAd != null) {
      return Future.value(true);
    }
    if (_isLoadingAd && _loadCompleter != null) {
      return _loadCompleter!.future;
    }

    _isLoadingAd = true;
    _loadCompleter = Completer<bool>();

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingAd = false;
          _rewardedAd = ad;
          _isAdLoaded = true;
          AppLogger.i('Rewarded Ad Loaded.');
          if (_loadCompleter?.isCompleted == false) {
            _loadCompleter!.complete(true);
          }
        },
        onAdFailedToLoad: (error) {
          _isLoadingAd = false;
          _isAdLoaded = false;
          _rewardedAd = null;
          AppLogger.e('Rewarded Ad Failed to Load', error);
          if (_loadCompleter?.isCompleted == false) {
            _loadCompleter!.complete(false);
          }
          // Retry after a delay
          Future.delayed(
            const Duration(seconds: 15),
            () => unawaited(_loadRewardedAd()),
          );
        },
      ),
    );

    return _loadCompleter!.future;
  }

  /// Shows the rewarded ad. Returns true if the user watched the ad and got the reward.
  Future<bool> showRewardedAd({
    required String rewardType,
    String? sessionId,
  }) async {
    if (!_isAdLoaded || _rewardedAd == null) {
      AppLogger.i('Ad not ready yet.');
      final loaded = await _loadRewardedAd().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      if (!loaded || _rewardedAd == null) {
        return false;
      }
    }

    bool rewardEarned = false;

    final completer = Completer<bool>();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      AppLogger.e('Cannot show rewarded ad without Firebase user.');
      return false;
    }
    final customData = [
      userId,
      rewardType,
      if (sessionId != null) sessionId,
    ].join('|');
    _rewardedAd!.setServerSideOptions(
      ServerSideVerificationOptions(userId: userId, customData: customData),
    );

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => AppLogger.i('Ad showed fullscreen.'),
      onAdDismissedFullScreenContent: (ad) {
        AppLogger.i('Ad dismissed.');
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        unawaited(_loadRewardedAd()); // Load the next ad
        if (!completer.isCompleted) completer.complete(rewardEarned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLogger.e('Ad failed to show.', error);
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        unawaited(_loadRewardedAd());
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
