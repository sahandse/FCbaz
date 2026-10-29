import 'package:fcbaz/features/settings/app_settings_repository.dart';
import 'package:fcbaz/features/settings/settings_screen.dart';
import 'package:fcbaz/src/theme/club_kits.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every club kit keeps readable contrast in both themes', () {
    for (final kit in kClubKits) {
      final dark = FCBazTheme.accessibleAccent(kit.accent, Brightness.dark);
      final light = FCBazTheme.accessibleAccent(kit.accent, Brightness.light);
      expect(
        FCBazTheme.contrastRatio(dark, FcbazPalette.dark.surface),
        greaterThanOrEqualTo(4.5),
        reason: '${kit.label} needs readable contrast in the dark theme',
      );
      expect(
        FCBazTheme.contrastRatio(light, FcbazPalette.light.surface),
        greaterThanOrEqualTo(4.5),
        reason: '${kit.label} needs readable contrast in the light theme',
      );
    }
  });

  test('club kits expose six curated presets', () {
    expect(kClubKits, hasLength(6));
    expect(kClubKits.map((kit) => kit.accent.toARGB32()).toSet(), hasLength(6));
  });

  testWidgets('selecting a club kit updates the accent setting', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    AppSettings? applied;
    await tester.pumpWidget(
      MaterialApp(
        theme: FCBazTheme.dark(),
        locale: const Locale('fa'),
        home: SettingsScreen(
          settings: const AppSettings(),
          onChanged: (value) => applied = value,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('کیت رنگی باشگاه (Club Kit)'), findsOneWidget);
    expect(find.text('پیش‌نمایش زنده کیت باشگاه'), findsOneWidget);
    for (final kit in kClubKits) {
      expect(find.text(kit.label), findsWidgets);
    }

    await tester.tap(find.text('آبی سلطنتی').first);
    await tester.pump();

    expect(applied?.accentColorValue, 0xFF82B1FF);
  });
}
