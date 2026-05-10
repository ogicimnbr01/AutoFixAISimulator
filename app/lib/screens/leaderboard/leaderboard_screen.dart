import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../l10n/app_localizations.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _selectedTab = 0;
  final _periods = ['weekly', 'monthly', 'yearly'];

  @override
  Widget build(BuildContext context) {
    final _tabs = [
      S.of(context)?.weeklyTab ?? 'Haftalık',
      S.of(context)?.monthlyTab ?? 'Aylık',
      S.of(context)?.yearlyTab ?? 'Yıllık'
    ];
    final leaderboard = ref.watch(leaderboardProvider(_periods[_selectedTab]));

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: AppTheme.warning, size: 28),
                const SizedBox(width: 12),
                Text(S.of(context)?.tabLeaderboard ?? 'Sıralama Tablosu', style: Theme.of(context).textTheme.headlineLarge),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: List.generate(3, (i) {
                  final selected = _selectedTab == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: selected ? AppTheme.primaryGradient : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _tabs[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Content
          Expanded(
            child: leaderboard.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, color: AppTheme.textMuted, size: 48),
                    const SizedBox(height: 12),
                    Text(S.of(context)?.error ?? 'Sıralama yüklenemedi', style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(leaderboardProvider(_periods[_selectedTab])),
                      child: Text(S.of(context)?.retry ?? 'Tekrar Dene'),
                    ),
                  ],
                ),
              ),
              data: (rankings) {
                if (rankings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_outlined, color: AppTheme.textMuted, size: 64),
                        const SizedBox(height: 12),
                        Text(S.of(context)?.leaderboardEmpty ?? 'Henüz kimse sıralamaya girmedi', style: const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text(S.of(context)?.leaderboardBeFirst ?? 'İlk sen ol! 🔧', style: const TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                  );
                }

                final top3 = rankings.take(3).toList();
                final rest = rankings.length > 3 ? rankings.sublist(3) : <LeaderboardEntry>[];

                return Column(
                  children: [
                    // Top 3 Podium
                    if (top3.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (top3.length > 1)
                              _PodiumCard(rank: 2, name: top3[1].displayName, points: top3[1].repPoints, height: 80, color: AppTheme.textSecondary)
                            else
                              const SizedBox(width: 80),
                            _PodiumCard(rank: 1, name: top3[0].displayName, points: top3[0].repPoints, height: 110, color: AppTheme.warning),
                            if (top3.length > 2)
                              _PodiumCard(rank: 3, name: top3[2].displayName, points: top3[2].repPoints, height: 60, color: const Color(0xFFCD7F32))
                            else
                              const SizedBox(width: 80),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Rest of rankings
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: rest.length,
                        itemBuilder: (context, index) {
                          final item = rest[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '#${item.rank}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const CircleAvatar(radius: 18, backgroundColor: AppTheme.bgSurface, child: Icon(Icons.person, size: 20)),
                                const SizedBox(width: 12),
                                Expanded(child: Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.w500))),
                                Text('${item.repPoints} ⭐', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final int rank, points;
  final double height;
  final String name;
  final Color color;

  const _PodiumCard({required this.rank, required this.name, required this.points, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    final medals = ['', '🥇', '🥈', '🥉'];
    return Column(
      children: [
        Text(medals[rank], style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        Text('$points ⭐', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(child: Text('#$rank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color))),
        ),
      ],
    );
  }
}
