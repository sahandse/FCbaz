import 'package:flutter/material.dart';

@immutable
class FcbazPalette extends ThemeExtension<FcbazPalette> {
  const FcbazPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.warning,
    required this.danger,
    required this.success,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color line;
  final Color lineStrong;
  final Color text;
  final Color textMuted;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color warning;
  final Color danger;
  final Color success;

  static const dark = FcbazPalette(
    canvas: Color(0xFF050706),
    surface: Color(0xFF0B100C),
    surfaceRaised: Color(0xFF121A13),
    line: Color(0xFF26352A),
    lineStrong: Color(0xFF354839),
    text: Color(0xFFF2F6EF),
    textMuted: Color(0xFFA7B4A9),
    primary: Color(0xFFC8FF42),
    onPrimary: Color(0xFF10140C),
    secondary: Color(0xFF7DEBFF),
    warning: Color(0xFFFFD76A),
    danger: Color(0xFFFF5F72),
    success: Color(0xFF6EE7A0),
  );

  static const light = FcbazPalette(
    // Paper Pitch: a warm, matte paper canvas instead of a cool grey one.
    canvas: Color(0xFFF4EDDD),
    surface: Color(0xFFFFFBF2),
    surfaceRaised: Color(0xFFEAE0CC),
    line: Color(0xFFD6C9AF),
    lineStrong: Color(0xFFB7A786),
    text: Color(0xFF241F14),
    textMuted: Color(0xFF6A5F4B),
    primary: Color(0xFF4A6600),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF00695C),
    warning: Color(0xFF8A5B00),
    danger: Color(0xFFB3263A),
    success: Color(0xFF1F6B3A),
  );

  @override
  FcbazPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? line,
    Color? lineStrong,
    Color? text,
    Color? textMuted,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? warning,
    Color? danger,
    Color? success,
  }) {
    return FcbazPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      success: success ?? this.success,
    );
  }

  @override
  FcbazPalette lerp(covariant FcbazPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return FcbazPalette(
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      line: mix(line, other.line),
      lineStrong: mix(lineStrong, other.lineStrong),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      secondary: mix(secondary, other.secondary),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      success: mix(success, other.success),
    );
  }
}

extension FcbazThemeContext on BuildContext {
  FcbazPalette get palette =>
      Theme.of(this).extension<FcbazPalette>() ?? FcbazPalette.dark;
}

abstract final class FcbazSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const page = 16.0;
}

abstract final class FcbazRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const pill = 999.0;
}

class FCBazTheme {
  static const darkBackground = Color(0xFF050706);
  static const darkSurface = Color(0xFF0B100C);
  static const darkSurfaceHigh = Color(0xFF121A13);
  static const primaryGreen = Color(0xFFC8FF42);
  static const accentBlue = Color(0xFF7DEBFF);
  static const warning = Color(0xFFFFD76A);
  static const outline = Color(0xFF26352A);

  static ThemeData dark([Color? accent]) {
    final resolved = accent == null
        ? null
        : accessibleAccent(accent, Brightness.dark);
    return _build(
      brightness: Brightness.dark,
      palette: resolved == null
          ? FcbazPalette.dark
          : FcbazPalette.dark.copyWith(
              primary: resolved,
              onPrimary: _onColor(resolved),
            ),
    );
  }

  static ThemeData light([Color? accent]) {
    final resolved = accent == null
        ? null
        : accessibleAccent(accent, Brightness.light);
    return _build(
      brightness: Brightness.light,
      palette: resolved == null
          ? FcbazPalette.light
          : FcbazPalette.light.copyWith(
              primary: resolved,
              onPrimary: _onColor(resolved),
            ),
    );
  }

  /// Shifts [accent] lightness until it reaches 4.5:1 contrast on the base
  /// surface of [brightness], so bright club kits stay readable on paper and
  /// dark kits stay readable in the dark theme.
  static Color accessibleAccent(Color accent, Brightness brightness) {
    final background = brightness == Brightness.dark
        ? FcbazPalette.dark.surface
        : FcbazPalette.light.surface;
    final step = brightness == Brightness.dark ? .04 : -.04;
    var resolved = accent;
    for (var i = 0; i < 24 && contrastRatio(resolved, background) < 4.5; i++) {
      final hsl = HSLColor.fromColor(resolved);
      resolved = hsl
          .withLightness((hsl.lightness + step).clamp(0.0, 1.0))
          .toColor();
    }
    return resolved;
  }

  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + .05) / (darker + .05);
  }

  static Color _onColor(Color color) => foregroundOn(color);

  static Color foregroundOn(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : const Color(0xFF10140C);

  static ThemeData _build({
    required Brightness brightness,
    required FcbazPalette palette,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: brightness,
          surface: palette.surface,
        ).copyWith(
          primary: palette.primary,
          onPrimary: palette.onPrimary,
          secondary: palette.secondary,
          surface: palette.surface,
          surfaceContainerHighest: palette.surfaceRaised,
          onSurface: palette.text,
          onSurfaceVariant: palette.textMuted,
          outline: palette.line,
          outlineVariant: palette.lineStrong,
          error: palette.danger,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.compact,
      fontFamily: 'Vazirmatn',
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(FcbazRadius.md),
      side: BorderSide(color: palette.line),
    );

    return base.copyWith(
      extensions: [palette],
      textTheme: base.textTheme
          .apply(
            fontFamily: 'Vazirmatn',
            bodyColor: palette.text,
            displayColor: palette.text,
          )
          .copyWith(
            displaySmall: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w800,
              fontSize: 32,
              height: 1.25,
              color: palette.text,
            ),
            headlineMedium: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w800,
              fontSize: 26,
              height: 1.3,
              color: palette.text,
            ),
            headlineSmall: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              height: 1.35,
              color: palette.text,
            ),
            titleLarge: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              height: 1.4,
              color: palette.text,
            ),
            titleMedium: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.45,
              color: palette.text,
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 1.7,
              color: palette.text,
            ),
            bodySmall: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w400,
              fontSize: 12.5,
              height: 1.6,
              color: palette.textMuted,
            ),
            labelLarge: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.4,
              color: palette.text,
            ),
          ),
      cardTheme: CardThemeData(
        // Paper Pitch cards sit on warm paper: a soft-but-crisp warm shadow
        // keeps them legible without the flat dark-mode look.
        elevation: brightness == Brightness.light ? 2 : 0,
        shadowColor: brightness == Brightness.light
            ? const Color(0x2E6B5A38)
            : Colors.transparent,
        margin: EdgeInsets.zero,
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      dividerTheme: DividerThemeData(
        color: palette.line,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.primary,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FcbazRadius.sm),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 21,
            color: states.contains(WidgetState.selected)
                ? palette.onPrimary
                : palette.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? palette.primary
                : palette.textMuted,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: palette.canvas,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 58,
        titleTextStyle: TextStyle(
          fontFamily: 'Vazirmatn',
          color: palette.text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceRaised.withValues(alpha: .7),
        hintStyle: TextStyle(
          fontFamily: 'Vazirmatn',
          color: palette.textMuted,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FcbazRadius.md),
          borderSide: BorderSide(color: palette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FcbazRadius.md),
          borderSide: BorderSide(color: palette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FcbazRadius.md),
          borderSide: BorderSide(color: palette.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(46, 46),
          elevation: 0,
          foregroundColor: palette.onPrimary,
          backgroundColor: palette.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FcbazRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(46, 46),
          foregroundColor: palette.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FcbazRadius.md),
          ),
          side: BorderSide(color: palette.lineStrong),
          textStyle: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FcbazRadius.sm),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: palette.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FcbazRadius.sm),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? palette.primary
                : palette.surfaceRaised.withValues(alpha: .75),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? palette.onPrimary
                : palette.text,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: palette.line)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FcbazRadius.sm),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: palette.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: palette.line,
        labelColor: palette.primary,
        unselectedLabelColor: palette.textMuted,
        labelStyle: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w500,
          fontSize: 12.5,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: palette.surface,
        collapsedBackgroundColor: palette.surface,
        iconColor: palette.primary,
        collapsedIconColor: palette.textMuted,
        textColor: palette.text,
        collapsedTextColor: palette.text,
        shape: shape,
        collapsedShape: shape,
        tilePadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FcbazRadius.md),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FcbazRadius.md),
          side: BorderSide(color: palette.line),
        ),
        textStyle: TextStyle(
          fontFamily: 'Vazirmatn',
          color: palette.text,
          fontWeight: FontWeight.w500,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: palette.primary,
        textColor: palette.onPrimary,
        largeSize: 18,
        textStyle: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: BorderRadius.circular(FcbazRadius.sm),
          border: Border.all(color: palette.line),
        ),
        textStyle: TextStyle(
          fontFamily: 'Vazirmatn',
          color: palette.text,
          fontWeight: FontWeight.w500,
          fontSize: 11.5,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FcbazRadius.lg),
          side: BorderSide(color: palette.line),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: palette.primary.withValues(alpha: .55),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FcbazRadius.lg),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.surfaceRaised,
        contentTextStyle: TextStyle(
          fontFamily: 'Vazirmatn',
          color: palette.text,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FcbazRadius.md),
          side: BorderSide(color: palette.line),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 7,
        iconColor: palette.textMuted,
        textColor: palette.text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FcbazRadius.sm),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primary
              : palette.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primary.withValues(alpha: .28)
              : palette.surfaceRaised,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(palette.onPrimary),
        side: BorderSide(color: palette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.surfaceRaised,
        circularTrackColor: palette.surfaceRaised,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: palette.surfaceRaised.withValues(alpha: .72),
        selectedColor: palette.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FcbazRadius.sm),
        ),
        side: BorderSide(color: palette.line),
        labelStyle: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
