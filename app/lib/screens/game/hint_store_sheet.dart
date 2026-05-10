import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

// Instead of hardcoding everything, we use RevenueCat packages.
// We map RevenueCat package identifiers to these UI properties.
class HintStoreItem {
  final String emoji;
  final int amount;
  final String unitPriceSuffix;
  final bool isTarget;

  const HintStoreItem({
    required this.emoji,
    required this.amount,
    required this.unitPriceSuffix,
    this.isTarget = false,
  });
}

const _hintMetadata = {
  'hints_3': HintStoreItem(emoji: '🧰', amount: 3, unitPriceSuffix: '/adet'),
  'hints_10': HintStoreItem(emoji: '🔧', amount: 10, unitPriceSuffix: '/adet'),
  'hints_25': HintStoreItem(
    emoji: '⭐',
    amount: 25,
    unitPriceSuffix: '/adet',
    isTarget: true,
  ),
  'hints_50': HintStoreItem(emoji: '🔥', amount: 50, unitPriceSuffix: '/adet'),
};

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

  void _onPurchase(Package package) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.warning),
      ),
    );

    final success = await RevenueCatService.purchasePackage(package);

    if (mounted) Navigator.pop(context); // close loading

    if (success) {
      // Refresh profile to pull the new hint credits from the backend
      // (Assuming a webhook adds the hints to DynamoDB, or we do it optimistically)
      final meta = _hintMetadata[package.identifier];
      if (meta != null) {
        ref.read(userProfileProvider.notifier).addHintCredits(meta.amount);
      } else {
        await ref.read(userProfileProvider.notifier).load();
      }

      if (mounted) {
        Navigator.pop(context); // close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 İpuçları eklendi! Şimdi ustaya danış.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Satın alma başarısız veya iptal edildi.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: AppTheme.accent,
                        size: 18,
                      ),
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

          // Package cards via RevenueCat Offerings
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ref
                .watch(offeringsProvider)
                .when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.warning),
                  ),
                  error: (err, st) => Text(
                    'Hata: $err',
                    style: const TextStyle(color: AppTheme.danger),
                  ),
                  data: (offerings) {
                    final offering = offerings?.all['hints'];
                    if (offering == null ||
                        offering.availablePackages.isEmpty) {
                      return const Text(
                        'İpucu paketleri bulunamadı',
                        style: TextStyle(color: Colors.white70),
                      );
                    }

                    return Column(
                      children: offering.availablePackages.map((pkg) {
                        final isSelected = _selectedPackageId == pkg.identifier;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildPackageCard(pkg, isSelected),
                        );
                      }).toList(),
                    );
                  },
                ),
          ),
          const SizedBox(height: 16),

          // Purchase button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final offeringsAsync = ref.read(offeringsProvider).valueOrNull;
                final pkgs = offeringsAsync?.all['hints']?.availablePackages;

                Package? selectedPkg;
                if (pkgs != null && pkgs.isNotEmpty) {
                  selectedPkg = pkgs.firstWhere(
                    (p) => p.identifier == _selectedPackageId,
                    orElse: () => pkgs.first,
                  );
                }

                final btnText = selectedPkg != null
                    ? 'Satın Al — ${selectedPkg.storeProduct.localizedPriceString}'
                    : 'Paket Bekleniyor...';

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
                    onPressed: selectedPkg == null
                        ? null
                        : () => _onPurchase(selectedPkg),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      btnText,
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

  Widget _buildPackageCard(Package pkg, bool isSelected) {
    // Default metadata if ID doesn't match our predefined list
    final meta =
        _hintMetadata[pkg.identifier] ??
        HintStoreItem(emoji: '📦', amount: 1, unitPriceSuffix: '');
    final name = pkg.storeProduct.title
        .replaceAll(RegExp(r'\(.*\)'), '')
        .trim(); // Remove "(App Name)"

    return GestureDetector(
      onTap: () => setState(() => _selectedPackageId = pkg.identifier),
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
                Text(meta.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${meta.amount} ipucu',
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
                  pkg.storeProduct.localizedPriceString,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? AppTheme.warning : Colors.white,
                  ),
                ),
              ],
            ),

            // "EN ÇOK SATAN" tag for target package
            if (meta.isTarget)
              Positioned(
                top: -22,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
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
