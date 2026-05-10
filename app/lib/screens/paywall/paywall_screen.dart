import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import 'package:lottie/lottie.dart';
import '../../l10n/app_localizations.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  final bool isFomo;
  const PaywallScreen({super.key, this.isFomo = false});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selectedPackage = 'monthly';

  void _onPurchase() async {
    final offeringsAsync = ref.read(offeringsProvider);
    final offerings = offeringsAsync.value;
    if (offerings == null) return;

    final offering = widget.isFomo ? offerings.all['fomo'] : offerings.current;
    if (offering == null) return;

    // Map _selectedPackage to actual Package
    Package? packageToBuy;
    if (_selectedPackage == 'weekly') packageToBuy = offering.weekly;
    if (_selectedPackage == 'monthly') packageToBuy = offering.monthly;
    if (_selectedPackage == 'yearly') packageToBuy = offering.annual;

    if (packageToBuy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paket bulunamadı!'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.warning)),
    );

    final success = await RevenueCatService.purchasePackage(packageToBuy);
    
    // Hide loading
    if (mounted) Navigator.pop(context);

    if (success) {
      if (widget.isFomo) {
        ref.read(userProfileProvider.notifier).markFomoPurchased();
      } else {
        ref.read(userProfileProvider.notifier).markProPurchased();
      }
      
      // Refresh profile and customer info from backend just in case
      ref.read(userProfileProvider.notifier).load();
      ref.invalidate(customerInfoProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context)?.paywallSuccess ?? 'Satın alma başarılı! Pro özellikler açıldı.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Satın alma iptal edildi veya başarısız oldu.'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C1908), AppTheme.bgDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.4],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header & Close Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(S.of(context)?.paywallTitle ?? 'PRO TAMİRCİ', style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(width: 48), // Balance
                    ],
                  ),
                ),
                
                // Lottie / Hero Image
                const Icon(Icons.workspace_premium, size: 100, color: AppTheme.warning),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  S.of(context)?.paywallHero ?? 'Garajın Yeni Patronu Ol!',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Features
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      _buildFeatureRow(Icons.bolt, S.of(context)?.paywallFeature1 ?? 'Sınırsız Enerji (Beklemek yok)'),
                      const SizedBox(height: 8),
                      _buildFeatureRow(Icons.lightbulb, S.of(context)?.paywallFeature2 ?? 'Her vaka için sınırsız ipucu'),
                      const SizedBox(height: 8),
                      _buildFeatureRow(Icons.block, S.of(context)?.paywallFeature3 ?? 'Tüm Reklamları Kaldır'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // --- LOAD REVENUECAT PRICES ---
                ref.watch(offeringsProvider).when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: AppTheme.warning),
                    ),
                  ),
                  error: (err, st) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Fiyatlar yüklenemedi: $err', style: const TextStyle(color: AppTheme.danger)),
                  ),
                  data: (offerings) {
                    if (offerings == null) return const Text('Fiyatlar bulunamadı');
                    
                    final offering = widget.isFomo ? offerings.all['fomo'] : offerings.current;
                    if (offering == null) return const Text('Teklif bulunamadı');

                    final weekly = offering.weekly;
                    final monthly = offering.monthly;
                    final yearly = offering.annual;

                    return Column(
                      children: [
                        if (weekly != null) ...[
                          _buildPackageCard(
                            id: 'weekly',
                            title: S.of(context)?.weeklyPlan ?? 'Haftalık Plan',
                            price: weekly.storeProduct.localizedPriceString,
                            subtitle: S.of(context)?.weeklyPlanSub ?? 'Kısa süreli ustalık',
                            isSelected: _selectedPackage == 'weekly',
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        if (monthly != null) ...[
                          _buildPackageCard(
                            id: 'monthly',
                            title: S.of(context)?.monthlyPlan ?? 'Aylık Plan',
                            price: monthly.storeProduct.localizedPriceString,
                            subtitle: S.of(context)?.monthlyPlanSub ?? 'Sadece birkaç kahve parası',
                            tag: S.of(context)?.monthlyPlanTag ?? 'EN ÇOK SATAN',
                            isSelected: _selectedPackage == 'monthly',
                            isTarget: true,
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (yearly != null && !widget.isFomo) ...[
                          _buildPackageCard(
                            id: 'yearly',
                            title: S.of(context)?.yearlyPlan ?? 'Yıllık Plan',
                            price: yearly.storeProduct.localizedPriceString,
                            subtitle: S.of(context)?.yearlyPlanSub ?? 'Uzun vadeli yatırım',
                            isSelected: _selectedPackage == 'yearly',
                          ),
                        ],
                      ],
                    );
                  },
                ),
                
                const Spacer(),
                
                // Purchase Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _onPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warning,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                      ),
                      child: Text(
                        S.of(context)?.upgradeNow ?? 'ŞİMDİ YÜKSELT',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
                
                // Legal links
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(S.of(context)?.termsOfUse ?? 'Terms of Use', style: const TextStyle(color: Colors.white38, fontSize: 12, decoration: TextDecoration.underline)),
                      const SizedBox(width: 16),
                      Text(S.of(context)?.privacyPolicy ?? 'Privacy Policy', style: const TextStyle(color: Colors.white38, fontSize: 12, decoration: TextDecoration.underline)),
                      const SizedBox(width: 16),
                      Text(S.of(context)?.restore ?? 'Restore', style: const TextStyle(color: Colors.white38, fontSize: 12, decoration: TextDecoration.underline)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.warning, size: 24),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ],
    );
  }

  Widget _buildPackageCard({
    required String id,
    required String title,
    required String price,
    required String subtitle,
    String? tag,
    bool isSelected = false,
    bool isTarget = false,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPackage = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.warning.withValues(alpha: 0.1) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.warning : AppTheme.bgElevated,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  // Radio button
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? AppTheme.warning : Colors.white38, width: 2),
                    ),
                    child: isSelected
                        ? Center(child: Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.warning)))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white70)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                      ],
                    ),
                  ),
                  
                  // Price
                  Text(price, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isSelected ? AppTheme.warning : Colors.white)),
                ],
              ),
            ),
            
            // Tag (For the monthly package)
            if (tag != null)
              Positioned(
                top: -12,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: AppTheme.danger.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1),
                    ],
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
