import 'package:fcbaz/features/evolutions/presentation/evolutions_screen.dart';
import 'package:fcbaz/features/home/objectives_screen.dart';
import 'package:fcbaz/features/sbc/presentation/sbc_screen.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<FlutterErrorDetails>> _pumpScreen(
  WidgetTester tester,
  Widget screen,
) async {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});

  final errors = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = errors.add;

  try {
    await tester.pumpWidget(
      MaterialApp(
        theme: FCBazTheme.dark(),
        home: Directionality(textDirection: TextDirection.rtl, child: screen),
      ),
    );
    await tester.pump();

    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 200));
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

void main() {
  testWidgets('SBC hub renders the sourced catalogue at 320px RTL', (
    tester,
  ) async {
    final errors = await _pumpScreen(tester, const SbcScreen());

    expect(find.text('SBC HUB'), findsOneWidget);
    expect(find.text('ابزارهای Rating و Cheapest'), findsOneWidget);
    expect(find.textContaining('Base Hero'), findsWidgets);
    expect(find.text('SBC در دسترس نیست'), findsNothing);
    expect(find.text('SBC فعالی پیدا نشد'), findsNothing);
    expect(errors, isEmpty);
  });

  testWidgets('Evolutions lab renders the sourced list at 320px RTL', (
    tester,
  ) async {
    final errors = await _pumpScreen(tester, const EvolutionsScreen());

    expect(find.text('EVOLUTIONS'), findsOneWidget);
    expect(find.textContaining('ساعت جادو'), findsWidgets);
    expect(find.text('Evolutionها در دسترس نیستند'), findsNothing);
    expect(find.text('Evolution فعالی پیدا نشد'), findsNothing);
    expect(errors, isEmpty);
  });

  testWidgets('Objectives renders live tasks at 320px RTL', (tester) async {
    final errors = await _pumpScreen(tester, const ObjectivesScreen());

    expect(find.text('هدف‌های زنده FC27'), findsOneWidget);
    expect(find.byType(ExpansionTile), findsWidgets);
    expect(find.text('هدف‌ها در دسترس نیست'), findsNothing);
    expect(find.text('هدف فعالی پیدا نشد'), findsNothing);
    expect(errors, isEmpty);
  });
}
