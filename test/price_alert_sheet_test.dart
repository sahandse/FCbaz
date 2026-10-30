import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fcbaz/features/market/presentation/price_alert_sheet.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';

void main() {
  testWidgets('accepts Persian digits and previews the local alert', (
    tester,
  ) async {
    PriceAlertChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        theme: FCBazTheme.dark(),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  choice = await showPriceAlertSheet(
                    context,
                    playerName: 'Player One',
                    currentPrice: 100000,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('هشدار قیمت محلی'), findsOneWidget);
    expect(find.textContaining('فقط روی همین دستگاه'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '۹۰٬۰۰۰');
    await tester.pump();

    expect(find.textContaining('به ۹۰,۰۰۰ سکه رسیده'), findsOneWidget);
    expect(find.textContaining('۱۰٪ کاهش'), findsOneWidget);

    await tester.tap(find.text('ذخیره هدف'));
    await tester.pumpAndSettle();

    expect(choice?.targetPrice, 90000);
    expect(choice?.remove, isFalse);
  });

  testWidgets('rejects an empty target instead of saving zero', (tester) async {
    PriceAlertChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        theme: FCBazTheme.dark(),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  choice = await showPriceAlertSheet(
                    context,
                    playerName: 'Player One',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ذخیره هدف'));
    await tester.pump();

    expect(choice, isNull);
    expect(find.textContaining('بزرگ‌تر از صفر'), findsOneWidget);
    expect(find.text('هشدار قیمت محلی'), findsOneWidget);
  });
}
