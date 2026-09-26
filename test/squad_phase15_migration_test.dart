import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/squad/domain/squad_formation_migrator.dart';
import 'package:fcbaz/features/squad/domain/squad_models.dart';

Player player(String id, String position, {List<String> positions = const []}) => Player(
      id: id,
      name: 'Player $id',
      rating: 90,
      position: position,
      positions: positions,
      clubName: 'Club',
      leagueName: 'League',
      nationName: 'Nation',
      version: 'Gold',
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

void main() {
  const migrator = SquadFormationMigrator();

  test('formation migration never silently drops starters', () {
    final from = Formations.byId('433');
    final to = Formations.byId('4231');
    final players = <String, Player>{};
    for (final slot in from.slots) {
      players[slot.id] = player(slot.id, slot.position);
    }

    final squad = SquadStateModel(
      id: '1',
      name: 'Test',
      formationId: from.id,
      playersBySlot: players,
    );

    final result = migrator.migrate(squad: squad, from: from, to: to);
    final ids = <String>{
      ...result.playersBySlot.values.map((p) => p.id),
      ...result.bench.map((p) => p.id),
    };

    expect(ids.length, players.length);
    expect(result.playersBySlot.length + result.bench.length, players.length);
  });

  test('player config follows a player when compatible slot changes', () {
    final from = Formations.byId('433');
    final to = Formations.byId('433a');
    final cm = player('cm-player', 'CM');
    final squad = SquadStateModel(
      id: '2',
      name: 'Config',
      formationId: from.id,
      playersBySlot: {'cm': cm},
      playerConfigs: const {
        'cm': SquadPlayerConfig(role: 'Playmaker'),
      },
    );

    final result = migrator.migrate(squad: squad, from: from, to: to);
    final slot = result.playersBySlot.entries
        .firstWhere((entry) => entry.value.id == cm.id)
        .key;

    expect(result.playerConfigs[slot]?.role, 'Playmaker');
  });
}
