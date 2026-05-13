import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

Future<T> showRewardVerificationDialog<T>({
  required BuildContext context,
  required Future<T> Function() task,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _RewardVerificationDialog(),
  );

  try {
    return await task();
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

class _RewardVerificationDialog extends StatefulWidget {
  const _RewardVerificationDialog();

  @override
  State<_RewardVerificationDialog> createState() =>
      _RewardVerificationDialogState();
}

class _RewardVerificationDialogState extends State<_RewardVerificationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;

    return Dialog(
      backgroundColor: AppTheme.bgCard,
      insetPadding: const EdgeInsets.symmetric(horizontal: 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final turns = (_controller.value * 2).floor() / 2;
                final isTop = _controller.value < 0.5;
                return Transform.rotate(
                  angle: turns * 3.141592653589793,
                  child: Icon(
                    isTop ? Icons.hourglass_top : Icons.hourglass_bottom,
                    color: AppTheme.warning,
                    size: 46,
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              loc.rewardVerifyingTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.rewardVerifyingBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
