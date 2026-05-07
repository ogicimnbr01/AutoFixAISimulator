import 'package:games_services/games_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

final achievementsServiceProvider = Provider<AchievementsService>((ref) {
  return AchievementsService();
});

class AchievementsService {
  bool _isSignIn = false;

  /// Oyuncu Google Play / Game Center hesabına giriş yapar.
  Future<void> signIn() async {
    try {
      final result = await GamesServices.signIn();
      _isSignIn = result != null && result.toString().isNotEmpty;
      AppLogger.i('Games Services Sign-In: $_isSignIn');
    } catch (e) {
      AppLogger.e('Games Services Sign-In failed', e);
    }
  }

  /// Belirli bir başarımı açar.
  Future<void> unlockAchievement({required String androidId, required String iosId}) async {
    if (!_isSignIn) {
      await signIn();
    }
    
    if (_isSignIn) {
      try {
        await GamesServices.unlock(
          achievement: Achievement(
            androidID: androidId,
            iOSID: iosId,
          ),
        );
        AppLogger.i('Achievement unlocked: $androidId / $iosId');
      } catch (e) {
        AppLogger.e('Failed to unlock achievement', e);
      }
    }
  }

  // --- OYUN İÇİ BAŞARIMLAR ---
  
  /// "Çırak": 5 Vaka Çöz
  Future<void> unlockCirak() => unlockAchievement(
    androidId: 'CgkI_PLACEHOLDER_1', // TODO: Play Console'dan alınacak
    iosId: 'ach_cirak',
  );

  /// "Usta": 50 Vaka Çöz
  Future<void> unlockUsta() => unlockAchievement(
    androidId: 'CgkI_PLACEHOLDER_2',
    iosId: 'ach_usta',
  );

  /// "Şahin Gözlü": İpucu kullanmadan 3 vaka çöz
  Future<void> unlockSahinGozlu() => unlockAchievement(
    androidId: 'CgkI_PLACEHOLDER_3',
    iosId: 'ach_sahin_gozlu',
  );

  /// "Sabırlı Usta": 18 mesaja ulaşmadan tek tahminde sorunu bul
  Future<void> unlockSabirliUsta() => unlockAchievement(
    androidId: 'CgkI_PLACEHOLDER_4',
    iosId: 'ach_sabirli_usta',
  );
}
