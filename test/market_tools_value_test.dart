import 'package:fcbaz/features/market/presentation/market_tools_screen.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('market tools exposes the value tab with honest source copy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: FCBazTheme.dark(), home: const MarketToolsScreen()),
    );
    await tester.pump();

    expect(find.widgetWithText(Tab, 'ارزش خرید'), findsOneWidget);

    await tester.drag(find.byType(TabBar), const Offset(-260, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(Tab, 'ارزش خرید'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Value to Buy'), findsOneWidget);
    expect(
      find.textContaining('ارزش خرید از قیمت واقعی همان پلتفرم'),
      findsOneWidget,
    );
    expect(find.text('۸۵+'), findsOneWidget);
    expect(find.text('۹۰+'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('۹۰+'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });
}
