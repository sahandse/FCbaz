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

  test('out of position player gets zero and does not contribute', () {
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
        'lw': p(
          id: '2',
          name: 'B',
          position: 'LW',
          club: 'Club A',
          league: 'League B',
          nation: 'Nation B',
        ),
      },
    );

    expect(result.bySlot['st'], 0);
    expect(result.bySlot['lw'], 0);
  });

  test('manager matching league adds chemistry up to max 3', () {
    final formation = Formations.byId('433');
    final result = const ChemistryEngineFC27().calculate(
      formation: formation,
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
      manager: const ManagerProfile(
        name: 'Manager',
        nationName: 'Nation Z',
        leagueName: 'League A',
      ),
    );

    expect(result.bySlot['st'], 1);
  });

  test('squad repository saves advanced squad fields', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SquadRepository();

    final starter = p(
      id: '1',
      name: 'A',
      position: 'ST',
      club: 'Club A',
      league: 'League A',
      nation: 'Nation A',
    );
    final bench = p(
      id: '2',
      name: 'B',
      position: 'LW',
      club: 'Club B',
      league: 'League B',
      nation: 'Nation B',
    );

    final squad = SquadStateModel(
      id: 's1',
      name: 'تیم تست',
      formationId: '433',
      playersBySlot: {'st': starter},
      playerConfigs: const {
        'st': SquadPlayerConfig(
          chemistryStyle: 'Hunter',
          role: 'Advanced Forward++',
          focus: 'Attack',
        ),
      },
      bench: [bench],
      manager: const ManagerProfile(
        name: 'Manager',
        nationName: 'Nation A',
        leagueName: 'League A',
      ),
    );

    await repository.upsert(squad);
    final loaded = await repository.getAll();

    expect(loaded, hasLength(1));
    expect(loaded.single.name, 'تیم تست');
    expect(loaded.single.playersBySlot['st']?.name, 'A');
    expect(loaded.single.playerConfigs['st']?.chemistryStyle, 'Hunter');
    expect(loaded.single.bench.single.name, 'B');
    expect(loaded.single.manager?.leagueName, 'League A');
  });

  test('squad export and import preserve usable data', () {
    final repository = SquadRepository();
    final squad = SquadStateModel(
      id: 's1',
      name: 'Export Test',
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
      bench: [
        p(
          id: '2',
          name: 'B',
          position: 'LW',
          club: 'Club B',
          league: 'League B',
          nation: 'Nation B',
        ),
      ],
    );

    final raw = repository.exportSquad(squad);
    final imported = repository.importSquad(raw);

    expect(imported.id, isNot('s1'));
    expect(imported.formationId, '433');
    expect(imported.playersBySlot['st']?.name, 'A');
    expect(imported.bench.single.name, 'B');
  });
}
