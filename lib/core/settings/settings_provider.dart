import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laravel_flutter_app/core/network/api_client.dart'; // يحتوي secureStorageProvider
import 'package:laravel_flutter_app/core/security/secure_storage_helper.dart';

class SettingsState {
  final Locale locale;
  final ThemeMode themeMode;

  SettingsState({required this.locale, required this.themeMode});

  SettingsState copyWith({Locale? locale, ThemeMode? themeMode}) =>
      SettingsState(
        locale: locale ?? this.locale,
        themeMode: themeMode ?? this.themeMode,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final ISecureStorageHelper _storage;

  SettingsNotifier(this._storage)
      : super(SettingsState(
          locale: const Locale('en'),
          themeMode: _getInitialThemeMode(),
        )) {
    _init();
  }

  /// تحديد الثيم الأولي من النظام دون انتظار Async
  static ThemeMode _getInitialThemeMode() {
    final brightness = PlatformDispatcher.instance.platformBrightness;
    return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _init() async {
    final localeCode = await _storage.read('locale_code');
    final themeCode = await _storage.read('theme_mode');

    // تحديث اللغة
    Locale? locale;
    if (localeCode != null) {
      locale = Locale(localeCode);
    } else {
      final deviceLocale = PlatformDispatcher.instance.locale;
      if (['ar', 'en'].contains(deviceLocale.languageCode)) {
        locale = Locale(deviceLocale.languageCode);
      }
    }

    // تحديث الثيم
    ThemeMode? themeMode;
    if (themeCode != null) {
      themeMode = themeCode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    }

    state = state.copyWith(
      locale: locale ?? state.locale,
      themeMode: themeMode ?? state.themeMode,
    );
  }

  void setLocale(Locale locale) {
    _storage.write('locale_code', locale.languageCode);
    state = state.copyWith(locale: locale);
  }

  void setThemeMode(ThemeMode mode) {
    _storage.write('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
    state = state.copyWith(themeMode: mode);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return SettingsNotifier(storage);
});
