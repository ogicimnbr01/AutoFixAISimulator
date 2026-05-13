import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/services/revenuecat_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = S.of(context)!;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final offeringsAsync = ref.watch(offeringsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(offeringsProvider);
          await ref.read(userProfileProvider.notifier).load();
        },
        color: AppTheme.primary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.local_gas_station,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.storeTitle,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      Text(
                        loc.storeSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _BalanceStrip(
              energy: profile?.energy ?? 0,
              hints: profile?.hintCredits ?? 0,
            ),
            const SizedBox(height: 20),
            offeringsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              ),
              error: (error, _) => _EmptyStore(message: '${loc.error}: $error'),
              data: (offerings) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StoreSection(
                    title: loc.energyPacks,
                    icon: Icons.bolt,
                    color: AppTheme.primary,
                    packages: offerings?.all['energy']?.availablePackages,
                    fallback: loc.noEnergyPacks,
                    onPurchased: (pkg) {
                      final amount = _amountFromProduct(pkg, 'energy_pack_');
                      if (amount > 0) {
                        ref
                            .read(userProfileProvider.notifier)
                            .addEnergyCredits(amount);
                      } else {
                        ref.read(userProfileProvider.notifier).load();
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  _StoreSection(
                    title: loc.hintPacks,
                    icon: Icons.lightbulb_outline,
                    color: AppTheme.warning,
                    packages: offerings?.all['hints']?.availablePackages,
                    fallback: loc.noHintPacks,
                    onPurchased: (pkg) {
                      final amount = _amountFromProduct(pkg, 'hint_pack_');
                      if (amount > 0) {
                        ref
                            .read(userProfileProvider.notifier)
                            .addHintCredits(amount);
                      } else {
                        ref.read(userProfileProvider.notifier).load();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceStrip extends StatelessWidget {
  final int energy;
  final int hints;

  const _BalanceStrip({required this.energy, required this.hints});

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.bgElevated),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BalanceItem(
              icon: Icons.bolt,
              label: loc.energy,
              value: '$energy',
              color: AppTheme.primary,
            ),
          ),
          Container(width: 1, height: 34, color: AppTheme.bgElevated),
          Expanded(
            child: _BalanceItem(
              icon: Icons.lightbulb_outline,
              label: loc.hints,
              value: '$hints',
              color: AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _BalanceItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _StoreSection extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Package>? packages;
  final String fallback;
  final ValueChanged<Package> onPurchased;

  const _StoreSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.packages,
    required this.fallback,
    required this.onPurchased,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = packages ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          _EmptyStore(message: fallback)
        else
          ...items.map(
            (pkg) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StorePackageCard(
                package: pkg,
                color: color,
                onPurchased: onPurchased,
              ),
            ),
          ),
      ],
    );
  }
}

class _StorePackageCard extends StatefulWidget {
  final Package package;
  final Color color;
  final ValueChanged<Package> onPurchased;

  const _StorePackageCard({
    required this.package,
    required this.color,
    required this.onPurchased,
  });

  @override
  State<_StorePackageCard> createState() => _StorePackageCardState();
}

class _StorePackageCardState extends State<_StorePackageCard> {
  bool _isBuying = false;

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;
    final product = widget.package.storeProduct;
    final amount =
        _amountFromProduct(widget.package, 'energy_pack_') +
        _amountFromProduct(widget.package, 'hint_pack_');
    final title = product.title.replaceAll(RegExp(r'\(.*\)'), '').trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.bgElevated),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: widget.color.withValues(alpha: 0.28)),
            ),
            child: Icon(
              product.identifier.contains('hint')
                  ? Icons.lightbulb
                  : Icons.bolt,
              color: widget.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? product.identifier : title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (amount > 0)
                  Text(
                    '+$amount',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isBuying
                ? null
                : () async {
                    setState(() => _isBuying = true);
                    final success = await RevenueCatService.purchasePackage(
                      widget.package,
                    );
                    if (!mounted) return;
                    setState(() => _isBuying = false);
                    if (success) {
                      widget.onPurchased(widget.package);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.purchaseSuccess),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.purchaseFailed),
                          backgroundColor: AppTheme.danger,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
            ),
            child: Text(_isBuying ? '...' : product.priceString),
          ),
        ],
      ),
    );
  }
}

class _EmptyStore extends StatelessWidget {
  final String message;

  const _EmptyStore({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.bgElevated),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
    );
  }
}

int _amountFromProduct(Package package, String prefix) {
  final prefixes = [
    prefix,
    if (prefix == 'hint_pack_') 'hints_',
    if (prefix == 'energy_pack_') 'energy_',
  ];
  final ids = [package.identifier, package.storeProduct.identifier];
  for (final id in ids) {
    for (final itemPrefix in prefixes) {
      final index = id.indexOf(itemPrefix);
      if (index >= 0) {
        final tail = id.substring(index + itemPrefix.length);
        final match = RegExp(r'^\d+').firstMatch(tail);
        if (match != null) {
          return int.tryParse(match.group(0)!) ?? 0;
        }
      }
    }
  }
  return 0;
}
