import '../../players/domain/player.dart';
import 'squad_models.dart';

class ChemistryResult {
  const ChemistryResult({
    required this.total,
    required this.bySlot,
  });

  final int total;
  final Map<String, int> bySlot;
}

class ChemistryEngineFC27 {
  const ChemistryEngineFC27();

  ChemistryResult calculate({
    required FormationDefinition formation,
    required Map<String, Player> playersBySlot,
    ManagerProfile? manager,
  }) {
    final eligible = <String, Player>{};

    for (final slot in formation.slots) {
      final player = playersBySlot[slot.id];
      if (player == null) continue;
      if (_isInPosition(player, slot.position)) {
        eligible[slot.id] = player;
      }
    }

    final contributingPlayers = eligible.values.toList();
    final bySlot = <String, int>{};

    for (final slot in formation.slots) {
      final player = playersBySlot[slot.id];
      if (player == null) continue;

      if (!eligible.containsKey(slot.id)) {
        bySlot[slot.id] = 0;
        continue;
      }

      if (_isIcon(player) || _isHero(player) || _isHallOfFut(player)) {
        bySlot[slot.id] = 3;
        continue;
      }

      final club = _weightedClubCount(player, contributingPlayers);
      final league = _weightedLeagueCount(player, contributingPlayers);
      final nation = _weightedNationCount(player, contributingPlayers);

      var chemistry = 0;
      chemistry += _points(club, const [2, 4, 7]);
      chemistry += _points(league, const [3, 5, 8]);
      chemistry += _points(nation, const [2, 5, 8]);

      if (_managerMatch(player, manager)) {
        chemistry += 1;
      }

      bySlot[slot.id] = chemistry.clamp(0, 3);
    }

    final total = bySlot.values.fold<int>(0, (sum, value) => sum + value);
    return ChemistryResult(total: total, bySlot: bySlot);
  }

  bool _managerMatch(Player player, ManagerProfile? manager) {
    if (manager == null) return false;

    final leagueMatch = manager.leagueName.isNotEmpty &&
        player.leagueName.isNotEmpty &&
        manager.leagueName.toLowerCase() == player.leagueName.toLowerCase();

    final nationMatch = manager.nationName.isNotEmpty &&
        player.nationName.isNotEmpty &&
        manager.nationName.toLowerCase() == player.nationName.toLowerCase();

    return leagueMatch || nationMatch;
  }

  bool _isInPosition(Player player, String slotPosition) {
    return player.position == slotPosition ||
        player.positions.contains(slotPosition);
  }

  int _points(int count, List<int> thresholds) {
    var points = 0;
    for (final threshold in thresholds) {
      if (count >= threshold) points++;
    }
    return points;
  }

  int _weightedClubCount(Player target, List<Player> players) {
    return players
        .where(
          (p) =>
              p.clubName.isNotEmpty &&
              p.clubName.toLowerCase() == target.clubName.toLowerCase(),
        )
        .length;
  }

  int _weightedLeagueCount(Player target, List<Player> players) {
    var count = players
        .where(
          (p) =>
              p.leagueName.isNotEmpty &&
              p.leagueName.toLowerCase() == target.leagueName.toLowerCase(),
        )
        .length;

    for (final player in players) {
      if (_isIcon(player)) {
        count += 1;
      } else if ((_isHero(player) || _isHallOfFut(player)) &&
          player.leagueName.toLowerCase() == target.leagueName.toLowerCase()) {
        count += 1;
      }
    }

    return count;
  }

  int _weightedNationCount(Player target, List<Player> players) {
    var count = players
        .where(
          (p) =>
              p.nationName.isNotEmpty &&
              p.nationName.toLowerCase() == target.nationName.toLowerCase(),
        )
        .length;

    for (final player in players) {
      if ((_isIcon(player) || _isHero(player) || _isHallOfFut(player)) &&
          player.nationName.toLowerCase() == target.nationName.toLowerCase()) {
        count += 1;
      }
    }

    return count;
  }

  bool _isIcon(Player player) =>
      player.version.toLowerCase().contains('icon');

  bool _isHero(Player player) =>
      player.version.toLowerCase().contains('hero');

  bool _isHallOfFut(Player player) {
    final version = player.version.toLowerCase();
    return version.contains('hall of fut') ||
        version.contains('halloffut');
  }
}
