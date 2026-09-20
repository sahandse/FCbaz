import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.localeCode = 'fa',
    this.defaultPlatform = 'console',
    this.priceAlertsEnabled = true,
    this.marketRefreshOnResume = true,
  });

  final ThemeMode themeMode;
  final String localeCode;
  final String defaultPlatform;
  final bool priceAlertsEnabled;
  final bool marketRefreshOnResume;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    String? defaultPlatform,
    bool? priceAlertsEnabled,
    bool? marketRefreshOnResume,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode ?? this.localeCode,
        defaultPlatform: defaultPlatform ?? this.defaultPlatform,
        priceAlertsEnabled: priceAlertsEnabled ?? this.priceAlertsEnabled,
        marketRefreshOnResume:
            marketRefreshOnResume ?? this.marketRefreshOnResume,
      );
}

class AppSettingsRepository {
  static const _themeKey = 'fcbaz_theme_mode';
  static const _localeKey = 'fcbaz_locale';
  static const _platformKey = 'fcbaz_default_platform';
  static const _alertsKey = 'fcbaz_price_alerts_enabled';
  static const _resumeRefreshKey = 'fcbaz_market_refresh_on_resume';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeRaw = prefs.getString(_themeKey) ?? 'dark';
    final theme = switch (themeRaw) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

    return AppSettings(
      themeMode: theme,
      localeCode: 'fa',
      defaultPlatform: prefs.getString(_platformKey) ?? 'console',
      priceAlertsEnabled: prefs.getBool(_alertsKey) ?? true,
      marketRefreshOnResume: prefs.getBool(_resumeRefreshKey) ?? true,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    final theme = switch (settings.themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };

    await Future.wait([
      prefs.setString(_themeKey, theme),
      prefs.setString(_localeKey, 'fa'),
      prefs.setString(_platformKey, settings.defaultPlatform),
      prefs.setBool(_alertsKey, settings.priceAlertsEnabled),
      prefs.setBool(_resumeRefreshKey, settings.marketRefreshOnResume),
    ]);
  }
}
