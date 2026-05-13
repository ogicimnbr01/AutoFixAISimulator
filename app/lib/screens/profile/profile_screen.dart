import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/revenuecat_service.dart';
import '../../core/services/admob_service.dart';
import '../settings/settings_screen.dart';
import '../paywall/paywall_screen.dart';
import '../../widgets/reward_verification_dialog.dart';

import '../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = S.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);

    return SafeArea(
      child: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
              const SizedBox(height: 12),
              Text(
                loc.profileLoadError,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(userProfileProvider.notifier).load(),
                child: Text(loc.retry),
              ),
            ],
          ),
        ),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.engineering,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        _showEditNameDialog(context, ref, profile.displayName),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.bgElevated,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                profile.rank == 'Acemi'
                    ? loc.rankNovice
                    : profile.rank == 'Çırak'
                    ? loc.rankApprentice
                    : profile.rank == 'Kalfa'
                    ? loc.rankJourneyman
                    : loc.rankMaster,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              // Account status badge
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AuthService.isLinked
                      ? AppTheme.success.withValues(alpha: 0.12)
                      : AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AuthService.isLinked
                      ? loc.accountLinked
                      : loc.accountAnonymous,
                  style: TextStyle(
                    color: AuthService.isLinked
                        ? AppTheme.success
                        : AppTheme.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Stats Grid
              Row(
                children: [
                  _StatCard(
                    icon: Icons.bolt,
                    label: loc.energy,
                    value: '${profile.energy}',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.build,
                    label: loc.repairs,
                    value: '${profile.totalRepairs}',
                    color: AppTheme.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    icon: Icons.local_fire_department,
                    label: loc.series,
                    value: '${profile.streakCount}',
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.lightbulb,
                    label: loc.hints,
                    value: '${profile.hintCredits}',
                    color: AppTheme.accent,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // --- Sign-In / Account Section ---
              if (!AuthService.isLinked) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warning.withValues(alpha: 0.08),
                        AppTheme.bgCard,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: AppTheme.warning,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.linkAccount,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.warning,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.linkAccountMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Google Sign-In Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleGoogleSignIn(context, ref),
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                          label: Text(
                            loc.signInGoogle,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      // Apple Sign-In Button (iOS only)
                      if (AuthService.showAppleSignIn) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleAppleSignIn(context, ref),
                            icon: const Icon(Icons.apple, size: 24),
                            label: Text(
                              loc.signInApple,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'By continuing, you explicitly consent to our Privacy Policy, Terms of Service, and the cross-border transfer of your data to the United States.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Menu items
              _MenuItem(
                icon: Icons.card_giftcard,
                title: loc.dailyBonus,
                subtitle: profile.loginBonusClaimed
                    ? loc.dailyBonusClaimed
                    : loc.dailyBonusReward,
                color: AppTheme.success,
                onTap: profile.loginBonusClaimed
                    ? null
                    : () async {
                        final success = await ref
                            .read(userProfileProvider.notifier)
                            .claimLoginBonus();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? loc.dailyBonusSuccess
                                    : loc.dailyBonusAlready,
                              ),
                              backgroundColor: success
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                          );
                        }
                      },
              ),
              _MenuItem(
                icon: Icons.play_circle_outline,
                title: loc.watchAd,
                subtitle: loc.watchAdReward,
                color: AppTheme.primary,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final adMobService = ref.read(adMobServiceProvider);
                  final adWatched = await adMobService.showRewardedAd(
                    rewardType: 'energy',
                  );

                  if (adWatched) {
                    final success = await showRewardVerificationDialog<bool>(
                      context: context,
                      task: () => ref
                          .read(userProfileProvider.notifier)
                          .claimAdReward('energy'),
                    );
                    if (context.mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? loc.watchAdSuccess : loc.watchAdFailed,
                          ),
                          backgroundColor: success
                              ? AppTheme.success
                              : AppTheme.danger,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(loc.watchAdFailed),
                          backgroundColor: AppTheme.warning,
                        ),
                      );
                    }
                  }
                },
              ),
              _MenuItem(
                icon: Icons.workspace_premium,
                title: loc.goPro,
                subtitle: profile.subscription == 'free'
                    ? loc.premiumFree
                    : '✅ ${profile.subscription}',
                color: AppTheme.warning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                },
              ),

              // Restore Purchases
              _MenuItem(
                icon: Icons.restore,
                title: loc.restorePurchases,
                subtitle: loc.restorePurchasesSub,
                color: AppTheme.accent,
                onTap: () async {
                  final info = await RevenueCatService.getCustomerInfo();
                  if (context.mounted) {
                    if (info != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.restoreSuccess),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                      ref.read(userProfileProvider.notifier).load();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.restoreEmpty),
                          backgroundColor: AppTheme.warning,
                        ),
                      );
                    }
                  }
                },
              ),

              _MenuItem(
                icon: Icons.settings,
                title: loc.settings,
                subtitle: loc.settingsSub,
                color: AppTheme.textSecondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),

              // Sign out (only if linked)
              if (AuthService.isLinked)
                _MenuItem(
                  icon: Icons.logout,
                  title: loc.signOut,
                  subtitle: loc.signOutSub,
                  color: AppTheme.danger,
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.bgCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(loc.signOutConfirm),
                        content: Text(loc.signOutMessage),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(loc.cancel),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.danger,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(loc.signOut),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await AuthService.signOut();
                      if (context.mounted) {
                        ref.read(userProfileProvider.notifier).load();
                      }
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleGoogleSignIn(BuildContext context, WidgetRef ref) async {
    final oldAnonymousId = AuthService.currentUid;
    final currentProfile = ref.read(userProfileProvider).value;

    int? localRank;
    try {
      final lbRes = await ref
          .read(apiClientProvider)
          .getLeaderboard('all-time');
      localRank = lbRes['userRank'];
    } catch (_) {}

    final result = await AuthService.signInWithGoogle();
    if (!context.mounted) return;

    if (result == AuthResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.signInGoogleSuccess),
          backgroundColor: AppTheme.success,
        ),
      );
      ref.read(userProfileProvider.notifier).load();
    } else if (result == AuthResult.conflict &&
        oldAnonymousId != null &&
        currentProfile != null) {
      await ref.read(userProfileProvider.notifier).load();
      final cloudProfile = ref.read(userProfileProvider).value;

      int? cloudRank;
      try {
        final lbRes = await ref
            .read(apiClientProvider)
            .getLeaderboard('all-time');
        cloudRank = lbRes['userRank'];
      } catch (_) {}

      if (cloudProfile != null && context.mounted) {
        _showConflictDialog(
          context,
          ref,
          oldAnonymousId,
          currentProfile,
          cloudProfile,
          localRank,
          cloudRank,
        );
      }
    } else if (result == AuthResult.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.signInCancelled),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }

  void _handleAppleSignIn(BuildContext context, WidgetRef ref) async {
    // Same logic applied to Apple Sign In for consistency
    final oldAnonymousId = AuthService.currentUid;
    final currentProfile = ref.read(userProfileProvider).value;

    int? localRank;
    try {
      final lbRes = await ref
          .read(apiClientProvider)
          .getLeaderboard('all-time');
      localRank = lbRes['userRank'];
    } catch (_) {}

    final result = await AuthService.signInWithApple();
    if (!context.mounted) return;

    if (result == AuthResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.signInAppleSuccess),
          backgroundColor: AppTheme.success,
        ),
      );
      ref.read(userProfileProvider.notifier).load();
    } else if (result == AuthResult.conflict &&
        oldAnonymousId != null &&
        currentProfile != null) {
      await ref.read(userProfileProvider.notifier).load();
      final cloudProfile = ref.read(userProfileProvider).value;

      int? cloudRank;
      try {
        final lbRes = await ref
            .read(apiClientProvider)
            .getLeaderboard('all-time');
        cloudRank = lbRes['userRank'];
      } catch (_) {}

      if (cloudProfile != null && context.mounted) {
        _showConflictDialog(
          context,
          ref,
          oldAnonymousId,
          currentProfile,
          cloudProfile,
          localRank,
          cloudRank,
        );
      }
    } else if (result == AuthResult.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.signInCancelled),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }

  void _showConflictDialog(
    BuildContext context,
    WidgetRef ref,
    String oldId,
    UserProfile local,
    UserProfile cloud,
    int? localRank,
    int? cloudRank,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Bulut Kaydı Bulundu!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu hesaba bağlı önceden kaydedilmiş bir ilerleme bulduk. Hangisiyle devam etmek istiyorsun?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '☁️ Buluttaki Hesap:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    'Sıralama: ${cloudRank != null ? '#$cloudRank' : 'Yok'} (Tamir: ${cloud.totalRepairs})',
                  ),
                  Text('Enerji: ${cloud.energy} | İpucu: ${cloud.hintCredits}'),
                  if (cloud.subscription == 'pro')
                    const Text(
                      'Üyelik: PRO 👑',
                      style: TextStyle(color: AppTheme.warning),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📱 Cihazdaki Hesap (Mevcut):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                  Text(
                    'Sıralama: ${localRank != null ? '#$localRank' : 'Yok'} (Tamir: ${local.totalRepairs})',
                  ),
                  Text('Enerji: ${local.energy} | İpucu: ${local.hintCredits}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Uyarı: Mevcut cihaz verinle devam edersen, sıralama ve ipuçları toplanacak, enerji yenilenecek, buluttaki pro üyeliğin varsa korunacaktır.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Zaten buluta geçtik, ekstra bir şeye gerek yok. UI güncellendi bile.
            },
            child: const Text(
              '☁️ Bulutu Koru',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await ref
                    .read(apiClientProvider)
                    .mergeProfile(oldId, local.toJson());
                if (res['success'] == true) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(S.of(context)!.mergeProfileSuccess),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                  ref.read(userProfileProvider.notifier).load();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context)!.error),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('📱 Cihazı Yaz'),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text(S.of(context)?.editProfile ?? 'Profili Düzenle'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: S.of(context)?.enterNewName ?? 'Yeni ismini gir',
            filled: true,
            fillColor: AppTheme.bgElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              S.of(context)?.cancel ?? 'İptal',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                final success = await ref
                    .read(userProfileProvider.notifier)
                    .updateDisplayName(newName);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? (S.of(context)?.saveSuccess ??
                                  'Başarıyla güncellendi!')
                            : (S.of(context)?.error ?? 'Hata oluştu!'),
                      ),
                      backgroundColor: success
                          ? AppTheme.success
                          : AppTheme.danger,
                    ),
                  );
                }
              }
            },
            child: Text(S.of(context)?.save ?? 'Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: onTap != null
                      ? AppTheme.textMuted
                      : AppTheme.textMuted.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
