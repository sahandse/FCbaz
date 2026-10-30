import 'package:flutter_test/flutter_test.dart';

import 'package:fcbaz/features/sbc/domain/sbc_rating_tools.dart';
import 'package:fcbaz/features/sbc/domain/sbc_shopping_list.dart';

const _combination = SbcRatingCombination(
  counts: {84: 5, 83: 6},
  squadRating: 84,
);

Map<int, SbcShoppingCandidate> _candidates({
  int price84 = 12000,
  int price83 = 10000,
}) {
  return {
    84: SbcShoppingCandidate(
      playerId: 'p84',
      playerName: 'Player 84',
      price: price84,
    ),
    83: SbcShoppingCandidate(
      playerId: 'p83',
      playerName: 'Player 83',
      price: price83,
    ),
  };
}

void main() {
  test('buys only the missing cards after the club is counted', () {
    final list = SbcShoppingList.build(
      targetRating: 84,
      combination: _combination,
      candidates: _candidates(),
      ownedCountByRating: const {84: 5, 83: 2},
    );

    expect(list.items, hasLength(1));
    expect(list.items.single.rating, 83);
    expect(list.items.single.count, 4);
    expect(list.items.single.totalPrice, 40000);
    expect(list.ownedCount, 7);
    expect(list.purchaseCount, 4);
    expect(list.hasCompletePrices, isTrue);
    expect(list.knownCost, 40000);
  });

  test('keeps ratings without a real price out of the cost', () {
    final list = SbcShoppingList.build(
      targetRating: 84,
      combination: _combination,
      candidates: _candidates(price83: 0),
      ownedCountByRating: const {84: 5},
      budget: 100000,
    );

    expect(list.unpricedCounts, {83: 6});
    expect(list.unpricedCount, 6);
    expect(list.hasCompletePrices, isFalse);
    expect(list.remainingBudget, isNull);
    expect(list.shortfall, isNull);
    expect(list.withinBudget, isFalse);
    expect(list.toShareText(), contains('قیمت واقعی در دسترس نیست'));
    expect(list.toShareText(), contains('مقایسه انجام نمی‌شود'));
  });

  test('reports the remaining budget when every row is priced', () {
    final list = SbcShoppingList.build(
      targetRating: 84,
      combination: _combination,
      candidates: _candidates(),
      ownedCountByRating: const {84: 5, 83: 2},
      budget: 50000,
    );

    expect(list.knownCost, 40000);
    expect(list.remainingBudget, 10000);
    expect(list.shortfall, 0);
    expect(list.withinBudget, isTrue);
    expect(list.toShareText(), contains('باقیمانده بودجه'));
    expect(list.toShareText(), contains('۱۰,۰۰۰'));
  });

  test('reports a real shortfall when the plan exceeds the budget', () {
    final list = SbcShoppingList.build(
      targetRating: 84,
      combination: _combination,
      candidates: _candidates(),
      ownedCountByRating: const {84: 5, 83: 2},
      budget: 30000,
    );

    expect(list.remainingBudget, -10000);
    expect(list.shortfall, 10000);
    expect(list.withinBudget, isFalse);
    expect(list.toShareText(), contains('کمبود بودجه'));
    expect(list.toShareText(), contains('۱۰,۰۰۰'));
  });

  test('is empty and exportable when the club covers every slot', () {
    final list = SbcShoppingList.build(
      targetRating: 84,
      combination: _combination,
      candidates: _candidates(),
      ownedCountByRating: const {84: 5, 83: 6},
      budget: 10000,
    );

    expect(list.isEmpty, isTrue);
    expect(list.knownCost, 0);
    expect(list.remainingBudget, 10000);
    expect(list.toShareText(), contains('خرید لازم نیست'));
  });

  test('treats a zero candidate price as unpriced', () {
    final list = SbcShoppingList.build(
      targetRating: 84,
      combination: _combination,
      candidates: _candidates(price84: 0),
      ownedCountByRating: const {83: 6},
    );

    expect(list.unpricedCounts, {84: 5});
    expect(list.items, isEmpty);
    expect(list.hasCompletePrices, isFalse);
  });
}
