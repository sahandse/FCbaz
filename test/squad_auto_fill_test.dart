import 'package:flutter_test/flutter_test.dart';

import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/squad/domain/squad_auto_fill_service.dart';
import 'package:fcbaz/features/squad/domain/squad_models.dart';

Player player(
  String id, {
  String? name,
  required String position,
  List<String> positions = const [],
  int rating = 80,
}) {
  return Player(
    id: id,
    name: name ?? id,
    rating: rating,
    position: position,
    positions: positions,
    clubName: 'Club',
    leagueName: 'League',
    nationName: 'Nation',
    version: 'Gold Rare',
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
  const service = SquadAutoFillService();
  final formation = Formations.byId('433');
  const gkSlot = 'gk';
  const lbSlot = 'lb';
  const stSlot = 'st';

  test('fills every empty slot with the highest-rated fitting player', () {
    final current = {gkSlot: player('gk-owner', position: 'GK', rating: 70)};
    final catalog = [
      player('gk-owner', position: 'GK', rating: 99),
      player('gk-backup', position: 'GK', rating: 88),
      player('lb-low', position: 'LB', rating: 78),
      player('lb-high', position: 'LB', rating: 84),
      player('cb-1', position: 'CB', rating: 82),
      player('cb-2', position: 'CB', rating: 81),
      player('rb-1', position: 'RB', rating: 80),
      player('cm-1', position: 'CM', rating: 86),
      player('cm-2', position: 'CM', rating: 85),
      player('cm-3', position: 'CM', rating: 84),
      player('lw-1', position: 'LW', rating: 88),
      player('st-1', position: 'ST', rating: 90),
      player('rw-1', position: 'RW', rating: 83),
    ];

    final result = service.fillEmptySlots(
      formation: formation,
      current: current,
      catalog: catalog,
    );

    expect(result.filledCount, 10);
    expect(result.complete, isTrue);
    expect(result.unfilledPositions, isEmpty);
    expect(result.playersBySlot, hasLength(11));
    expect(result.playersBySlot[gkSlot]!.id, 'gk-owner');
    expect(result.playersBySlot[lbSlot]!.id, 'lb-high');
    expect(result.playersBySlot[stSlot]!.id, 'st-1');

    final ids = result.playersBySlot.values.map((p) => p.id).toList();
    expect(ids.toSet(), hasLength(ids.length));

    for (final slot in formation.slots) {
      final picked = result.playersBySlot[slot.id]!;
      final fits =
          picked.position == slot.position ||
          picked.positions.contains(slot.position);
      expect(fits, isTrue, reason: '${slot.position} got ${picked.name}');
    }
  });

  test('keeps existing players and never reuses an excluded bench player', () {
    final current = {'lst': player('st-owner', position: 'ST', rating: 77)};
    const formation442 = '442';
    final result = service.fillEmptySlots(
      formation: Formations.byId(formation442),
      current: current,
      catalog: [
        player('st-owner', position: 'ST', rating: 99),
        player('st-bench', position: 'ST', rating: 95),
        player('st-free', position: 'ST', rating: 80),
        player('gk-1', position: 'GK', rating: 80),
      ],
      excludedIds: {'st-bench'},
    );

    expect(result.playersBySlot['lst']!.id, 'st-owner');
    expect(result.playersBySlot['rst']!.id, 'st-free');
    expect(result.playersBySlot[gkSlot]!.id, 'gk-1');
    expect(
      result.playersBySlot.values.map((p) => p.id),
      isNot(contains('st-bench')),
    );
  });

  test('leaves out-of-position slots empty instead of inventing a fit', () {
    final result = service.fillEmptySlots(
      formation: formation,
      current: const {},
      catalog: [player('only-gk', position: 'GK', rating: 80)],
    );

    expect(result.filledCount, 1);
    expect(result.complete, isFalse);
    expect(result.playersBySlot.keys, [gkSlot]);
    expect(result.unfilledPositions, contains('ST'));
    expect(result.unfilledPositions, isNot(contains('GK')));
  });

  test('reports no fill when the catalog is empty', () {
    final result = service.fillEmptySlots(
      formation: formation,
      current: const {},
      catalog: const [],
    );

    expect(result.filledCount, 0);
    expect(result.playersBySlot, isEmpty);
    expect(result.unfilledPositions, hasLength(11));
    expect(result.consideredCandidates, 0);
  });

  test(
    'matches alternate positions and ignores incomplete catalog entries',
    () {
      final result = service.fillEmptySlots(
        formation: formation,
        current: const {},
        catalog: [
          player('no-name', position: 'GK', rating: 99, name: ''),
          player('', name: 'Bad Id', position: 'GK', rating: 99),
          player(
            'utility',
            position: 'CM',
            positions: const ['CDM', 'CAM'],
            rating: 79,
          ),
        ],
      );
      final pickedIds = result.playersBySlot.values.map((p) => p.id);
      expect(pickedIds, isNot(contains('no-name')));
      expect(pickedIds, isNot(contains('')));
      expect(pickedIds, contains('utility'));

      // The formation has three central midfield slots; one utility player can
      // only occupy one of them and must not be duplicated.
      final utilityCount = result.playersBySlot.values
          .where((p) => p.id == 'utility')
          .length;
      expect(utilityCount, 1);
    },
  );
}
