import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

/// Hint packages available for purchase
class HintPackage {
  final String id;
  final String name;
  final String emoji;
  final int amount;
  final String price;
  final String unitPrice;
  final bool isTarget;

  const HintPackage({
    required this.id,
    required this.name,
    required this.emoji,
    required this.amount,
    required this.price,
    required this.unitPrice,
    this.isTarget = false,
  });
}

const _hintPackages = [
  HintPackage(
    id: 'hint_3',
    name: 'Küçük Tamir Çantası',
    emoji: '🧰',
    amount: 3,
    price: '29.99 ₺',
    unitPrice: '~10 ₺/adet',
  ),
  HintPackage(
    id: 'hint_10',
    name: 'Usta Çantası',
    emoji: '🔧',
    amount: 10,
    price: '69.99 ₺',
    unitPrice: '~7 ₺/adet',
  ),
  HintPackage(
    id: 'hint_25',
    name: 'Patron Çantası',
    emoji: '⭐',
    amount: 25,
    price: '129.99 ₺',
    unitPrice: '~5.2 ₺/adet',
    isTarget: true,
  ),
  HintPackage(
    id: 'hint_50',
    name: 'Sınırsız Usta',
    emoji: '🔥',
    amount: 50,
    price: '199.99 ₺',
    unitPrice: '~4 ₺/adet',
  ),
];

/// Show the hint store as a bottom sheet
Future<void> showHintStoreSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _HintStoreSheet(),
  );
}

class _HintStoreSheet extends ConsumerStatefulWidget {
  const _HintStoreSheet();

  @override
  ConsumerState<_HintStoreSheet> createState() => _HintStoreSheetState();
}

class _HintStoreSheetState extends ConsumerState<_HintStoreSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  String? _selectedPackageId;

  @override
  void initState() {
    super.initState();
    _selectedPackageId = 'hint_25'; // Default to the target package
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _onPurchase(HintPackage package) {
    // In a real app, this would call RevenueCat: Purchases.purchasePackage(package)
    ref.read(userProfileProvider.notifier).addHintCredits(package.amount);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 ${package.amount} ipucu eklendi! Şimdi ustaya danış.'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final currentCredits = profile?.hintCredits ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header gradient
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.lightbulb, color: AppTheme.warning, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'İpucu Mağazası',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Danışman Ustanın bilgeliği, bir tık uzağında.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lightbulb, color: AppTheme.accent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Mevcut: $currentCredits ipucu',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Package cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: _hintPackages.map((pkg) {
                final isSelected = _selectedPackageId == pkg.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildPackageCard(pkg, isSelected),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Purchase button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final selectedPkg = _hintPackages.firstWhere(
                  (p) => p.id == _selectedPackageId,
                  orElse: () => _hintPackages[2],
                );
                return Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warning.withValues(
                          alpha: 0.3 + (_glowController.value * 0.2),
                        ),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _onPurchase(selectedPkg),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '${selectedPkg.amount} İpucu Al — ${selectedPkg.price}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Pro tip
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Pro aboneler sınırsız ipucu kullanır ✨',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildPackageCard(HintPackage pkg, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPackageId = pkg.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.warning.withValues(alpha: 0.08)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.warning : AppTheme.bgElevated,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                // Radio
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.warning : Colors.white38,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.warning,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Emoji
                Text(pkg.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pkg.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${pkg.amount} ipucu • ${pkg.unitPrice}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price
                Text(
                  pkg.price,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? AppTheme.warning : Colors.white,
                  ),
                ),
              ],
            ),

            // "EN ÇOK SATAN" tag for target package
            if (pkg.isTarget)
              Positioned(
                top: -22,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.danger.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Text(
                    'EN ÇOK SATAN ⭐',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
