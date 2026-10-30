import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/market/domain/purchase_value.dart';
import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/players/domain/player_value_analysis.dart';

Player buildPlayer({
  String id = '1',
  String name = 'Test Player',
  int rating = 90,
  String position = 'ST',
  int ps = 0,
  int pc = 0,
}) => Player(
  id: id,
  name: name,
  rating: rating,
  position: position,
  positions: [position],
  clubName: 'Club',
  leagueName: 'League',
  nationName: 'Nation',
  version: 'Gold',
  imageUrl: '',
  pace: 90,
  shooting: 90,
  passing: 80,
  dribbling: 88,
  defending: 40,
  physical: 82,
  skillMoves: 4,
  weakFoot: 4,
  pricePs: ps,
  pricePc: pc,
);

void main() {
  const analyzer = PurchaseValueAnalyzer();

  test('does not invent a purchase value without a real price', () {
    final value = analyzer.analyze(buildPlayer());
    expect(value.hasRealPrice, isFalse);
    expect(value.coinsPerRating, isNull);
    expect(value.taxAdjustedPrice, isNull);
    expect(value.taxAdjustedCoinsPerRating, isNull);
  });

  test('uses the selected platform price', () {
    final player = buildPlayer(ps: 100000, pc: 150000);
    expect(analyzer.analyze(player).price, 100000);
    expect(
      analyzer.analyze(player, platform: PlayerMarketPlatform.pc).price,
      150000,
    );
  });

  test('computes coins per rating and tax break-even from real numbers', () {
    final value = analyzer.analyze(buildPlayer(ps: 95000, rating: 90));
    expect(value.coinsPerRating, closeTo(95000 / 90, .0001));
    expect(value.taxAdjustedPrice, 100000);
    expect(value.taxAdjustedCoinsPerRating, closeTo(100000 / 90, .0001));
    expect(value.taxAdjustedPrice!, greaterThan(value.price));
  });

  test('ranks only priced cards from cheapest per rating', () {
    final players = [
      buildPlayer(id: 'a', name: 'Expensive', rating: 90, ps: 900000),
      buildPlayer(id: 'b', name: 'Cheap', rating: 85, ps: 85000),
      buildPlayer(id: 'c', name: 'Unpriced', rating: 95),
    ];
    final ranked = analyzer.rank(players);
    expect(ranked.map((item) => item.player.id), ['b', 'a']);
    expect(ranked.first.coinsPerRating!, lessThan(ranked.last.coinsPerRating!));
  });

  test('minRating filter keeps the value list honest', () {
    final players = [
      buildPlayer(id: 'a', rating: 84, ps: 50000),
      buildPlayer(id: 'b', rating: 86, ps: 90000),
    ];
    final ranked = analyzer.rank(players, minRating: 85);
    expect(ranked.length, 1);
    expect(ranked.single.player.id, 'b');
  });

  group('CheaperAlternativeFinder', () {
    const finder = CheaperAlternativeFinder();

    test('finds a cheaper same-position card within the rating gap', () {
      final target = buildPlayer(id: 'target', rating: 90, ps: 100000);
      final candidates = [
        buildPlayer(id: 'other-pos', rating: 90, position: 'CM', ps: 40000),
        buildPlayer(id: 'too-low', rating: 80, ps: 30000),
        buildPlayer(id: 'good', rating: 89, ps: 60000),
      ];
      final alternative = finder.find(target, candidates);
      expect(alternative, isNotNull);
      expect(alternative!.player.id, 'good');
      expect(alternative.savings, 40000);
      expect(alternative.ratingGap, 1);
    });

    test('returns null when nothing is honestly cheaper', () {
      final target = buildPlayer(id: 'target', rating: 90, ps: 100000);
      final candidates = [
        buildPlayer(id: 'pricier', rating: 91, ps: 200000),
        buildPlayer(id: 'unpriced', rating: 90, ps: 0),
      ];
      expect(finder.find(target, candidates), isNull);
    });

    test('returns null when the target price is unknown', () {
      final target = buildPlayer(id: 'target', rating: 90);
      final candidates = [buildPlayer(id: 'cheap', rating: 89, ps: 50000)];
      expect(finder.find(target, candidates), isNull);
    });
  });
}
