import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../providers/providers.dart';
import '../../core/services/achievements_service.dart';
import 'hint_store_sheet.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int scenarioId;
  const GameScreen({super.key, required this.scenarioId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String? _sessionId;
  Map<String, dynamic>? _scenario;
  final List<Map<String, String>> _messages = [];
  int _messageCount = 0;
  int _messageLimit = 18;
  bool _isLoading = false;
  bool _solved = false;
  int _streakCount = 0;
  bool _bonusEnergy = false;
  bool _autoHintGiven = false;
  bool _isCooldown = false;
  DateTime? _cooldownEnd;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  ApiClient get _api => ref.read(apiClientProvider);

  Future<void> _startGame() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.startGame(widget.scenarioId);
      
      if (res['energy'] != null) {
        ref.read(userProfileProvider.notifier).updateEnergy(res['energy']);
      }
      
      setState(() {
        _sessionId = res['sessionId'];
        _scenario = res['scenario'];
        _messages.add({'role': 'system', 'content': '🧑‍🔧 Müşteri: "${_scenario!['complaint']}"'});
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        String errorMsg = 'Hata: $e';
        if (e.error == 'no_energy') {
          errorMsg = '⚡ Enerji bitti! Reklam izle veya bekle.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppTheme.danger),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.danger),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sessionId == null || _solved || _isLoading || _isCooldown) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final res = await _api.sendMessage(_sessionId!, text);
      setState(() {
        _messages.add({'role': 'assistant', 'content': res['response']});
        _messageCount = res['messageCount'] ?? _messageCount + 1;
        _solved = res['solved'] == true;
        if (res['streakCount'] != null) _streakCount = res['streakCount'];
        if (res['bonusEnergy'] == true) _bonusEnergy = true;
        _isLoading = false;
      });
      _scrollToBottom();

      // If solved, refresh profile to update energy/streak
      if (_solved) {
        ref.read(userProfileProvider.notifier).load();
        
        // Achievements Check
        final achService = ref.read(achievementsServiceProvider);
        if (_messageCount == 1) {
          achService.unlockSabirliUsta();
        }
        // "Çırak" ve "Usta" başarımları sunucu (backend) tabanlı sayılmalı
        // Ancak prototip için frontend'den tetiklenebilir:
        final totalRepairs = ref.read(userProfileProvider).valueOrNull?.totalRepairs ?? 0;
        if (totalRepairs + 1 >= 5) achService.unlockCirak();
        if (totalRepairs + 1 >= 50) achService.unlockUsta();
      }

      // Auto-hint at 15 messages if not solved
      if (_messageCount >= 15 && !_solved && !_autoHintGiven) {
        _autoHintGiven = true;
        _showAutoHint();
      }
    } on ApiException catch (e) {
      if (e.error == 'cooldown') {
        _startCooldown(e.message, e.statusCode == 403 ? 2 * 60 : 45); // just an estimation, we don't have exact yet unless API gives it
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _messages.add({'role': 'assistant', 'content': '⚡ Garajın şartelleri attı. Tekrar dene.'});
          _isLoading = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': '⚡ Garajın şartelleri attı. Tekrar dene.'});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _startCooldown(String message, [int minutes = 120]) {
    setState(() {
      _isCooldown = true;
      _cooldownEnd = DateTime.now().add(Duration(minutes: minutes));
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownEnd != null && DateTime.now().isAfter(_cooldownEnd!)) {
        timer.cancel();
        setState(() => _isCooldown = false);
      } else {
        setState(() {}); // Refresh timer display
      }
    });
  }

  String get _cooldownRemaining {
    if (_cooldownEnd == null) return '';
    final diff = _cooldownEnd!.difference(DateTime.now());
    if (diff.isNegative) return '00:00';
    final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showAutoHint() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.lightbulb, color: AppTheme.warning), SizedBox(width: 8), Text('İpucu Zamanı!')]),
        content: const Text('15 mesajı geçtin ama çözememedin. Ustaya danışmak ister misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hayır')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _handleHintRequest(); },
            child: const Text('İpucu Al'),
          ),
        ],
      ),
    );
  }

  /// Check hint credits before requesting — show FOMO if empty
  void _handleHintRequest() {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile == null) return;

    // Pro users have unlimited hints
    if (profile.isPro) {
      _requestHint();
      return;
    }

    // Has credits? Use one
    if (profile.hasHints) {
      _requestHint();
      return;
    }

    // No credits — show FOMO
    _showHintFomoPopup();
  }

  void _showHintFomoPopup() {
    showDialog(
      context: context,
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
            const Icon(Icons.lightbulb, color: AppTheme.warning, size: 56),
            const SizedBox(height: 16),
            const Text(
              'İpuçların Bitti!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.warning),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ustanın bilgeliğine ihtiyacın var ama ipucu hakkın kalmadı! Hemen ipucu satın al ve vakayı çöz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 3 ipucu sadece 29.99 ₺!',
                style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  showHintStoreSheet(context);
                },
                child: const Text('İPUCU MAĞAZASI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kendi Başıma Devam Et', style: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestHint() async {
    if (_sessionId == null || _solved) return;
    setState(() => _isLoading = true);
    try {
      final res = await _api.requestHint(_sessionId!);
      // Consume a hint credit (unless Pro)
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile != null && !profile.isPro) {
        ref.read(userProfileProvider.notifier).consumeHint();
      }
      setState(() {
        _messages.add({'role': 'hint', 'content': '💡 Usta: ${res['hint']}'});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İpucu hatası: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  void _showGiveUp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🏳️ Teslim Ol?'),
        content: const Text('Seri puanın kırılmaz, ama bu vaka çözülmüş sayılmaz. Devam etmek istediğine emin misin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Devam Et')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Teslim Ol'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _solved ? () => Navigator.pop(context) : _showGiveUp,
        ),
        title: Column(
          children: [
            Text(
              _scenario?['vehicle'] ?? 'Yükleniyor...',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _solved
                  ? '✅ Vaka Çözüldü!'
                  : _isCooldown
                      ? '⏰ Cooldown: $_cooldownRemaining'
                      : '$_messageCount/$_messageLimit mesaj',
              style: TextStyle(
                fontSize: 12,
                color: _solved ? AppTheme.success : _isCooldown ? AppTheme.warning : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (!_solved && !_isCooldown) ...[
            // Give up
            IconButton(
              icon: const Icon(Icons.flag_outlined, color: AppTheme.textMuted, size: 22),
              onPressed: _showGiveUp,
              tooltip: 'Teslim Ol',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: _messageCount / _messageLimit,
              backgroundColor: AppTheme.bgSurface,
              valueColor: AlwaysStoppedAnimation(_messageCount > _messageLimit - 4 ? AppTheme.danger : _messageCount > _messageLimit - 9 ? AppTheme.warning : AppTheme.primary),
            ),
          ),

          // Messages
          Expanded(
            child: _messages.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) return const _TypingIndicator();
                      return _MessageBubble(message: _messages[index]);
                    },
                  ),
          ),

          // Cooldown overlay
          if (_isCooldown)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.warning.withValues(alpha: 0.15), AppTheme.bgCard],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: const Border(top: BorderSide(color: AppTheme.bgElevated)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer, color: AppTheme.warning, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Cooldown: $_cooldownRemaining',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.warning),
                  ),
                  const SizedBox(height: 4),
                  Text('$_messageLimit mesaj limitine ulaştın', style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await ref.read(userProfileProvider.notifier).claimAdReward('cooldown', sessionId: _sessionId);
                            if (success && mounted) {
                              // We just assume 1 hour reduction for simplicity, real app would get response data.
                              // Actually claimAdReward returns bool, we should just assume it reduced it by 1 hr.
                              if (_cooldownEnd != null) {
                                final newEnd = _cooldownEnd!.subtract(const Duration(hours: 1));
                                if (newEnd.isBefore(DateTime.now())) {
                                  // cleared
                                  setState(() {
                                    _isCooldown = false;
                                    _messageLimit += 18;
                                    _cooldownTimer?.cancel();
                                  });
                                  messenger.showSnackBar(const SnackBar(
                                    content: Text('🎬 Cooldown sıfırlandı! Devam et.'),
                                    backgroundColor: AppTheme.success,
                                  ));
                                } else {
                                  setState(() {
                                    _cooldownEnd = newEnd;
                                  });
                                  messenger.showSnackBar(SnackBar(
                                    content: Text('🎬 1 Saat düştü! Kalan: $_cooldownRemaining'),
                                    backgroundColor: AppTheme.success,
                                  ));
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Reklam İzle → Devam Et'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.warning,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Garaja Dön', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                ],
              ),
            ),

          // Solved banner
          if (_solved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
              ),
              child: Column(
                children: [
                  const Text('🏆 Tamir Başarılı!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                    'Seri: $_streakCount | +1 Ün Puanı${_bonusEnergy ? ' | 🎁 +1 Bonus Enerji!' : ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.garage),
                      label: const Text('Garaja Dön'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.success),
                    ),
                  ),
                ],
              ),
            ),

          // Input bar
          if (!_solved && !_isCooldown)
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              decoration: const BoxDecoration(
                color: AppTheme.bgCard,
                border: Border(top: BorderSide(color: AppTheme.bgElevated, width: 0.5)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Animated Hint Button
                    _AnimatedHintButton(
                      hintCredits: ref.watch(userProfileProvider).valueOrNull?.hintCredits ?? 0,
                      isPro: ref.watch(userProfileProvider).valueOrNull?.isPro ?? false,
                      isLoading: _isLoading,
                      onTap: _handleHintRequest,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Kontrol et, test et, tamir et...',
                          filled: true,
                          fillColor: AppTheme.bgSurface,
                        ),
                        textInputAction: TextInputAction.send,
                        enabled: !_isLoading,
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _isLoading ? null : AppTheme.primaryGradient,
                        color: _isLoading ? AppTheme.bgSurface : null,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send_rounded, color: _isLoading ? AppTheme.textMuted : Colors.white),
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }
}

// --- Message Bubble ---
class _MessageBubble extends StatelessWidget {
  final Map<String, String> message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final role = message['role']!;
    final isUser = role == 'user';
    final isSystem = role == 'system';
    final isHint = role == 'hint';

    Color bgColor;
    Color textColor;
    if (isUser) {
      bgColor = AppTheme.primary.withValues(alpha: 0.12);
      textColor = AppTheme.primary;
    } else if (isSystem) {
      bgColor = AppTheme.warning.withValues(alpha: 0.08);
      textColor = AppTheme.textPrimary;
    } else if (isHint) {
      bgColor = AppTheme.accent.withValues(alpha: 0.08);
      textColor = AppTheme.accent;
    } else {
      bgColor = AppTheme.bgSurface;
      textColor = AppTheme.textPrimary;
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
          ),
          border: isSystem ? Border.all(color: AppTheme.warning.withValues(alpha: 0.2)) : null,
        ),
        child: Text(message['content']!, style: TextStyle(fontSize: 15, height: 1.45, color: textColor)),
      ),
    );
  }
}

// --- Typing Indicator ---
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(16)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
            SizedBox(width: 10),
            Text('İnceleniyor...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// --- Animated Hint Button ---
class _AnimatedHintButton extends StatefulWidget {
  final int hintCredits;
  final bool isPro;
  final bool isLoading;
  final VoidCallback onTap;

  const _AnimatedHintButton({
    required this.hintCredits,
    required this.isPro,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_AnimatedHintButton> createState() => _AnimatedHintButtonState();
}

class _AnimatedHintButtonState extends State<_AnimatedHintButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
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
    final hasCredits = widget.isPro || widget.hintCredits > 0;
    final badgeText = widget.isPro ? '∞' : '${widget.hintCredits}';

    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: hasCredits ? _scaleAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: hasCredits
                    ? const LinearGradient(
                        colors: [Color(0xFFFFF176), Color(0xFFFFD54F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasCredits ? null : AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: hasCredits
                    ? [
                        BoxShadow(
                          color: AppTheme.warning.withValues(alpha: _glowAnimation.value),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
                border: hasCredits
                    ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1)
                    : Border.all(color: AppTheme.bgElevated),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lightbulb icon
                  Icon(
                    Icons.lightbulb,
                    color: hasCredits ? Colors.black87 : AppTheme.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  // "Yardım" label
                  Text(
                    'Yardım',
                    style: TextStyle(
                      color: hasCredits ? Colors.black87 : AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasCredits
                          ? Colors.black.withValues(alpha: 0.2)
                          : AppTheme.danger.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: hasCredits ? Colors.black87 : AppTheme.danger,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
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
