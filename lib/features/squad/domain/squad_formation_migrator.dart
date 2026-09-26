import '../../players/domain/player.dart';
import 'squad_models.dart';

class FormationMigrationResult {
  const FormationMigrationResult({
    required this.playersBySlot,
    required this.playerConfigs,
    required this.bench,
    required this.movedToBench,
    required this.outOfPositionPlacements,
  });

  final Map<String, Player> playersBySlot;
  final Map<String, SquadPlayerConfig> playerConfigs;
  final List<Player> bench;
  final int movedToBench;
  final int outOfPositionPlacements;
}

class SquadFormationMigrator {
  const SquadFormationMigrator();

  FormationMigrationResult migrate({
    required SquadStateModel squad,
    required FormationDefinition from,
    required FormationDefinition to,
  }) {
    final placed = <String, Player>{};
    final configs = <String, SquadPlayerConfig>{};
    final remaining = <_SourcePlayer>[];

    for (final entry in squad.playersBySlot.entries) {
      final player = entry.value;
      final oldSlot = from.slots.where((s) => s.id == entry.key).firstOrNull;
      remaining.add(_SourcePlayer(
        oldSlotId: entry.key,
        oldPosition: oldSlot?.position ?? player.position,
        player: player,
        config: squad.playerConfigs[entry.key],
      ));
    }

    // 1) Preserve exact slot IDs only when the player is compatible with the
    // destination position. This keeps stable layouts without preserving a
    // player in an invalid role by accident.
    for (final target in to.slots) {
      final index = remaining.indexWhere(
        (source) =>
            source.oldSlotId == target.id &&
            _canPlay(source.player, target.position),
      );
      if (index < 0) continue;
      _place(target.id, remaining.removeAt(index), placed, configs);
    }

    // 2) Place every remaining player into a compatible destination slot.
    for (final target in to.slots.where((s) => !placed.containsKey(s.id))) {
      final index = remaining.indexWhere(
        (source) => _canPlay(source.player, target.position),
      );
      if (index < 0) continue;
      _place(target.id, remaining.removeAt(index), placed, configs);
    }

    // 3) Prefer the bench for players who genuinely do not fit the new shape.
    final bench = <Player>[...squad.bench];
    var movedToBench = 0;
    while (remaining.isNotEmpty && bench.length < 7) {
      final source = remaining.removeAt(0);
      if (!bench.any((p) => p.id == source.player.id)) {
        bench.add(source.player);
        movedToBench++;
      }
    }

    // 4) Never silently lose a player. If the bench is full, keep remaining
    // players in open formation slots and let Chemistry Diagnostics flag them
    // as out of position.
    var outOfPosition = 0;
    for (final target in to.slots.where((s) => !placed.containsKey(s.id))) {
      if (remaining.isEmpty) break;
      final source = remaining.removeAt(0);
      _place(target.id, source, placed, configs);
      outOfPosition++;
    }

    return FormationMigrationResult(
      playersBySlot: placed,
      playerConfigs: configs,
      bench: bench.take(7).toList(),
      movedToBench: movedToBench,
      outOfPositionPlacements: outOfPosition,
    );
  }

  void _place(
    String slotId,
    _SourcePlayer source,
    Map<String, Player> players,
    Map<String, SquadPlayerConfig> configs,
  ) {
    players[slotId] = source.player;
    if (source.config != null) configs[slotId] = source.config!;
  }

  bool _canPlay(Player player, String target) {
    final normalized = target.trim().toUpperCase();
    final positions = <String>{
      player.position.trim().toUpperCase(),
      ...player.positions.map((p) => p.trim().toUpperCase()),
    }..removeWhere((p) => p.isEmpty);
    return positions.contains(normalized);
  }
}

class _SourcePlayer {
  const _SourcePlayer({
    required this.oldSlotId,
    required this.oldPosition,
    required this.player,
    required this.config,
  });

  final String oldSlotId;
  final String oldPosition;
  final Player player;
  final SquadPlayerConfig? config;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
