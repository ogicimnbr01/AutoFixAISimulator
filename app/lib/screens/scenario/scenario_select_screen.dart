import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../game/game_screen.dart';

/// Scenarios data — matches backend scenarios.py
const _scenarios = [
  // Easy (1-5)
  {
    'id': 1,
    'vehicle': '2002 Japon Sedan 1.6',
    'complaint': 'Araba hiç çalışmıyor, anahtar çevirince ses yok.',
    'difficulty': 'Easy',
  },
  {
    'id': 2,
    'vehicle': '2006 Amerikan Hatchback 1.6',
    'complaint': 'Anahtar çevirince tıklama sesi var ama motor dönmüyor.',
    'difficulty': 'Easy',
  },
  {
    'id': 3,
    'vehicle': '2008 Alman Hatchback 1.4',
    'complaint': 'Sol far çalışmıyor, sağ far sorunsuz.',
    'difficulty': 'Easy',
  },
  {
    'id': 4,
    'vehicle': '2010 Fransız Sedan 1.5',
    'complaint': 'Silecekler hiç hareket etmiyor, cam suyu fışkırıyor.',
    'difficulty': 'Easy',
  },
  {
    'id': 5,
    'vehicle': '2004 Alman Hatchback 1.6',
    'complaint': 'Klima hava üflüyor ama hiç soğutmuyor.',
    'difficulty': 'Easy',
  },
  // Medium (6-10)
  {
    'id': 6,
    'vehicle': '2015 Kore Hatchback 1.4',
    'complaint': 'Motor harareti 15 dakikada kırmızıya çıkıyor.',
    'difficulty': 'Medium',
  },
  {
    'id': 7,
    'vehicle': '1998 İtalyan Hatchback 1.6',
    'complaint': 'Sabahları zor çalışıyor, rölantide sallanıyor.',
    'difficulty': 'Medium',
  },
  {
    'id': 8,
    'vehicle': '2012 Japon Sedan 1.6',
    'complaint': 'Vites geçişleri, özellikle 1-2 arası çok sert ve sarsıntılı.',
    'difficulty': 'Medium',
  },
  {
    'id': 9,
    'vehicle': '2009 Fransız Hatchback 1.4',
    'complaint':
        'Düşük hızda frene basınca ön tekerlerden tiz bir gıcırtı geliyor.',
    'difficulty': 'Medium',
  },
  {
    'id': 10,
    'vehicle': '2007 Japon Hatchback 1.5',
    'complaint':
        'Motor uyarı lambası yandı. Araç biraz hantal ve yakıtı fazla tüketiyor.',
    'difficulty': 'Medium',
  },
  // Hard (11-15)
  {
    'id': 11,
    'vehicle': '2003 BMW 320i E46',
    'complaint':
        'Motor yağ yakıyor. 1000 km’de bir yağ ekliyorum ve hızlanırken egzozdan mavi duman çıkıyor.',
    'difficulty': 'Hard',
  },
  {
    'id': 12,
    'vehicle': '2007 Volkswagen Passat 1.9 TDI',
    'complaint':
        'Soğuk sabahlarda zor çalışıyor, çalışınca birkaç dakika beyaz duman atıyor ve su eksiltiyor.',
    'difficulty': 'Hard',
  },
  {
    'id': 13,
    'vehicle': '2013 Renault Megane 1.5 dCi',
    'complaint':
        'Motor tarafından uğultu geliyor ve sabah arabanın altında yeşilimsi sıvı birikintisi gördüm.',
    'difficulty': 'Hard',
  },
  {
    'id': 14,
    'vehicle': '2004 Fiat Doblo 1.9 JTD',
    'complaint':
        'Motor çok güç kaybetti. Yokuş çıkmakta zorlanıyor, bazen gaz verince stop ediyor.',
    'difficulty': 'Hard',
  },
  {
    'id': 15,
    'vehicle': '2010 Hyundai Accent Era 1.5 CRDi',
    'complaint':
        'Benzinde sorunsuz ama LPG’de tekliyor, güçsüzleşiyor ve gaz yemiyor.',
    'difficulty': 'Hard',
  },
];

class ScenarioSelectScreen extends ConsumerStatefulWidget {
  final String difficulty;
  const ScenarioSelectScreen({super.key, required this.difficulty});

  @override
  ConsumerState<ScenarioSelectScreen> createState() =>
      _ScenarioSelectScreenState();
}

class _ScenarioSelectScreenState extends ConsumerState<ScenarioSelectScreen> {
  final Map<int, Map<String, dynamic>> _completed = {};
  bool _isLoadingCompleted = true;

  @override
  void initState() {
    super.initState();
    _loadCompleted();
  }

  Future<void> _loadCompleted() async {
    try {
      final res = await ref.read(apiClientProvider).getCompletedScenarios();
      final items = res['completedScenarios'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _completed
          ..clear()
          ..addEntries(
            items.map((item) {
              final entry = item as Map<String, dynamic>;
              return MapEntry(entry['scenarioId'] as int, entry);
            }),
          );
        _isLoadingCompleted = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCompleted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = _scenarios
        .where((s) => s['difficulty'] == widget.difficulty)
        .toList();
    final diffColor = widget.difficulty == 'Easy'
        ? AppTheme.success
        : widget.difficulty == 'Medium'
        ? AppTheme.warning
        : AppTheme.danger;
    final diffLabel = widget.difficulty == 'Easy'
        ? (S.of(context)?.difficultyEasy ?? 'Kolay')
        : widget.difficulty == 'Medium'
        ? (S.of(context)?.difficultyMedium ?? 'Orta')
        : (S.of(context)?.difficultyHard ?? 'Zor');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: diffColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                diffLabel,
                style: TextStyle(
                  color: diffColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              S.of(context)?.casesTitle ?? 'Vakalar',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scenarios.length,
        itemBuilder: (context, index) {
          final s = scenarios[index];
          final scenarioId = s['id'] as int;
          final completed = _completed[scenarioId];
          final isSolved = completed != null;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  if (isSolved) {
                    await _openArchive(scenarioId);
                    return;
                  }
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameScreen(scenarioId: scenarioId),
                    ),
                  );
                  _loadCompleted();
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Car Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/cars/scenario_${s['id']}.jpg',
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: double.infinity,
                                height: 140,
                                color: diffColor.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.directions_car,
                                  size: 64,
                                  color: diffColor.withValues(alpha: 0.5),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: diffColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  color: diffColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getLocalizedVehicle(
                                        context,
                                        s['id'] as int,
                                      ) ??
                                      '${s['vehicle']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isLoadingCompleted)
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              isSolved
                                  ? Icons.check_circle
                                  : Icons.play_circle_fill,
                              color: isSolved
                                  ? AppTheme.success
                                  : AppTheme.primary,
                              size: 36,
                            ),
                        ],
                      ),
                      if (isSolved) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.success.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fact_check_outlined,
                                color: AppTheme.success,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Çözüldü · Sohbeti Gör',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🧑‍🔧 ',
                              style: TextStyle(fontSize: 16),
                            ),
                            Expanded(
                              child: Text(
                                '"${_getLocalizedComplaint(context, s['id'] as int) ?? s['complaint']}"',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.3,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openArchive(int scenarioId) async {
    try {
      final archive = await ref
          .read(apiClientProvider)
          .getArchivedScenario(scenarioId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            scenarioId: scenarioId,
            archiveData: archive,
            readOnlyArchive: true,
          ),
        ),
      );
      ref.read(userProfileProvider.notifier).load();
      _loadCompleted();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: e.error == 'archive_limit'
              ? AppTheme.warning
              : AppTheme.danger,
        ),
      );
    }
  }

  String? _getLocalizedVehicle(BuildContext context, int id) {
    final loc = S.of(context);
    switch (id) {
      case 1:
        return loc?.case1Vehicle;
      case 2:
        return loc?.case2Vehicle;
      case 3:
        return loc?.case3Vehicle;
      case 4:
        return loc?.case4Vehicle;
      case 5:
        return loc?.case5Vehicle;
      case 6:
        return loc?.case6Vehicle;
      case 7:
        return loc?.case7Vehicle;
      case 8:
        return loc?.case8Vehicle;
      case 9:
        return loc?.case9Vehicle;
      case 10:
        return loc?.case10Vehicle;
      case 11:
        return loc?.case11Vehicle;
      case 12:
        return loc?.case12Vehicle;
      case 13:
        return loc?.case13Vehicle;
      case 14:
        return loc?.case14Vehicle;
      case 15:
        return loc?.case15Vehicle;
      default:
        return null;
    }
  }

  String? _getLocalizedComplaint(BuildContext context, int id) {
    final loc = S.of(context);
    switch (id) {
      case 1:
        return loc?.case1Complaint;
      case 2:
        return loc?.case2Complaint;
      case 3:
        return loc?.case3Complaint;
      case 4:
        return loc?.case4Complaint;
      case 5:
        return loc?.case5Complaint;
      case 6:
        return loc?.case6Complaint;
      case 7:
        return loc?.case7Complaint;
      case 8:
        return loc?.case8Complaint;
      case 9:
        return loc?.case9Complaint;
      case 10:
        return loc?.case10Complaint;
      case 11:
        return loc?.case11Complaint;
      case 12:
        return loc?.case12Complaint;
      case 13:
        return loc?.case13Complaint;
      case 14:
        return loc?.case14Complaint;
      case 15:
        return loc?.case15Complaint;
      default:
        return null;
    }
  }
}
