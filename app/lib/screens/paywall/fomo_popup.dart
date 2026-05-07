import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'paywall_screen.dart';

class FOMOPopup extends StatefulWidget {
  const FOMOPopup({super.key});

  /// Displays the FOMO popup as a dialog. Returns true if dismissed.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Force them to look at it
      builder: (_) => const FOMOPopup(),
    );
  }

  @override
  State<FOMOPopup> createState() => _FOMOPopupState();
}

class _FOMOPopupState extends State<FOMOPopup> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  
  int _spotsLeft = 3;
  int _visitors = 513;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the urgent text
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // Fake Real-Time Logic (The Magic Trick)
    // Drops the available spots randomly every 2 to 4 seconds
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 3000), (timer) {
      if (!mounted) return;
      final rand = Random();
      if (rand.nextBool() && _spotsLeft > 1) {
        setState(() {
          _spotsLeft -= 1;
          _visitors += rand.nextInt(5) + 2;
        });
      }
      
      // Stop decreasing at 1 to maximize panic without closing the window
      if (_spotsLeft <= 1) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onClaim() {
    Navigator.pop(context);
    // Push to Paywall to complete the purchase
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen(isFomo: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.danger.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Urgent Icon
            ScaleTransition(
              scale: _pulseAnimation,
              child: const Icon(Icons.local_fire_department, color: AppTheme.danger, size: 64),
            ),
            const SizedBox(height: 16),
            
            // Headline
            const Text(
              'GİZLİ TEKLİF',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // The Deal
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '1 Haftalık Sınırsız Enerji\n🎁 +5 İpucu Hediye!',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.danger,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '₺249.99',
                            style: TextStyle(
                              fontSize: 20,
                              color: AppTheme.textMuted,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: const Text(
                              '₺49.99',
                              style: TextStyle(
                                fontSize: 32,
                                color: AppTheme.success,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -12,
                  right: -12,
                  child: Transform.rotate(
                    angle: 0.15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: AppTheme.success.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)
                        ],
                      ),
                      child: const Text(
                        '%80 İNDİRİM!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Social Proof & Scarcity (Fake Counter)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_alt_outlined, color: AppTheme.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$_visitors kişi teklifi inceliyor',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.bgElevated),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Kalan Paket: ', style: TextStyle(fontSize: 16, color: Colors.white70)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Text(
                      '$_spotsLeft',
                      key: ValueKey<int>(_spotsLeft),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.warning),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Call to Action
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppTheme.danger.withValues(alpha: 0.5),
                ),
                child: const Text(
                  'TÜKENMEDEN AL',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Dismiss
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Fırsatı Kaçır ve Normal Devam Et',
                style: TextStyle(color: AppTheme.textMuted, decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
