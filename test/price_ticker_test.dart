import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/ui/price_ticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/source_bundle.dart';

Widget _app(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    theme: FCBazTheme.dark(),
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: disableAnimations),
      child: appChild!,
    ),
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(child: child),
      ),
    ),
  );
}

void main() {
  final now = DateTime(2026, 10, 23, 12);

  testWidgets('shows the real price, delta and snapshot age', (tester) async {
    await tester.pumpWidget(
      _app(
        PriceTicker(
          price: 125000,
          changePercent: 4.25,
          updatedAt: now.subtract(const Duration(hours: 2)),
          now: now,
        ),
      ),
    );

    expect(find.text('۱۲۵,۰۰۰'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);
    expect(find.textContaining('۴.۲۵'), findsOneWidget);
    expect(find.textContaining('۲ ساعت پیش'), findsOneWidget);
  });

  testWidgets('does not invent a delta or timestamp', (tester) async {
    await tester.pumpWidget(
      _app(const PriceTicker(price: 8000, updatedAt: null)),
    );

    expect(find.text('۸,۰۰۰'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up_rounded), findsNothing);
    expect(find.byIcon(Icons.trending_down_rounded), findsNothing);
    expect(find.textContaining('به‌روزرسانی'), findsNothing);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('flashes on price changes and settles back', (tester) async {
    var price = 1000;
    late StateSetter update;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return PriceTicker(price: price, updatedAt: now, now: now);
          },
        ),
      ),
    );

    Color surfaceColor() {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(PriceTicker),
              matching: find.byType(Container),
            )
            .first,
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    final resting = surfaceColor();
    price = 1400;
    update(() {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final flashing = surfaceColor();
    expect(flashing, isNot(resting));

    await tester.pump(const Duration(milliseconds: 800));
    expect(surfaceColor(), resting);

    price = 900;
    update(() {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion skips the flash', (tester) async {
    var price = 1000;
    late StateSetter update;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return PriceTicker(price: price, now: now);
          },
        ),
        disableAnimations: true,
      ),
    );

    Color surfaceColor() {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(PriceTicker),
              matching: find.byType(Container),
            )
            .first,
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    final resting = surfaceColor();
    price = 1700;
    update(() {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(surfaceColor(), resting);
    expect(tester.takeException(), isNull);
  });

  testWidgets('very long prices fit a 320px surface', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        PriceTicker(
          price: 123456789,
          changePercent: -12.5,
          updatedAt: now.subtract(const Duration(days: 2)),
          now: now,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('۱۲۳,۴۵۶,۷۸۹'), findsOneWidget);
  });

  test('market screens use the shared ticker', () {
    expect(
      readSourceBundle(
        'lib/features/market/presentation/player_market_panel.dart',
      ),
      contains('PriceTicker'),
    );
    final market = readSourceBundle(
      'lib/features/market/presentation/market_screen.dart',
    );
    expect(market, contains('PriceTicker'));
    expect(market, contains('PriceDelta'));
  });
}
