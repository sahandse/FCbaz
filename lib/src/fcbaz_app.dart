import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/fcbaz_theme.dart';
import '../features/navigation/main_shell.dart';

class FCBazApp extends StatefulWidget {
  const FCBazApp({super.key});

  @override
  State<FCBazApp> createState() => _FCBazAppState();
}

class _FCBazAppState extends State<FCBazApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FCBaz',
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _themeMode,
      theme: FCBazTheme.light,
      darkTheme: FCBazTheme.dark,
      builder: (context, child) => Directionality(
        textDirection: Directionality.of(context),
        child: child ?? const SizedBox.shrink(),
      ),
      home: MainShell(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
