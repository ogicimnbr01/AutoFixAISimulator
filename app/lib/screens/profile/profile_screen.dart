import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return SafeArea(
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
              const SizedBox(height: 12),
              const Text('Profil yüklenemedi', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(userProfileProvider.notifier).load(),
                child: const Text('Tekrar Dene'),
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
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20)],
                ),
                child: const Icon(Icons.engineering, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(profile.displayName, style: Theme.of(context).textTheme.headlineMedium),
              Text(profile.rank, style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 28),

              // Stats Grid
              Row(
                children: [
                  _StatCard(icon: Icons.bolt, label: 'Enerji', value: '${profile.energy}', color: AppTheme.primary),
                  const SizedBox(width: 12),
                  _StatCard(icon: Icons.build, label: 'Tamir', value: '${profile.totalRepairs}', color: AppTheme.success),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(icon: Icons.local_fire_department, label: 'Seri', value: '${profile.streakCount}', color: AppTheme.warning),
                  const SizedBox(width: 12),
                  _StatCard(icon: Icons.lightbulb, label: 'İpucu', value: '${profile.hintCredits}', color: AppTheme.accent),
                ],
              ),
              const SizedBox(height: 28),

              // Menu items
              _MenuItem(
                icon: Icons.card_giftcard,
                title: 'Günlük Bonus Al',
                subtitle: profile.loginBonusClaimed ? 'Bugün alındı ✅' : '+1 Enerji, +1 İpucu',
                color: AppTheme.success,
                onTap: profile.loginBonusClaimed
                    ? null
                    : () async {
                        final success = await ref.read(userProfileProvider.notifier).claimLoginBonus();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(success ? '🎁 Bonus alındı! +1 Enerji, +1 İpucu' : 'Bonus zaten alınmış'),
                            backgroundColor: success ? AppTheme.success : AppTheme.warning,
                          ));
                        }
                      },
              ),
              _MenuItem(
                icon: Icons.play_circle_outline,
                title: 'Reklam İzle',
                subtitle: '+1 Enerji kazan',
                color: AppTheme.primary,
                onTap: () async {
                  final success = await ref.read(userProfileProvider.notifier).claimAdReward('energy');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(success ? '🎬 +1 Enerji kazandın!' : 'Reklam yüklenemedi'),
                      backgroundColor: success ? AppTheme.success : AppTheme.danger,
                    ));
                  }
                },
              ),
              _MenuItem(
                icon: Icons.workspace_premium,
                title: 'Premium',
                subtitle: profile.subscription == 'free' ? 'Sınırsız enerji, reklamsız' : '✅ ${profile.subscription}',
                color: AppTheme.warning,
                onTap: () {
                  // TODO: Faz 4 — Paywall ekranı
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('🚧 Yakında! Premium özellikler geliyor...'),
                  ));
                },
              ),
              _MenuItem(
                icon: Icons.settings,
                title: 'Ayarlar',
                subtitle: 'Dil, bildirimler',
                color: AppTheme.textSecondary,
                onTap: () {
                  // TODO: Ayarlar ekranı
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

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
              width: 40, height: 40,
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
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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

  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.color, this.onTap});

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
                  width: 42, height: 42,
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
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: onTap != null ? AppTheme.textMuted : AppTheme.textMuted.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
