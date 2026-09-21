import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/core/market/tax_calculator.dart';
import 'package:fcbaz/features/market/domain/player_price.dart';
import 'package:fcbaz/features/market/domain/player_price_ext.dart';
import 'package:fcbaz/features/sbc/domain/rating_combination_solver.dart';

void main() {
  group('TaxCalculator', () {
    test('applies 5 percent tax', () {
      expect(TaxCalculator.taxOn(100000), 5000);
      expect(TaxCalculator.netAfterTax(100000), 95000);
      expect(TaxCalculator.maxBuyForProfit(100000), 94999);
      expect(
        TaxCalculator.profit(buyPrice: 90000, sellPrice: 100000),
        5000,
      );
    });

    test('handles zero and negative safely', () {
      expect(TaxCalculator.taxOn(0), 0);
      expect(TaxCalculator.netAfterTax(-10), 0);
      expect(TaxCalculator.maxBuyForProfit(0), 0);
    });
  });

  group('PlayerPrice bins', () {
    test('parses lowest bins and tax helpers', () {
      final price = PlayerPrice.fromJson({
        'player_id': 'p1',
        'platform': 'console',
        'current': 100000,
        'low': 90000,
        'high': 120000,
        'change_24h_percent': 1.5,
        'lowest_bins': [98000, 99000, 100000],
      });

      expect(price.lowestBins, [98000, 99000, 100000]);
      expect(price.displayBins.length, 3);
      expect(price.taxAmount, 5000);
      expect(price.netAfterTax, 95000);
    });
  });

  group('RatingCombinationSolver', () {
    test('returns practical mixes for target rating', () {
      const solver = RatingCombinationSolver();
      final combos = solver.solve(targetRating: 84);
      expect(combos, isNotEmpty);
      for (final combo in combos) {
        expect(combo.ratings.length, 11);
        expect(combo.average, greaterThanOrEqualTo(84));
        expect(combo.summary, isNotEmpty);
      }
    });
  });
}
