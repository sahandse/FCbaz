import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/ui/paper_pitch_background.dart';

int _channel(Color color, int shift) => (color.toARGB32() >> shift) & 0xFF;

void main() {
  test('Paper Pitch palette is warm paper with readable ink', () {
    final light = FcbazPalette.light;
    expect(_channel(light.canvas, 16), greaterThan(_channel(light.canvas, 0)));
    expect(
      _channel(light.surface, 16),
      greaterThan(_channel(light.surface, 0)),
    );
    expect(_channel(light.canvas, 8), greaterThan(_channel(light.canvas, 0)));
    expect(
      FCBazTheme.contrastRatio(light.textMuted, light.surfaceRaised),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      FCBazTheme.contrastRatio(light.onPrimary, light.primary),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('light cards carry a warm shadow while dark stays flat', () {
    final light = FCBazTheme.light();
    final dark = FCBazTheme.dark();
    expect(light.cardTheme.elevation, greaterThan(0));
    expect(dark.cardTheme.elevation, 0);
    expect(_channel(light.cardTheme.shadowColor!, 24), greaterThan(0));
    expect(
      _channel(light.cardTheme.shadowColor!, 16),
      greaterThan(_channel(light.cardTheme.shadowColor!, 0)),
    );
  });

  testWidgets('paper pitch lines only render in light mode', (tester) async {
    Widget host(ThemeData theme) => MaterialApp(
      theme: theme,
      themeAnimationDuration: Duration.zero,
      home: const Scaffold(
        body: PaperPitchBackground(child: SizedBox.expand()),
      ),
    );

    await tester.pumpWidget(host(FCBazTheme.light()));
    expect(find.byKey(const ValueKey('paper-pitch-lines')), findsOneWidget);

    await tester.pumpWidget(host(FCBazTheme.dark()));
    expect(find.byKey(const ValueKey('paper-pitch-lines')), findsNothing);
  });

  test('club lime is shifted to an accessible ink on paper', () {
    const lime = Color(0xFFC8FF42);
    final resolved = FCBazTheme.accessibleAccent(lime, Brightness.light);
    expect(
      FCBazTheme.contrastRatio(resolved, FcbazPalette.light.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(resolved, isNot(lime));
  });
}
