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
      cheapestPriceByRating: const {83: 900, 84: 1800},
      limit: 30,
    );

    expect(combinations, isNotEmpty);
    final usesMissingPrice = combinations.where(
      (item) => item.counts.containsKey(85),
    );
    expect(usesMissingPrice, isNotEmpty);
    expect(
      usesMissingPrice.every((item) => item.estimatedCost == null),
      isTrue,
    );
  });

  test('cost is calculated only from supplied real price map', () {
    final combinations = calculator.combinations(
      targetRating: 83,
      minCardRating: 82,
      maxCardRating: 84,
      cheapestPriceByRating: const {82: 700, 83: 900, 84: 1400},
      limit: 10,
    );

    expect(combinations, isNotEmpty);
    expect(combinations.every((item) => item.estimatedCost != null), isTrue);
  });

  test('owned club cards reduce the coins needed to buy a combination', () {
    final combinations = calculator.combinations(
      targetRating: 83,
      minCardRating: 82,
      maxCardRating: 84,
      cheapestPriceByRating: const {82: 700, 83: 900, 84: 1400},
      ownedCountByRating: const {83: 1},
      limit: 30,
    );

    expect(combinations, isNotEmpty);
    for (final combination in combinations) {
      final expected =
          (combination.counts[82] ?? 0) * 700 +
          ((combination.counts[83] ?? 0) - 1).clamp(
                0,
                combination.counts[83] ?? 0,
              ) *
              900 +
          (combination.counts[84] ?? 0) * 1400;
      expect(combination.estimatedCost, expected);
    }
    expect(
      combinations.any(
        (item) =>
            item.counts[83] == 1 &&
            item.estimatedCost ==
                (item.counts[82] ?? 0) * 700 + (item.counts[84] ?? 0) * 1400,
      ),
      isTrue,
    );
  });

  test('a fully owned club combination costs zero instead of unknown', () {
    final combinations = calculator.combinations(
      targetRating: 85,
      cheapestPriceByRating: const {84: 1000, 86: 1200},
      ownedCountByRating: const {85: 11},
      limit: 60,
    );

    final fullyOwned = combinations.where(
      (item) => item.counts.length == 1 && item.counts[85] == 11,
    );
    expect(fullyOwned, isNotEmpty);
    expect(fullyOwned.every((item) => item.estimatedCost == 0), isTrue);
  });

  test('squad rating never drops when a single card rating increases', () {
    final samples = <List<int>>[
      [70, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79],
      [84, 84, 84, 84, 84, 84, 84, 84, 84, 84, 84],
      [99, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60],
      [90, 85, 80, 75, 70, 65, 60, 55, 50, 45, 40],
    ];

    for (final base in samples) {
      final initial = calculator.calculateSquadRating(base);
      for (var index = 0; index < base.length; index++) {
        final bumped = [...base];
        bumped[index] = (base[index] + 3).clamp(40, 99);
        expect(
          calculator.calculateSquadRating(bumped),
          greaterThanOrEqualTo(initial),
        );
      }
    }
  });

  test('club solver prefers untradeable cards when they reach the target', () {
    final club = [
      for (var i = 0; i < 11; i++) _ClubCard('u$i', 84, untradeable: true),
      for (var i = 0; i < 3; i++) _ClubCard('t$i', 90, untradeable: false),
    ];

    final solution = calculator.solveClubSquad<_ClubCard>(
      clubItems: club,
      getRating: (item) => item.rating,
      isUntradeable: (item) => item.untradeable,
      targetRating: 84,
    );

    expect(solution, isNotNull);
    expect(solution!.meetsTarget, isTrue);
    expect(solution.playerCount, 11);
    expect(solution.tradeables, isEmpty);
    expect(solution.untradeables.length, 11);
    expect(solution.squadRating, 84);
    expect(solution.counts, {84: 11});
  });

  test('club solver uses the fewest tradeable cards needed', () {
    final club = [
      for (var i = 0; i < 8; i++) _ClubCard('u$i', 75, untradeable: true),
      for (var i = 0; i < 5; i++) _ClubCard('t$i', 92, untradeable: false),
    ];

    final solution = calculator.solveClubSquad<_ClubCard>(
      clubItems: club,
      getRating: (item) => item.rating,
      isUntradeable: (item) => item.untradeable,
      targetRating: 83,
    );

    expect(solution, isNotNull);
    expect(solution!.meetsTarget, isTrue);
    expect(solution.tradeables.length, 3);
    expect(solution.untradeables.length, 8);
    expect(solution.counts, {75: 8, 92: 3});
  });

  test('club solver reports the real shortfall instead of inventing cards', () {
    final club = [
      for (var i = 0; i < 11; i++) _ClubCard('u$i', 70, untradeable: true),
    ];

    final solution = calculator.solveClubSquad<_ClubCard>(
      clubItems: club,
      getRating: (item) => item.rating,
      isUntradeable: (item) => item.untradeable,
      targetRating: 85,
    );

    expect(solution, isNotNull);
    expect(solution!.meetsTarget, isFalse);
    expect(solution.squadRating, 70);
    expect(solution.shortfall, 15);
    expect(solution.selected.length, 11);
  });

  test('club solver requires at least eleven club cards', () {
    final club = [
      for (var i = 0; i < 10; i++) _ClubCard('u$i', 84, untradeable: true),
    ];

    expect(
      calculator.solveClubSquad<_ClubCard>(
        clubItems: club,
        getRating: (item) => item.rating,
        isUntradeable: (item) => item.untradeable,
        targetRating: 84,
      ),
      isNull,
    );
  });
}

class _ClubCard {
  const _ClubCard(this.id, this.rating, {required this.untradeable});

  final String id;
  final int rating;
  final bool untradeable;
}
