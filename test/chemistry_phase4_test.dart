import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/squad/domain/chemistry_engine.dart';
import 'package:fcbaz/features/squad/domain/squad_models.dart';

Player makePlayer({
  required String id,
  required String position,
  String club = 'FCBaz Club',
  String league = 'FCBaz League',
  String nation = 'Iran',
  String version = 'Gold',
}) {
  return Player(
    id: id,
    name: 'Player $id',
    rating: 85,
    position: position,
    positions: [position],
    clubName: club,
    leagueName: league,
    nationName: nation,
    version: version,
    imageUrl: '',
    pace: 80,
    shooting: 80,
    passing: 80,
    dribbling: 80,
    defending: 80,
    physical: 80,
    skillMoves: 4,
    weakFoot: 4,
  );
}

void main() {
  const engine = ChemistryEngineFC27();
  final formation = Formations.byId('433');

  test('reports out-of-position players instead of silently treating them as valid', () {
    final result = engine.calculate(
      formation: formation,
      playersBySlot: {
        'gk': makePlayer(id: '1', position: 'ST'),
      },
    );

    expect(result.total, 0);
    expect(result.filledSlots, 1);
    expect(result.inPositionSlots, 0);
    expect(result.hasOutOfPositionPlayers, isTrue);
    expect(result.details['gk']?.inPosition, isFalse);
  });

  test('keeps per-slot chemistry diagnostics', () {
    final result = engine.calculate(
      formation: formation,
      playersBySlot: {
        'st': makePlayer(id: '1', position: 'ST'),
        'lw': makePlayer(id: '2', position: 'LW'),
        'rw': makePlayer(id: '3', position: 'RW'),
      },
      manager: const ManagerProfile(
        name: 'Manager',
        nationName: 'Iran',
        leagueName: '',
      ),
    );

    expect(result.filledSlots, 3);
    expect(result.inPositionSlots, 3);
    expect(result.details['st'], isNotNull);
    expect(result.details['st']!.clubCount, 3);
    expect(result.details['st']!.leagueCount, 3);
    expect(result.details['st']!.nationCount, 3);
    expect(result.details['st']!.managerMatch, isTrue);
  });

  test('normalizes position casing and surrounding spaces', () {
    final player = makePlayer(id: '1', position: 'st');
    final result = engine.calculate(
      formation: formation,
      playersBySlot: {'st': player},
    );

    expect(result.inPositionSlots, 1);
    expect(result.details['st']?.inPosition, isTrue);
  });
}
