import 'package:flutter/material.dart';

class FCBazTheme {
  static const darkBackground = Color(0xFF080B0F);
  static const darkSurface = Color(0xFF10151C);
  static const darkSurfaceHigh = Color(0xFF171E27);
  static const primaryGreen = Color(0xFF66F08A);
  static const accentBlue = Color(0xFF79C8FF);
  static const warning = Color(0xFFFFC857);
  static const outline = Color(0xFF26303C);

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        background: darkBackground,
        surface: darkSurface,
        surfaceHigh: darkSurfaceHigh,
        primary: primaryGreen,
        secondary: accentBlue,
        outlineColor: outline,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        background: const Color(0xFFF4F7F5),
        surface: Colors.white,
        surfaceHigh: const Color(0xFFEEF3F0),
        primary: const Color(0xFF177A36),
        secondary: const Color(0xFF236FA6),
        outlineColor: const Color(0xFFD7E0DA),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceHigh,
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
      surfaceContainerHighest: surfaceHigh,
      outline: outlineColor,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -.4,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -.25,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.55),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: outlineColor.withValues(alpha: .85)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outlineColor.withValues(alpha: .7),
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: .14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: outlineColor),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
