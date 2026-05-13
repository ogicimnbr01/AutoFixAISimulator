import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's locale (language) state with persistence.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_deviceLocaleOrEnglish()) {
    _loadSavedLocale();
  }

  static const _key = 'app_locale';

  static const supportedLocales = [
    Locale('tr'),
    Locale('en'),
    Locale('ru'),
    Locale('zh'),
  ];

  static const localeNames = {
    'tr': '🇹🇷 Türkçe',
    'en': '🇬🇧 English',
    'ru': '🇷🇺 Русский',
    'zh': '🇨🇳 中文',
  };

  static Locale _deviceLocaleOrEnglish() {
    final deviceCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final isSupported = supportedLocales.any(
      (locale) => locale.languageCode == deviceCode,
    );
    return Locale(isSupported ? deviceCode : 'en');
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null &&
        supportedLocales.any((locale) => locale.languageCode == code)) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  String get currentName =>
      localeNames[state.languageCode] ?? state.languageCode;
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
