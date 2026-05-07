import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../game/game_screen.dart';

/// Scenarios data — matches backend scenarios.py
const _scenarios = [
  // Easy (1-5)
  {'id': 1, 'vehicle': '2002 Toyota Corolla 1.6', 'complaint': 'Araba hiç çalışmıyor, anahtar çevirince ses yok.', 'difficulty': 'Easy'},
  {'id': 2, 'vehicle': '2006 Ford Focus 1.6 TDCi', 'complaint': 'Anahtar çevirince tıklama sesi var ama motor dönmüyor.', 'difficulty': 'Easy'},
  {'id': 3, 'vehicle': '2008 VW Golf 1.4 TSI', 'complaint': 'Motor çalışıyor ama rölantide sallantı ve titreşim.', 'difficulty': 'Easy'},
  {'id': 4, 'vehicle': '2010 Renault Megane 1.5 dCi', 'complaint': 'Araç çalışıyor ama direksiyon çevirince gıcırtı sesi.', 'difficulty': 'Easy'},
  {'id': 5, 'vehicle': '2004 Opel Astra 1.6', 'complaint': 'Motor ısındıktan sonra stop ediyor.', 'difficulty': 'Easy'},
  // Medium (6-10)
  {'id': 6, 'vehicle': '2015 Hyundai i20 1.4', 'complaint': 'Araç sarsarak gidiyor, hızlanmada güç kaybı var.', 'difficulty': 'Medium'},
  {'id': 7, 'vehicle': '1998 Fiat Palio 1.6 LPG', 'complaint': 'Sabahları zor çalışıyor, rölantide sallanıyor.', 'difficulty': 'Medium'},
  {'id': 8, 'vehicle': '2012 Honda Civic 1.6', 'complaint': 'Fren pedalı yumuşak, durma mesafesi uzadı.', 'difficulty': 'Medium'},
  {'id': 9, 'vehicle': '2009 Peugeot 207 1.4 HDi', 'complaint': 'Egzozdan beyaz duman çıkıyor.', 'difficulty': 'Medium'},
  {'id': 10, 'vehicle': '2007 Nissan Note 1.5 dCi', 'complaint': 'Klima açınca motor neredeyse stop edecek.', 'difficulty': 'Medium'},
  // Hard (11-15)
  {'id': 11, 'vehicle': '2005 BMW 320d E46', 'complaint': 'Hızlanırken düdük sesi, güç kaybı.', 'difficulty': 'Hard'},
  {'id': 12, 'vehicle': '2011 Mercedes C200 CDI', 'complaint': 'Motor ısındığında antifriz kokusu.', 'difficulty': 'Hard'},
  {'id': 13, 'vehicle': '2003 Audi A4 1.8T', 'complaint': 'Vites geçişleri sert, 3. viteste takılma.', 'difficulty': 'Hard'},
  {'id': 14, 'vehicle': '2014 Volvo S60 D3', 'complaint': 'Stop-start çalışmıyor, akü ikaz lambası.', 'difficulty': 'Hard'},
  {'id': 15, 'vehicle': '2016 Skoda Octavia 1.6 TDI', 'complaint': 'DPF lambası yanıyor, güç kısıtlaması.', 'difficulty': 'Hard'},
];

class ScenarioSelectScreen extends StatelessWidget {
  final String difficulty;
  const ScenarioSelectScreen({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final scenarios = _scenarios.where((s) => s['difficulty'] == difficulty).toList();
    final diffColor = difficulty == 'Easy' ? AppTheme.success : difficulty == 'Medium' ? AppTheme.warning : AppTheme.danger;
    final diffLabel = difficulty == 'Easy' ? 'Kolay' : difficulty == 'Medium' ? 'Orta' : 'Zor';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text(diffLabel, style: TextStyle(color: diffColor, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            const SizedBox(width: 8),
            const Text('Vakalar', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scenarios.length,
        itemBuilder: (context, index) {
          final s = scenarios[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => GameScreen(scenarioId: s['id'] as int),
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: diffColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '#${index + 1}',
                                style: TextStyle(color: diffColor, fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${s['vehicle']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const Icon(Icons.play_circle_fill, color: AppTheme.primary, size: 32),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Text('🧑‍🔧 ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                '"${s['complaint']}"',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
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
}
