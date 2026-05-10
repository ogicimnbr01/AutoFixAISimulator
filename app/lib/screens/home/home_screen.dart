import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../paywall/paywall_screen.dart';
import '../paywall/fomo_popup.dart';
import '../scenario/scenario_select_screen.dart';
import '../../core/services/admob_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime? _fomoOfferEndTime;
  int _randomTipIndex = 0;

  @override
  void initState() {
    super.initState();
    _randomTipIndex = math.Random().nextInt(6);
    // Occasional Special Offer Popup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOccasionalOffer();
    });
  }

  void _checkOccasionalOffer() {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile == null || profile.subscription == 'pro' || profile.fomoPurchased) return;
    
    // No FOMO during honeymoon phase (Day 1-3)
    if (profile.isHoneymoon) return;

    // 30% chance to show a limited time offer
    if (math.Random().nextDouble() < 0.3) {
      if (!mounted) return;
      _showSpecialOffer(context);
    }
  }

  void _showSpecialOffer(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.warning, width: 2),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, color: AppTheme.warning, size: 64),
            const SizedBox(height: 16),
            Text(
              S.of(context)?.fomoTitle ?? 'GİZLİ TEKLİF!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.warning,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              S.of(context)?.fomoBody ?? 'Sadece şu an için geçerli! Sınırsız enerji ve tüm ustalık özellikleri seni bekliyor. Bu fırsatı kaçırma!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
              },
              child: Text(S.of(context)?.upgradeNow ?? 'FIRSATI YAKALA', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(S.of(context)?.cancel ?? 'Belki Sonra', style: const TextStyle(color: AppTheme.textMuted)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final loc = S.of(context);
    final showFomoBanner = _fomoOfferEndTime != null && DateTime.now().isBefore(_fomoOfferEndTime!);

    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text('🔧', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AutoFix AI', style: Theme.of(context).textTheme.headlineLarge),
                      Text(loc?.tabGarage ?? 'Garaj seni bekliyor, usta.', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                // Daily bonus button
                profileAsync.whenOrNull(
                  data: (profile) => Row(
                    children: [
                      // Animated PRO Button
                      if (profile.subscription != 'pro')
                        const _AnimatedProButton(),
                      
                      if (profile.subscription != 'pro')
                        const SizedBox(width: 8),

                      // Daily Bonus Button
                      GestureDetector(
                        onTap: profile.loginBonusClaimed ? null : () => _showDailyBonus(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: profile.loginBonusClaimed
                                ? AppTheme.bgSurface
                                : AppTheme.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: profile.loginBonusClaimed
                                  ? AppTheme.bgElevated
                                  : AppTheme.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            profile.loginBonusClaimed ? Icons.check_circle : Icons.card_giftcard,
                            color: profile.loginBonusClaimed ? AppTheme.textMuted : AppTheme.success,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ) ?? const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 24),

            // Energy Card
            profileAsync.when(
              loading: () => _buildEnergyCardShimmer(),
              error: (e, _) => _buildEnergyCardError(),
              data: (profile) => _buildEnergyCard(context, profile),
            ),
            const SizedBox(height: 12),

            // Transition Warning Banner (Day 4-7)
            profileAsync.whenOrNull(
              data: (profile) => profile.isTransition && !profile.isPro
                  ? _buildTransitionBanner(profile)
                  : null,
            ) ?? const SizedBox.shrink(),

            const SizedBox(height: 28),

            // Section Title
            Text(loc?.tabGarage ?? 'Yeni Vaka Seç', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 14),

            // Difficulty Cards
            _DifficultyCard(
              title: loc?.difficultyEasy ?? 'Kolay',
              subtitle: loc?.difficultyEasySub ?? 'Akü, marş motoru, bujiler',
              icon: Icons.speed,
              color: AppTheme.success,
              scenarios: loc?.casesCount ?? '5 vaka',
              onTap: () => _handleGameStart('Easy'),
            ),
            const SizedBox(height: 12),
            _DifficultyCard(
              title: loc?.difficultyMedium ?? 'Orta',
              subtitle: loc?.difficultyMediumSub ?? 'LPG, yakıt pompası, sensörler',
              icon: Icons.trending_up,
              color: AppTheme.warning,
              scenarios: loc?.casesCount ?? '5 vaka',
              onTap: () => _handleGameStart('Medium'),
            ),
            const SizedBox(height: 12),
            _DifficultyCard(
              title: loc?.difficultyHard ?? 'Zor',
              subtitle: loc?.difficultyHardSub ?? 'Conta, turbo, şanzıman',
              icon: Icons.whatshot,
              color: AppTheme.danger,
              scenarios: loc?.casesCount ?? '5 vaka',
              onTap: () => _handleGameStart('Hard'),
            ),
            const SizedBox(height: 28),

            // Streak Bar
            profileAsync.whenOrNull(
              data: (profile) => _buildStreakBar(context, profile),
            ) ?? _buildStreakBarShimmer(),
            const SizedBox(height: 16),

            // Tips card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates, color: AppTheme.accent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      [
                        S.of(context)?.tip1,
                        S.of(context)?.tip2,
                        S.of(context)?.tip3,
                        S.of(context)?.tip4,
                        S.of(context)?.tip5,
                        S.of(context)?.tip6
                      ][_randomTipIndex] ?? '',
                      style: const TextStyle(fontSize: 13, color: AppTheme.accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ), // closes SingleChildScrollView
      ), // closes SafeArea
      
      if (showFomoBanner)
        Positioned(
          bottom: 20,
          right: 20,
          child: _FomoFloatingBanner(
            endTime: _fomoOfferEndTime!,
            onTimeout: () => setState(() => _fomoOfferEndTime = null),
          ),
        ),
    ]);
  }

  void _handleGameStart(String difficulty) async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null && profile.energy <= 0) {
      final isOfferActive = _fomoOfferEndTime != null && DateTime.now().isBefore(_fomoOfferEndTime!);
      
      // No FOMO popup during honeymoon — just a friendly message
      if (profile.isHoneymoon) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enerjin bitti! Yarın yeni enerjin hazır olacak. 🔧'),
            backgroundColor: AppTheme.warning,
          ),
        );
      } else if (!profile.fomoPurchased && !isOfferActive) {
        final dismissed = await FOMOPopup.show(context);
        if (dismissed == true) {
          setState(() {
            _fomoOfferEndTime = DateTime.now().add(const Duration(minutes: 2));
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOfferActive ? 'Enerjin bitti! Sağ alttaki teklifi kaçırma!' : 'Enerji bitti! Reklam izle veya bekle.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ScenarioSelectScreen(difficulty: difficulty),
    ));
  }

  Widget _buildEnergyCard(BuildContext context, UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${profile.energy} ${S.of(context)?.energy ?? 'Enerji'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(
                  profile.energy > 0
                      ? (S.of(context)?.backToGarage ?? 'Garaja gir ve tamir et!')
                      : (S.of(context)?.noEnergy ?? 'Enerji bitti — reklam izle veya bekle'),
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Watch ad button
          GestureDetector(
            onTap: () => _showAdReward(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text('+1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyCardShimmer() {
    return Container(
      width: double.infinity,
      height: 90,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),
    );
  }

  Widget _buildEnergyCardError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 32),
          const SizedBox(width: 12),
          Expanded(child: Text(S.of(context)?.error ?? 'Bağlantı kurulamadı', style: const TextStyle(color: AppTheme.danger))),
          TextButton(
            onPressed: () => ref.read(userProfileProvider.notifier).load(),
            child: Text(S.of(context)?.retry ?? 'Tekrar Dene', style: const TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBar(BuildContext context, UserProfile profile) {
    final streakProgress = (profile.streakCount % 3) / 3;
    final streakMod = profile.streakCount % 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bgElevated),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: AppTheme.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context)?.streakProgress(streakMod, 3) ?? 'Seri: $streakMod/3', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: streakProgress,
                    minHeight: 6,
                    backgroundColor: AppTheme.bgSurface,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(S.of(context)?.bonusEnergyShort ?? '🎁 +1 Enerji', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBarShimmer() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildTransitionBanner(UserProfile profile) {
    // Calculate yesterday's and tomorrow's energy for the message
    final currentMax = profile.maxEnergy;
    final previousMax = profile.daysSinceInstall <= 3 ? 5 : 4;
    final nextMax = profile.daysSinceInstall >= 5 ? 3 : currentMax;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.warning.withValues(alpha: 0.12), AppTheme.warning.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_down, color: AppTheme.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dün $previousMax enerjin vardı, şu an $currentMax${nextMax < currentMax ? ', yarın $nextMax olacak' : ''}.',
                  style: const TextStyle(color: AppTheme.warning, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Pro\'ya geçersen sınırsız kalır ✨',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDailyBonus(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.bgElevated, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('🎁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(S.of(context)?.dailyBonus ?? 'Günlük Bonus', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(S.of(context)?.dailyBonusReward ?? 'Her gün giriş yap, bonus kazan!', style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BonusItem(icon: Icons.bolt, label: S.of(context)?.bonusEnergy ?? '+1 Enerji', color: AppTheme.primary),
                const SizedBox(width: 20),
                _BonusItem(icon: Icons.lightbulb, label: S.of(context)?.bonusHint ?? '+1 İpucu', color: AppTheme.accent),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  final success = await ref.read(userProfileProvider.notifier).claimLoginBonus();
                  messenger.showSnackBar(SnackBar(
                    content: Text(success ? (S.of(context)?.dailyBonusSuccess ?? '🎁 Bonus alındı!') : (S.of(context)?.dailyBonusAlready ?? 'Bonus zaten alınmış')),
                    backgroundColor: success ? AppTheme.success : AppTheme.warning,
                  ));
                },
                child: Text(S.of(context)?.claimBonus ?? 'Bonus Al!'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAdReward(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('🎬 ${S.of(context)?.watchAd ?? 'Reklam İzle'}'),
        content: Text(S.of(context)?.watchAdReward ?? '30 saniyelik reklam izle, +1 enerji kazan!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(context)?.cancel ?? 'İptal')),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              
              // 1. Show AdMob Ad
              final adMobService = ref.read(adMobServiceProvider);
              final adWatched = await adMobService.showRewardedAd();
              
              if (adWatched) {
                // 2. Grant Reward
                final success = await ref.read(userProfileProvider.notifier).claimAdReward('energy');
                messenger.showSnackBar(SnackBar(
                  content: Text(success ? (S.of(context)?.adEnergySuccess ?? '🎬 +1 Enerji kazandın!') : (S.of(context)?.adApiFail ?? 'Ödül API hatası')),
                  backgroundColor: success ? AppTheme.success : AppTheme.danger,
                ));
              } else {
                messenger.showSnackBar(SnackBar(
                  content: Text(S.of(context)?.adLoadFail ?? 'Reklam yüklenemedi veya yarıda kesildi.'),
                  backgroundColor: AppTheme.danger,
                ));
              }
            },
            child: Text(S.of(context)?.watchAdButton ?? 'İzle'),
          ),
        ],
      ),
    );
  }
}

class _BonusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _BonusItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final String title, subtitle, scenarios;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.title, required this.subtitle, required this.icon,
    required this.color, required this.scenarios, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(8)),
                child: Text(scenarios, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedProButton extends StatefulWidget {
  const _AnimatedProButton();

  @override
  State<_AnimatedProButton> createState() => _AnimatedProButtonState();
}

class _AnimatedProButtonState extends State<_AnimatedProButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen())),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: _glowAnimation.value),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, color: Colors.black87, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FomoFloatingBanner extends StatefulWidget {
  final DateTime endTime;
  final VoidCallback onTimeout;
  const _FomoFloatingBanner({required this.endTime, required this.onTimeout});

  @override
  State<_FomoFloatingBanner> createState() => _FomoFloatingBannerState();
}

class _FomoFloatingBannerState extends State<_FomoFloatingBanner> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (DateTime.now().isAfter(widget.endTime)) {
        timer.cancel();
        widget.onTimeout();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.endTime.difference(DateTime.now());
    if (remaining.isNegative) return const SizedBox.shrink();
    
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen(isFomo: true))),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_anim.value * 0.05),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.danger, Color(0xFFD32F2F)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppTheme.danger.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)
                ],
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('TEKLİFİ KAÇIRMA!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                      Text('$minutes:$seconds', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
