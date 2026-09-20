import '../../players/domain/player.dart';
import 'chemistry_engine.dart';
import 'squad_models.dart';

class SquadOptimizationResult {
  const SquadOptimizationResult({required this.playersBySlot, required this.chemistry});
  final Map<String, Player> playersBySlot;
  final ChemistryResult chemistry;
}

class SquadChemistryOptimizer {
  const SquadChemistryOptimizer();

  SquadOptimizationResult optimize({
    required FormationDefinition formation,
    required Map<String, Player> current,
    required ChemistryEngineFC27 engine,
    ManagerProfile? manager,
  }) {
    final players = current.values.toList();
    if (players.length != formation.slots.length) {
      return SquadOptimizationResult(
        playersBySlot: current,
        chemistry: engine.calculate(
          formation: formation,
          playersBySlot: current,
          manager: manager,
        ),
      );
    }

    var best = Map<String, Player>.from(current);
    var bestChem = engine.calculate(
      formation: formation,
      playersBySlot: best,
      manager: manager,
    );

    bool improved = true;
    var rounds = 0;
    while (improved && rounds < 8) {
      improved = false;
      rounds++;
      final slots = formation.slots.map((e) => e.id).toList();

      for (var i = 0; i < slots.length; i++) {
        for (var j = i + 1; j < slots.length; j++) {
          final a = best[slots[i]];
          final b = best[slots[j]];
          if (a == null || b == null) continue;

          final candidate = Map<String, Player>.from(best)
            ..[slots[i]] = b
            ..[slots[j]] = a;

          final chemistry = engine.calculate(
            formation: formation,
            playersBySlot: candidate,
            manager: manager,
          );

          if (_score(formation, candidate, chemistry) >
              _score(formation, best, bestChem)) {
            best = candidate;
            bestChem = chemistry;
            improved = true;
          }
        }
      }
    }

    return SquadOptimizationResult(playersBySlot: best, chemistry: bestChem);
  }

  int _score(
    FormationDefinition formation,
    Map<String, Player> players,
    ChemistryResult chemistry,
  ) {
    var inPosition = 0;
    var roleFit = 0;
    for (final slot in formation.slots) {
      final p = players[slot.id];
      if (p == null) continue;
      final fit = p.position == slot.position || p.positions.contains(slot.position);
      if (fit) inPosition++;
      roleFit += _roleScore(p, slot.position);
    }
    return chemistry.total * 1000000 + inPosition * 10000 + roleFit;
  }

  int _roleScore(Player p, String position) {
    if (position == 'GK') return p.rating;
    if (position == 'CB') return p.defending * 5 + p.physical * 3 + p.pace;
    if (position == 'LB' || position == 'RB') {
      return p.pace * 3 + p.defending * 3 + p.passing * 2;
    }
    if (position == 'CDM') return p.defending * 4 + p.physical * 2 + p.passing * 3;
    if (position == 'CM') return p.passing * 4 + p.dribbling * 2 + p.physical + p.defending;
    if (position == 'CAM') return p.passing * 4 + p.dribbling * 4 + p.shooting * 2;
    if (position == 'LM' || position == 'RM' || position == 'LW' || position == 'RW') {
      return p.pace * 4 + p.dribbling * 3 + p.passing * 2 + p.shooting;
    }
    return p.shooting * 4 + p.pace * 3 + p.dribbling * 2 + p.physical;
  }
}