import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/navigation/main_shell.dart';
import '../features/notifications/price_alert_service.dart';
import '../features/settings/app_settings_repository.dart';
import 'theme/fcbaz_theme.dart';

class FCBazApp extends StatefulWidget {
  const FCBazApp({super.key});

  @override
  State<FCBazApp> createState() => _FCBazAppState();
}

class _FCBazAppState extends State<FCBazApp> with WidgetsBindingObserver {
  final settingsRepository = AppSettingsRepository();
  final priceAlertService = PriceAlertService();

  AppSettings settings = const AppSettings();
  bool ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initialize() async {
    AppSettings loaded = const AppSettings();
    try {
      loaded = await settingsRepository.load();
    } catch (_) {
      // Corrupt/unavailable local preferences must not block app startup.
    }

    if (!mounted) return;
    setState(() {
      settings = loaded;
      ready = true;
    });

    if (loaded.priceAlertsEnabled) {
      try {
        await priceAlertService.checkNow();
      } catch (_) {
        // Network/background price checks are optional during startup.
      }
    }
  }

  Future<void> _updateSettings(AppSettings value) async {
    setState(() => settings = value);
    try {
      await settingsRepository.save(value);
    } catch (_) {
      // Keep the current in-memory settings if local persistence fails.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!settings.marketRefreshOnResume || !settings.priceAlertsEnabled) return;
    priceAlertService.checkNow().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: FCBazTheme.light,
        darkTheme: FCBazTheme.dark,
        themeMode: ThemeMode.dark,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FCBaz',
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: settings.themeMode,
      theme: FCBazTheme.light,
      darkTheme: FCBazTheme.dark,
      home: MainShell(
        settings: settings,
        onSettingsChanged: _updateSettings,
      ),
    );
  }
}
