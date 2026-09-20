import 'package:flutter/material.dart';

class FCBazTheme {
  static const darkBackground = Color(0xFF080A0E);
  static const darkSurface = Color(0xFF11151B);
  static const darkSurfaceHigh = Color(0xFF171C24);
  static const primaryGreen = Color(0xFF58E56E);
  static const accentBlue = Color(0xFF77C7FF);
  static const outline = Color(0xFF252C36);

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: darkBackground,
        surface: darkSurface,
        primary: primaryGreen,
        secondary: accentBlue,
        outlineColor: outline,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: const Color(0xFFF5F7F6),
        surface: Colors.white,
        primary: const Color(0xFF187A35),
        secondary: const Color(0xFF2B6EA8),
        outlineColor: const Color(0xFFDDE2E6),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color primary,
    required Color secondary,
    required Color outlineColor,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
    ).copyWith(
      primary: primary,
      secondary: secondary,
      surface: surface,
      outline: outlineColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: outlineColor),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: .18),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outlineColor),
        ),
      ),
    );
  }
}
