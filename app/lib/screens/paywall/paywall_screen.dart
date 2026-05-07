import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import 'package:lottie/lottie.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  final bool isFomo;
  const PaywallScreen({super.key, this.isFomo = false});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selectedPackage = 'monthly';

  void _onPurchase() {
    // In a real app, this calls RevenueCat: Purchases.purchasePackage(package)
    if (widget.isFomo) {
      ref.read(userProfileProvider.notifier).markFomoPurchased();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Satın alma başarılı! Pro özellikler açıldı.'),
        backgroundColor: AppTheme.success,
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
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
                      const Text('PRO TAMİRCİ', style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(width: 48), // Balance
                    ],
                  ),
                ),
                
                // Lottie / Hero Image
                const Icon(Icons.workspace_premium, size: 100, color: AppTheme.warning),
                const SizedBox(height: 16),
                
                // Title
                const Text(
                  'Garajın Yeni Patronu Ol!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Features
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      _buildFeatureRow(Icons.bolt, 'Sınırsız Enerji (Beklemek yok)'),
                      const SizedBox(height: 8),
                      _buildFeatureRow(Icons.lightbulb, 'Her vaka için sınırsız ipucu'),
                      const SizedBox(height: 8),
                      _buildFeatureRow(Icons.block, 'Tüm Reklamları Kaldır'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // --- DECOY PRICING STRATEGY ---
                
                // 1. Weekly (The Decoy)
                _buildPackageCard(
                  id: 'weekly',
                  title: 'Haftalık Plan',
                  price: '249.99 ₺',
                  subtitle: 'Kısa süreli ustalık',
                  isSelected: _selectedPackage == 'weekly',
                ),
                const SizedBox(height: 16),
                
                // 2. Monthly (The Target)
                _buildPackageCard(
                  id: 'monthly',
                  title: 'Aylık Plan',
                  price: '399.99 ₺',
                  subtitle: 'Sadece 13 ₺ / Gün',
                  tag: 'EN ÇOK SATAN — %61 KÂR',
                  isSelected: _selectedPackage == 'monthly',
                  isTarget: true,
                ),
                const SizedBox(height: 16),
                
                // 3. Yearly (The Anchor)
                _buildPackageCard(
                  id: 'yearly',
                  title: 'Yıllık Plan',
                  price: '1999.00 ₺',
                  subtitle: 'Uzun vadeli yatırım',
                  isSelected: _selectedPackage == 'yearly',
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
                      child: const Text(
                        'ŞİMDİ YÜKSELT',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
                
                // Legal links
                const Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Terms of Use', style: TextStyle(color: Colors.white38, fontSize: 12, decoration: TextDecoration.underline)),
                      SizedBox(width: 16),
                      Text('Privacy Policy', style: TextStyle(color: Colors.white38, fontSize: 12, decoration: TextDecoration.underline)),
                      SizedBox(width: 16),
                      Text('Restore', style: TextStyle(color: Colors.white38, fontSize: 12, decoration: TextDecoration.underline)),
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
