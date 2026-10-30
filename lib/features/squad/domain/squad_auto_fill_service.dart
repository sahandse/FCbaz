import '../../players/domain/player.dart';
import 'chemistry_engine.dart';
import 'squad_chemistry_optimizer.dart';
import 'squad_models.dart';

class SquadAutoFillResult {
  const SquadAutoFillResult({
    required this.playersBySlot,
    required this.filledSlotIds,
    required this.unfilledPositions,
    required this.consideredCandidates,
  });

  final Map<String, Player> playersBySlot;
  final List<String> filledSlotIds;
  final List<String> unfilledPositions;
  final int consideredCandidates;

  int get filledCount => filledSlotIds.length;
  bool get complete => unfilledPositions.isEmpty;
}

/// Fills only empty slots with real catalog players who fit the slot position.
/// Slots without a fitting player stay empty instead of receiving a filler.
class SquadAutoFillService {
  const SquadAutoFillService({
    this.optimizer = const SquadChemistryOptimizer(),
    this.engine = const ChemistryEngineFC27(),
  });

  final SquadChemistryOptimizer optimizer;
  final ChemistryEngineFC27 engine;

  SquadAutoFillResult fillEmptySlots({
    required FormationDefinition formation,
    required Map<String, Player> current,
    required List<Player> catalog,
    ManagerProfile? manager,
    Set<String> excludedIds = const {},
  }) {
    final usedIds = <String>{
      ...current.values.map((p) => p.id),
      ...excludedIds,
    };
    final candidates = catalog
        .where(
          (p) =>
              p.id.isNotEmpty && p.name.isNotEmpty && !usedIds.contains(p.id),
        )
        .toList();

    bool fits(Player player, String position) {
      final target = position.toUpperCase();
      return player.position.toUpperCase() == target ||
          player.positions.any((alt) => alt.toUpperCase() == target);
    }

    final players = Map<String, Player>.from(current);
    final filledSlotIds = <String>[];
    final unfilledPositions = <String>[];

    for (final slot in formation.slots) {
      if (players.containsKey(slot.id)) continue;

      final fitting = candidates
          .where((p) => !usedIds.contains(p.id) && fits(p, slot.position))
          .toList();
      if (fitting.isEmpty) {
        unfilledPositions.add(slot.position);
        continue;
      }

      fitting.sort((a, b) {
        final byRating = b.rating.compareTo(a.rating);
        return byRating != 0 ? byRating : a.name.compareTo(b.name);
      });

      final pick = fitting.first;
      players[slot.id] = pick;
      usedIds.add(pick.id);
      filledSlotIds.add(slot.id);
    }

    final filled = players.length == formation.slots.length
        ? optimizer
              .optimize(
                formation: formation,
                current: players,
                engine: engine,
                manager: manager,
              )
              .playersBySlot
        : players;

    return SquadAutoFillResult(
      playersBySlot: filled,
      filledSlotIds: filledSlotIds,
      unfilledPositions: unfilledPositions,
      consideredCandidates: candidates.length,
    );
  }
}
