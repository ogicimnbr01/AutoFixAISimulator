import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../providers/providers.dart';
import '../../core/services/achievements_service.dart';
import '../../l10n/app_localizations.dart';
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
  String? _masteryFeedback;
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
        final complaint =
            _getLocalizedComplaint(context, widget.scenarioId) ??
            _scenario!['complaint'];
        _messages.add({
          'role': 'system',
          'content':
              S.of(context)?.customerComplaint(complaint) ??
              '🧑‍🔧 Müşteri: "$complaint"',
        });
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        String errorMsg = '${S.of(context)?.error ?? 'Hata'}: $e';
        if (e.error == 'no_energy') {
          errorMsg =
              S.of(context)?.noEnergy ??
              '⚡ Enerji bitti! Reklam izle veya bekle.';
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
          SnackBar(
            content: Text('${S.of(context)?.error ?? 'Hata'}: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty ||
        _sessionId == null ||
        _solved ||
        _isLoading ||
        _isCooldown)
      return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final lang = Localizations.localeOf(context).languageCode;
      final res = await _api.sendMessage(_sessionId!, text, lang: lang);
      setState(() {
        _messages.add({'role': 'assistant', 'content': res['response']});
        _messageCount = res['messageCount'] ?? _messageCount + 1;
        _solved = res['solved'] == true;
        if (res['streakCount'] != null) _streakCount = res['streakCount'];
        if (res['bonusEnergy'] == true) _bonusEnergy = true;
        if (res['masteryFeedback'] is String &&
            (res['masteryFeedback'] as String).trim().isNotEmpty) {
          _masteryFeedback = (res['masteryFeedback'] as String).trim();
        }
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
        final totalRepairs =
            ref.read(userProfileProvider).valueOrNull?.totalRepairs ?? 0;
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
        _startCooldown(
          e.message,
          e.statusCode == 403 ? 2 * 60 : 45,
        ); // just an estimation, we don't have exact yet unless API gives it
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content':
                S.of(context)?.fallbackError ??
                '⚡ Garajın şartelleri attı. Tekrar dene.',
          });
          _isLoading = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              S.of(context)?.fallbackError ??
              '⚡ Garajın şartelleri attı. Tekrar dene.',
        });
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
        title: Row(
          children: [
            const Icon(Icons.lightbulb, color: AppTheme.warning),
            const SizedBox(width: 8),
            Text(S.of(context)?.hintTimeTitle ?? 'İpucu Zamanı!'),
          ],
        ),
        content: Text(
          S.of(context)?.hintTimeMessage ??
              '15 mesajı geçtin ama çözememedin. Ustaya danışmak ister misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context)?.no ?? 'Hayır'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleHintRequest();
            },
            child: Text(S.of(context)?.getHint ?? 'İpucu Al'),
          ),
        ],
      ),
    );
  }

  /// Check hint credits before requesting — show FOMO if empty
  void _handleHintRequest() {
    if (_isLoading) return; // Prevent double-taps
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
            Text(
              S.of(context)?.hintsEmpty ?? 'İpuçların Bitti!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.warning,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              S.of(context)?.hintsEmptyMessage ??
                  'Ustanın bilgeliğine ihtiyacın var ama ipucu hakkın kalmadı! Hemen ipucu satın al ve vakayı çöz.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                S.of(context)?.hintsPromo ?? '💡 3 ipucu sadece 29.99 ₺!',
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  showHintStoreSheet(context);
                },
                child: Text(
                  S.of(context)?.hintStore ?? 'İPUCU MAĞAZASI',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                S.of(context)?.continueAlone ?? 'Kendi Başıma Devam Et',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
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
      final lang = Localizations.localeOf(context).languageCode;
      final res = await _api.requestHint(_sessionId!, lang: lang);
      // Consume a hint credit (unless Pro)
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (profile != null && !profile.isPro) {
        ref.read(userProfileProvider.notifier).consumeHint();
      }
      setState(() {
        _messages.add({
          'role': 'hint',
          'content': '💡 ${S.of(context)?.master ?? 'Usta'}: ${res['hint']}',
        });
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.of(context)?.hintError ?? 'İpucu hatası'}: $e'),
            backgroundColor: AppTheme.danger,
          ),
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
        title: Text(S.of(context)?.giveUpTitle ?? '🏳️ Teslim Ol?'),
        content: Text(
          S.of(context)?.giveUpMessage ??
              'Seri puanın kırılmaz, ama bu vaka çözülmüş sayılmaz. Devam etmek istediğine emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context)?.continueButton ?? 'Devam Et'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(S.of(context)?.giveUpButton ?? 'Teslim Ol'),
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

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(S.of(context)?.reportTitle ?? '🚨 Şikayet Et'),
        content: Text(
          S.of(context)?.reportMessage ??
              'AI tarafından üretilen rahatsız edici veya uygunsuz bir mesajı rapor etmek üzeresiniz. Bu oturum incelenmek üzere kaydedilecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context)?.cancel ?? 'İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);

              if (_sessionId != null && _messages.isNotEmpty) {
                // Find last assistant message
                final lastAiMessage = _messages.lastWhere(
                  (m) => m['role'] == 'assistant' || m['role'] == 'hint',
                  orElse: () => {'content': 'No AI message found'},
                );

                try {
                  await _api.reportMessage(
                    _sessionId!,
                    lastAiMessage['content']!,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          S.of(context)?.reportSuccess ??
                              'Şikayetiniz alınmıştır. İncelenecektir.',
                        ),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          S.of(context)?.reportFailed ??
                              'Şikayet gönderilemedi.',
                        ),
                        backgroundColor: AppTheme.danger,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(S.of(context)?.send ?? 'Gönder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDynamicMastery = _masteryFeedback != null;
    final masteryNote =
        _masteryFeedback ?? _getMasteryNote(context, widget.scenarioId);
    final masteryTitle = hasDynamicMastery
        ? _getCoachTitle(context)
        : _getMasteryTitle(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _solved ? () => Navigator.pop(context) : _showGiveUp,
        ),
        title: Column(
          children: [
            Text(
              _getLocalizedVehicle(context, widget.scenarioId) ??
                  _scenario?['vehicle'] ??
                  (S.of(context)?.loading ?? 'Yükleniyor...'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _solved
                  ? (S.of(context)?.caseSolved ?? '✅ Vaka Çözüldü!')
                  : _isCooldown
                  ? (S.of(context)?.cooldownLabel(_cooldownRemaining) ??
                        '⏰ Cooldown: $_cooldownRemaining')
                  : (S
                            .of(context)
                            ?.messageCount(_messageCount, _messageLimit) ??
                        '$_messageCount/$_messageLimit mesaj'),
              style: TextStyle(
                fontSize: 12,
                color: _solved
                    ? AppTheme.success
                    : _isCooldown
                    ? AppTheme.warning
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.report_problem_outlined,
              color: AppTheme.textMuted,
              size: 22,
            ),
            onPressed: _showReportDialog,
            tooltip: S.of(context)?.reportTitle ?? 'Şikayet Et',
          ),
          if (!_solved && !_isCooldown) ...[
            // Give up
            IconButton(
              icon: const Icon(
                Icons.flag_outlined,
                color: AppTheme.textMuted,
                size: 22,
              ),
              onPressed: _showGiveUp,
              tooltip: S.of(context)?.giveUpButton ?? 'Teslim Ol',
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
              valueColor: AlwaysStoppedAnimation(
                _messageCount > _messageLimit - 4
                    ? AppTheme.danger
                    : _messageCount > _messageLimit - 9
                    ? AppTheme.warning
                    : AppTheme.primary,
              ),
            ),
          ),

          // Messages
          Expanded(
            child: _messages.isEmpty && _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading)
                        return const _TypingIndicator();
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
                  colors: [
                    AppTheme.warning.withValues(alpha: 0.15),
                    AppTheme.bgCard,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: const Border(
                  top: BorderSide(color: AppTheme.bgElevated),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer, color: AppTheme.warning, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Cooldown: $_cooldownRemaining',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.warning,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.of(context)?.cooldownMessage(_messageLimit) ??
                        '$_messageLimit mesaj limitine ulaştın',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await ref
                                .read(userProfileProvider.notifier)
                                .claimAdReward(
                                  'cooldown',
                                  sessionId: _sessionId,
                                );
                            if (success && mounted) {
                              // We just assume 1 hour reduction for simplicity, real app would get response data.
                              // Actually claimAdReward returns bool, we should just assume it reduced it by 1 hr.
                              if (_cooldownEnd != null) {
                                final newEnd = _cooldownEnd!.subtract(
                                  const Duration(hours: 1),
                                );
                                if (newEnd.isBefore(DateTime.now())) {
                                  // cleared
                                  setState(() {
                                    _isCooldown = false;
                                    _messageLimit += 18;
                                    _cooldownTimer?.cancel();
                                  });
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        S.of(context)?.cooldownCleared ??
                                            '🎬 Cooldown sıfırlandı! Devam et.',
                                      ),
                                      backgroundColor: AppTheme.success,
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    _cooldownEnd = newEnd;
                                  });
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        S
                                                .of(context)
                                                ?.cooldownAdSuccess(
                                                  _cooldownRemaining,
                                                ) ??
                                            '🎬 1 Saat düştü! Kalan: $_cooldownRemaining',
                                      ),
                                      backgroundColor: AppTheme.success,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.play_circle_outline),
                          label: Text(
                            S.of(context)?.watchAdContinue ??
                                'Reklam İzle → Devam Et',
                          ),
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
                    child: Text(
                      S.of(context)?.backToGarage ?? 'Garaja Dön',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
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
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    S.of(context)?.repairSuccess ?? '🏆 Tamir Başarılı!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${S.of(context)?.seriesInfo(_streakCount) ?? 'Seri: $_streakCount | +1 Ün Puanı'}${_bonusEnergy ? (S.of(context)?.bonusEnergyTag ?? ' | 🎁 +1 Bonus Enerji!') : ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (masteryNote != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  masteryTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  masteryNote,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.garage),
                      label: Text(S.of(context)?.backToGarage ?? 'Garaja Dön'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.success,
                      ),
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
                border: Border(
                  top: BorderSide(color: AppTheme.bgElevated, width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Animated Hint Button
                    _AnimatedHintButton(
                      hintCredits:
                          ref
                              .watch(userProfileProvider)
                              .valueOrNull
                              ?.hintCredits ??
                          0,
                      isPro:
                          ref.watch(userProfileProvider).valueOrNull?.isPro ??
                          false,
                      isLoading: _isLoading,
                      onTap: _handleHintRequest,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText:
                              S.of(context)?.chatPlaceholder ??
                              'Kontrol et, test et, tamir et...',
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
                        icon: Icon(
                          Icons.send_rounded,
                          color: _isLoading ? AppTheme.textMuted : Colors.white,
                        ),
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
      bgColor = AppTheme.primary.withValues(alpha: 0.15);
      textColor = AppTheme.primary;
    } else if (isSystem) {
      bgColor = AppTheme.warning.withValues(alpha: 0.1);
      textColor = AppTheme.textPrimary;
    } else if (isHint) {
      bgColor = AppTheme.accent.withValues(alpha: 0.12);
      textColor = AppTheme.accent;
    } else {
      // AI / Master message
      bgColor = AppTheme.bgSurface.withValues(alpha: 0.6);
      textColor = AppTheme.textPrimary;
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser
                ? const Radius.circular(20)
                : const Radius.circular(6),
            bottomRight: isUser
                ? const Radius.circular(6)
                : const Radius.circular(20),
          ),
          border: isSystem
              ? Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Text(
          message['content']!,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: textColor,
            fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
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
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              S.of(context)?.analyzing ?? 'İnceleniyor...',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
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

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
                          color: AppTheme.warning.withValues(
                            alpha: _glowAnimation.value,
                          ),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
                border: hasCredits
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 1,
                      )
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
                    S.of(context)?.helpButton ?? 'Yardım',
                    style: TextStyle(
                      color: hasCredits ? Colors.black87 : AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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

String _getMasteryTitle(BuildContext context) {
  final lang = Localizations.localeOf(context).languageCode;
  if (lang == 'tr') return 'Ustalık Notu';
  if (lang == 'ru') return 'Заметка мастера';
  if (lang == 'zh') return '技师笔记';
  return 'Mastery Note';
}

String _getCoachTitle(BuildContext context) {
  final lang = Localizations.localeOf(context).languageCode;
  if (lang == 'tr') return 'Usta Yorumu';
  if (lang == 'ru') return 'Оценка мастера';
  if (lang == 'zh') return '师傅点评';
  return 'Master Review';
}

String? _getMasteryNote(BuildContext context, int id) {
  final lang = Localizations.localeOf(context).languageCode;

  const notes = {
    'tr': {
      1: '9.2V akü voltajı çok düşüktür. Takviye ile çalışması, marş motorundan önce akünün şüpheli olduğunu gösterir.',
      2: 'Akü güçlü kalırken hızlı tıklama duyuluyorsa güç var ama marş motoru dönemiyordur. Marşa vurunca çalışması bu teşhisi güçlendirir.',
      3: 'Ampul sağlam ve sağ far çalışıyorsa arıza devrenin besleme tarafındadır. Sigorta kontrolü küçük ama kritik bir testtir.',
      4: 'Silecek motoruna 12V geliyor ama motor ses vermiyorsa anahtar ve sigortadan çok motorun kendisi suçludur.',
      5: 'Klima basıncı neredeyse sıfırsa sistem boşalmıştır. Kompresörü değiştirmeden önce kaçak bulup gazı tamamlamak gerekir.',
      6: 'Üst hortum sıcak, alt hortum soğuksa soğutma sıvısı radyatörden dolaşmıyordur. Kapalı kalan termostat bu tabloyu açıklar.',
      7: 'Tek silindirde ıslak ve kurumlu buji, ateşlemenin o silindirde kaçırdığını gösterir. Kompresyon sağlamsa buji iyi ilk hamledir.',
      8: 'Sert vites geçişiyle koyu ve yanık kokulu ATF birleşince sorun genelde elektronik değil bakım ihmalidir.',
      9: 'Frene basınca gelen metalik tiz ses ve 1 mm balata, aşınma ikazının diske sürttüğünü gösterir.',
      10: 'P0136 ve sabit 0.45V okuyan downstream O2 sensörü, katalizörden önce sensör devresini şüpheli yapar.',
      11: 'Islak kompresyon testinde değer yükseliyorsa yağ geçici sızdırmazlık sağlar. Bu, segman aşınmasına güçlü kanıttır.',
      12: 'Beyaz tatlı duman, su eksiltme ve blok testinde renk değişimi birlikte conta kaçağını işaret eder.',
      13: 'Yeşil sıvı, pompa çevresinden kaçak ve rulman uğultusu birleşince su pompası hem sızdırıyor hem de mekanik aşınıyordur.',
      14: 'P0016 kodu ve kaçmış zamanlama işaretleri, güç kaybının turbo değil sente problemi olduğunu gösterir.',
      15: 'Benzinde sorunsuz, LPG’de tekleme varsa temel motor sağlıklıdır. Harita kalibrasyonu LPG tarafındaki davranışı açıklar.',
    },
    'en': {
      1: 'A 9.2V battery reading is far too low. If a jump start works, suspect the battery before the starter motor.',
      2: 'Bright lights plus rapid clicking means power is present, but the starter is not turning. Tapping it and then starting confirms the clue.',
      3: 'If the bulb is intact and the right headlight works, the fault is likely in the supply path. A fuse check is small but decisive.',
      4: 'When 12V reaches the wiper motor but it stays silent, the switch and fuse are less suspicious than the motor itself.',
      5: 'Near-zero AC pressure means the system is empty. Find the leak and recharge before blaming the compressor.',
      6: 'A hot upper hose and cold lower hose means coolant is not circulating through the radiator. A stuck thermostat fits that pattern.',
      7: 'One wet, carbon-fouled spark plug points to a missed ignition event on that cylinder. Good compression makes the plug the right first fix.',
      8: 'Harsh shifts plus dark, burnt-smelling ATF usually points to neglected fluid service rather than electronics.',
      9: 'A metallic squeal under braking and a 1 mm pad means the wear indicator is touching the disc.',
      10: 'Code P0136 and a downstream O2 sensor stuck at 0.45V make the sensor circuit more likely than the catalytic converter.',
      11: 'If wet compression raises the reading, oil briefly seals the leak. That is strong evidence for worn piston rings.',
      12: 'Sweet white smoke, coolant loss, and a positive block test together point to a head gasket leak.',
      13: 'Green coolant, a leak near the pump, and bearing whine mean the water pump is leaking and mechanically worn.',
      14: 'P0016 plus misaligned timing marks points away from the turbo and toward a slipped timing belt.',
      15: 'If gasoline runs smoothly but LPG misfires, the base engine is healthy. LPG fuel-map calibration explains the behavior.',
    },
    'ru': {
      1: '9,2 В для аккумулятора слишком мало. Если с бустером мотор запускается, сначала подозревай аккумулятор, а не стартер.',
      2: 'Яркие лампы и частые щелчки означают, что питание есть, но стартер не крутит. Запуск после удара по стартеру усиливает диагноз.',
      3: 'Если лампа целая, а правая фара работает, проблема скорее в питании цепи. Проверка предохранителя здесь решающая.',
      4: 'Если на мотор дворников приходит 12 В, но он молчит, виноват скорее сам мотор, а не переключатель или предохранитель.',
      5: 'Почти нулевое давление кондиционера значит, что система пустая. Сначала найди утечку и заправь хладагент.',
      6: 'Горячий верхний патрубок и холодный нижний показывают, что антифриз не идет через радиатор. Это похоже на закрытый термостат.',
      7: 'Одна мокрая и закопченная свеча указывает на пропуски в этом цилиндре. При нормальной компрессии свеча — правильный первый ремонт.',
      8: 'Жесткие переключения вместе с темной ATF с запахом гари чаще говорят о старой жидкости, а не об электронике.',
      9: 'Металлический писк при торможении и колодка 1 мм означают, что индикатор износа касается диска.',
      10: 'Код P0136 и нижний O2-датчик, застывший на 0,45 В, сильнее указывают на датчик, чем на катализатор.',
      11: 'Если мокрый тест компрессии поднимает значения, масло временно уплотняет зазор. Это сильный признак износа колец.',
      12: 'Сладкий белый дым, уход антифриза и положительный блок-тест вместе указывают на пробой прокладки ГБЦ.',
      13: 'Зеленая жидкость, течь у помпы и вой подшипника означают, что водяная помпа течет и изношена.',
      14: 'P0016 и смещенные метки ГРМ уводят диагноз от турбины к перескочившему ремню ГРМ.',
      15: 'Если на бензине все ровно, а на LPG троит, базовый мотор здоров. Поведение объясняет калибровка карты LPG.',
    },
    'zh': {
      1: '电瓶只有 9.2V 明显过低。搭电后能启动，说明应先怀疑电瓶，而不是起动机。',
      2: '仪表灯很亮但只有快速咔哒声，说明有电但起动机没有转动。敲击后能启动会强化这个判断。',
      3: '灯泡完好且右大灯正常时，故障更可能在供电线路。检查保险丝是小动作，但很关键。',
      4: '雨刷电机插头有 12V 但电机无声，问题更像电机本身，而不是开关或保险丝。',
      5: '空调压力接近 0 说明系统已经漏空。先找漏点并重新加注，不要急着换压缩机。',
      6: '上水管热、下水管冷，说明冷却液没有经过散热器循环。卡在关闭位的节温器符合这个现象。',
      7: '只有一个气缸的火花塞湿黑，说明该缸点火不良。压缩正常时，先换火花塞是合理的。',
      8: '换挡冲击加上 ATF 颜色深且有焦味，通常是油液保养问题，而不是电子故障。',
      9: '刹车时金属尖叫且刹车片只剩 1mm，说明磨损报警片正在接触刹车盘。',
      10: 'P0136 加上下游氧传感器固定在 0.45V，比起三元催化，更指向传感器电路故障。',
      11: '湿式压缩测试数值升高，说明机油暂时封住了泄漏。这是活塞环磨损的强证据。',
      12: '甜味白烟、冷却液减少和缸压化学测试变色一起指向汽缸垫泄漏。',
      13: '绿色冷却液、水泵附近泄漏和轴承啸叫同时出现，说明水泵既漏水又机械磨损。',
      14: 'P0016 和正时标记错位，说明问题不像涡轮，而是正时皮带跳齿。',
      15: '汽油模式正常、LPG 模式抖动，说明基础发动机健康。LPG 燃油图校准能解释这个问题。',
    },
  };

  return notes[lang]?[id] ?? notes['en']?[id];
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
