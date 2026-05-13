import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/locale_provider.dart';
import '../../providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final canDeleteAccount = AuthService.isLinked;

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context)?.settings ?? 'Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- Language Section ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.language,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      S.of(context)?.language ?? 'Dil / Language',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...LocaleNotifier.supportedLocales.map((locale) {
                  final name =
                      LocaleNotifier.localeNames[locale.languageCode] ??
                      locale.languageCode;
                  final isSelected =
                      currentLocale.languageCode == locale.languageCode;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          ref.read(localeProvider.notifier).setLocale(locale);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primary,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // --- Account Deletion Section ---
          if (canDeleteAccount)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text(
                'Hesabı Sil / Delete Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showDeleteConfirmation(context, ref),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: AppTheme.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      S.of(context)!.guestDeleteDisabledInfo,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    if (!AuthService.isLinked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.guestDeleteDisabledSnack),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text(
          '⚠️ Hesabı Sil',
          style: TextStyle(color: AppTheme.danger),
        ),
        content: const Text(
          'Bu işlem geri alınamaz!\n\n'
          'Tüm ilerlemen, satın alımların ve kişisel verilerin '
          '30 gün içinde sistemlerimizden kalıcı olarak silinecektir.\n\n'
          'Onaylıyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              S.of(context)?.cancel ?? 'İptal',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              _performDeletion(context, ref);
            },
            child: const Text('Kalıcı Olarak Sil'),
          ),
        ],
      ),
    );
  }

  void _performDeletion(BuildContext context, WidgetRef ref) async {
    if (!AuthService.isLinked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.guestDeleteDisabledSnack),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Delete from DynamoDB via API
      await ref.read(apiClientProvider).deleteAccount();

      // 2. Delete from Firebase & Recreate Anonymous Session
      await AuthService.deleteAccount();

      if (context.mounted) {
        Navigator.pop(context); // close loader
        Navigator.pop(context); // close settings screen

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hesap başarıyla silindi ve sıfırlandı.'),
            backgroundColor: AppTheme.success,
          ),
        );

        // Reload fresh data
        ref.read(userProfileProvider.notifier).load();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Silme işlemi başarısız oldu: $e\nLütfen tekrar giriş yapıp deneyin.',
            ),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
