import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fcbaz/features/market/domain/transfer_tax.dart';
import 'package:fcbaz/features/market/presentation/market_tax_calculator_panel.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';

void main() {
  group('TransferTaxCalculator', () {
    const calculator = TransferTaxCalculator();

    test('takes 5 percent of the sale price rounded to the nearest coin', () {
      expect(calculator.taxFor(5000), 250);
      expect(calculator.taxFor(1234), 62);
      expect(calculator.taxFor(0), 0);
    });

    test('computes net, profit, ROI and break-even for a profitable flip', () {
      final result = calculator.evaluate(buyPrice: 4000, salePrice: 5000)!;

      expect(result.tax, 250);
      expect(result.net, 4750);
      expect(result.profit, 750);
      expect(result.roiPercent, closeTo(18.75, 0.0001));
      expect(result.breakEvenSalePrice, 4211);
      expect(result.isProfit, isTrue);
      expect(result.isLoss, isFalse);
    });

    test('treats an exact break-even sale as zero profit', () {
      final result = calculator.evaluate(buyPrice: 9500, salePrice: 10000)!;

      expect(result.tax, 500);
      expect(result.net, 9500);
      expect(result.profit, 0);
      expect(result.isProfit, isFalse);
      expect(result.isLoss, isFalse);
      expect(result.breakEvenSalePrice, 10000);
    });

    test('rounds the break-even price up so the seller never loses coins', () {
      final result = calculator.evaluate(buyPrice: 6000, salePrice: 5000)!;

      expect(result.profit, -1250);
      expect(result.isLoss, isTrue);
      expect(result.breakEvenSalePrice, 6316);
    });

    test('leaves ROI unknown when the buy price is zero', () {
      final result = calculator.evaluate(buyPrice: 0, salePrice: 5000)!;

      expect(result.profit, 4750);
      expect(result.roiPercent, isNull);
      expect(result.breakEvenSalePrice, 0);
    });

    test('refuses to evaluate a sale without a real sale price', () {
      expect(calculator.evaluate(buyPrice: 4000, salePrice: 0), isNull);
      expect(calculator.evaluate(buyPrice: 4000, salePrice: -1), isNull);
      expect(calculator.evaluate(buyPrice: -1, salePrice: 5000), isNull);
    });
  });

  group('MarketTaxCalculatorPanel', () {
    Widget host(Widget child) => MaterialApp(
      theme: FCBazTheme.dark(),
      builder: (context, inner) =>
          Directionality(textDirection: TextDirection.rtl, child: inner!),
      home: Scaffold(body: child),
    );

    Future<void> pumpPanel(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(const MarketTaxCalculatorPanel()));
      await tester.pump();
    }

    Future<void> enterPrices(
      WidgetTester tester, {
      String? buy,
      String? sell,
    }) async {
      if (buy != null) {
        await tester.enterText(find.byType(TextField).first, buy);
      }
      if (sell != null) {
        await tester.enterText(find.byType(TextField).at(1), sell);
      }
      await tester.pump();
    }

    testWidgets('shows tax, net, profit, ROI and break-even from real input', (
      tester,
    ) async {
      await pumpPanel(tester);
      expect(
        find.text('قیمت فروش را وارد کن تا مالیات و خالص دریافتی محاسبه شود.'),
        findsOneWidget,
      );

      await enterPrices(tester, buy: '4000', sell: '5000');

      expect(find.text('۲۵۰ سکه'), findsOneWidget);
      expect(find.text('۴,۷۵۰ سکه'), findsOneWidget);
      expect(find.text('+۷۵۰ سکه'), findsOneWidget);
      expect(find.text('۱۸.۸٪'), findsOneWidget);
      expect(find.text('۴,۲۱۱ سکه'), findsOneWidget);
      expect(find.text('سود خالص'), findsOneWidget);
    });

    testWidgets('accepts Persian digits and reports a loss honestly', (
      tester,
    ) async {
      await pumpPanel(tester);
      await enterPrices(tester, buy: '۶۰۰۰', sell: '۵۰۰۰');

      expect(find.text('−۱,۲۵۰ سکه'), findsOneWidget);
      expect(find.text('۶,۳۱۶ سکه'), findsOneWidget);
      expect(find.text('ضرر خالص'), findsOneWidget);
    });

    testWidgets('asks for a buy price before showing profit metrics', (
      tester,
    ) async {
      await pumpPanel(tester);
      await enterPrices(tester, sell: '5000');

      expect(find.text('۲۵۰ سکه'), findsOneWidget);
      expect(find.text('۴,۷۵۰ سکه'), findsOneWidget);
      expect(
        find.text(
          'برای دیدن سود، بازده سرمایه و قیمت سربه‌سر، قیمت خرید را هم وارد کن.',
        ),
        findsOneWidget,
      );
      expect(find.text('سود خالص'), findsNothing);
    });

    testWidgets('rejects non-numeric input instead of guessing a price', (
      tester,
    ) async {
      await pumpPanel(tester);
      await enterPrices(tester, buy: 'abc', sell: '5000');

      expect(find.text('فقط عدد سکه پذیرفته می‌شود.'), findsOneWidget);
      expect(find.text('سود خالص'), findsNothing);
    });
  });
}
