import 'package:flutter_test/flutter_test.dart';

import 'package:fcbaz/features/club/data/my_club_repository.dart';
import 'package:fcbaz/features/evolutions/domain/evolution.dart';
import 'package:fcbaz/features/evolutions/domain/evolution_projection.dart';

void main() {
  const engine = EvolutionProjectionEngine();
  const player = MyClubItem(
    playerId: '1',
    playerName: 'Test Player',
    rating: 84,
    position: 'CM',
    positions: ['CM'],
    clubName: 'Club',
    leagueName: 'League',
    nationName: 'Nation',
    version: 'Gold',
    imageUrl: '',
    pace: 80,
    shooting: 75,
    passing: 86,
    dribbling: 84,
    defending: 70,
    physical: 78,
    skillMoves: 4,
    weakFoot: 3,
    acquisitionPrice: 0,
    untradeable: true,
  );

  Evolution evo({List<Map<String, dynamic>> upgrades = const []}) => Evolution(
        id: 'evo',
        title: 'Evo',
        description: '',
        cost: 0,
        requirements: const [],
        requirementData: const [],
        upgrades: const [],
        upgradeData: upgrades,
        expiresAt: null,
        steps: const [],
      );

  test('does not invent projection when structured upgrades are missing', () {
    expect(engine.project(player, evo()), isNull);
  });

  test('applies explicit numeric deltas only', () {
    final result = engine.project(
      player,
      evo(upgrades: const [
        {'stat': 'pace', 'delta': 5},
        {'stat': 'passing', 'delta': 3},
      ]),
    );

    expect(result, isNotNull);
    expect(result!.before['pace'], 80);
    expect(result.after['pace'], 85);
    expect(result.after['passing'], 89);
    expect(result.changes['pace'], 5);
  });

  test('uses explicit final value without guessing other stats', () {
    final result = engine.project(
      player,
      evo(upgrades: const [
        {'stat': 'rating', 'operation': 'set', 'value': 87},
      ]),
    );

    expect(result, isNotNull);
    expect(result!.after['rating'], 87);
    expect(result.after['pace'], 80);
    expect(result.changes['rating'], 3);
    expect(result.changes['pace'], 0);
  });
}
