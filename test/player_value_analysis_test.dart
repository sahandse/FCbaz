import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/players/domain/player_value_analysis.dart';

Player buildPlayer({int ps = 0, int pc = 0}) => Player(
      id: '1',
      name: 'Test Player',
      rating: 90,
      position: 'ST',
      positions: const ['ST'],
      clubName: 'Club',
      leagueName: 'League',
      nationName: 'Nation',
      version: 'Gold',
      imageUrl: '',
      pace: 92,
      shooting: 91,
      passing: 84,
      dribbling: 90,
      defending: 40,
      physical: 82,
      skillMoves: 5,
      weakFoot: 4,
      playStyles: const ['Quick Step', 'Finesse Shot'],
      playStylesPlus: const ['Rapid+'],
      roles: const ['Advanced Forward++'],
      pricePs: ps,
      pricePc: pc,
    );

void main() {
  const analyzer = PlayerValueAnalyzer();

  test('does not invent value index when real price is missing', () {
    final result = analyzer.analyze(buildPlayer());
    expect(result.price, 0);
    expect(result.valueIndex, isNull);
    expect(result.hasRealPrice, isFalse);
  });

  test('uses the selected platform price', () {
    final player = buildPlayer(ps: 100000, pc: 150000);
    final console = analyzer.analyze(player);
    final pc = analyzer.analyze(
      player,
      platform: PlayerMarketPlatform.pc,
    );

    expect(console.price, 100000);
    expect(pc.price, 150000);
    expect(console.valueIndex, isNotNull);
    expect(pc.valueIndex, isNotNull);
    expect(console.valueIndex!, greaterThan(pc.valueIndex!));
  });

  test('performance score uses only player card fields', () {
    final result = analyzer.analyze(buildPlayer(ps: 50000));
    expect(result.faceStatAverage, greaterThan(0));
    expect(result.performanceScore, greaterThan(0));
    expect(result.valueIndex, greaterThan(0));
  });
}
