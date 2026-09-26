import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/sbc/domain/sbc_rating_tools.dart';

void main() {
  const calculator = SbcRatingCalculator();

  test('traditional SBC squad rating uses correction factor', () {
    final rating = calculator.calculateSquadRating([
      87,
      87,
      86,
      86,
      86,
      85,
      85,
      85,
      85,
      85,
      85,
    ]);

    expect(rating, greaterThanOrEqualTo(86));
  });

  test('combinations always contain exactly 11 cards and meet target', () {
    final combinations = calculator.combinations(
      targetRating: 84,
      minCardRating: 79,
      maxCardRating: 89,
      limit: 20,
    );

    expect(combinations, isNotEmpty);
    for (final combination in combinations) {
      expect(combination.playerCount, 11);
      expect(combination.squadRating, greaterThanOrEqualTo(84));
    }
  });

  test('cost stays unavailable when any real rating price is missing', () {
    final combinations = calculator.combinations(
      targetRating: 84,
      minCardRating: 83,
      maxCardRating: 85,
      cheapestPriceByRating: const {
        83: 900,
        84: 1800,
      },
      limit: 30,
    );

    expect(combinations, isNotEmpty);
    final usesMissingPrice = combinations.where((item) => item.counts.containsKey(85));
    expect(usesMissingPrice, isNotEmpty);
    expect(usesMissingPrice.every((item) => item.estimatedCost == null), isTrue);
  });

  test('cost is calculated only from supplied real price map', () {
    final combinations = calculator.combinations(
      targetRating: 83,
      minCardRating: 82,
      maxCardRating: 84,
      cheapestPriceByRating: const {
        82: 700,
        83: 900,
        84: 1400,
      },
      limit: 10,
    );

    expect(combinations, isNotEmpty);
    expect(combinations.every((item) => item.estimatedCost != null), isTrue);
  });
}
