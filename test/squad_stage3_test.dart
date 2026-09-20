import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/squad/data/squad_repository.dart';
import 'package:fcbaz/features/squad/domain/chemistry_engine.dart';
import 'package:fcbaz/features/squad/domain/squad_models.dart';

Player p({
  required String id,
  required String name,
  required String position,
  required String club,
  required String league,
  required String nation,
  String version = 'Gold Rare',
}) {
  return Player(
    id: id,
    name: name,
    rating: 85,
    position: position,
    positions: const [],
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
  test('chemistry counts same club and caps at 3 per player', () {
    final formation = Formations.byId('433');
    final players = <String, Player>{
      'st': p(
        id: '1',
        name: 'A',
        position: 'ST',
        club: 'Club A',
        league: 'League A',
        nation: 'Nation A',
      ),
      'lw': p(
        id: '2',
        name: 'B',
        position: 'LW',
        club: 'Club A',
        league: 'League A',
        nation: 'Nation B',
      ),
      'rw': p(
        id: '3',
        name: 'C',
        position: 'RW',
        club: 'Club A',
        league: 'League A',
        nation: 'Nation C',
      ),
    };

    final result = const ChemistryEngineFC27().calculate(
      formation: formation,
      playersBySlot: players,
    );

    expect(result.bySlot['st'], greaterThanOrEqualTo(1));
    expect(result.bySlot.values.every((value) => value <= 3), isTrue);
  });

  test('out of position player gets zero chemistry', () {
    final formation = Formations.byId('433');
    final result = const ChemistryEngineFC27().calculate(
      formation: formation,
      playersBySlot: {
        'st': p(
          id: '1',
          name: 'A',
          position: 'CB',
          club: 'Club A',
          league: 'League A',
          nation: 'Nation A',
        ),
      },
    );

    expect(result.bySlot['st'], 0);
  });

  test('squad repository saves and restores squads', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SquadRepository();

    final squad = SquadStateModel(
      id: 's1',
      name: 'تیم تست',
      formationId: '433',
      playersBySlot: {
        'st': p(
          id: '1',
          name: 'A',
          position: 'ST',
          club: 'Club A',
          league: 'League A',
          nation: 'Nation A',
        ),
      },
    );

    await repository.upsert(squad);
    final loaded = await repository.getAll();

    expect(loaded, hasLength(1));
    expect(loaded.single.name, 'تیم تست');
    expect(loaded.single.playersBySlot['st']?.name, 'A');
  });
}
