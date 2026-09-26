import '../../players/domain/player.dart';
import 'squad_models.dart';

class ChemistrySlotDetail {
  const ChemistrySlotDetail({
    required this.slotId,
    required this.chemistry,
    required this.inPosition,
    required this.clubCount,
    required this.leagueCount,
    required this.nationCount,
    required this.managerMatch,
    required this.specialCard,
  });

  final String slotId;
  final int chemistry;
  final bool inPosition;
  final int clubCount;
  final int leagueCount;
  final int nationCount;
  final bool managerMatch;
  final bool specialCard;
}

class ChemistryResult {
  const ChemistryResult({
    required this.total,
    required this.bySlot,
    this.details = const {},
    this.filledSlots = 0,
    this.inPositionSlots = 0,
  });

  final int total;
  final Map<String, int> bySlot;
  final Map<String, ChemistrySlotDetail> details;
  final int filledSlots;
  final int inPositionSlots;

  int get maxForFilledPlayers => filledSlots * 3;
  int get missingChemistry => maxForFilledPlayers - total;
  bool get hasOutOfPositionPlayers => inPositionSlots < filledSlots;
}

class ChemistryEngineFC27 {
  const ChemistryEngineFC27();

  ChemistryResult calculate({
    required FormationDefinition formation,
    required Map<String, Player> playersBySlot,
    ManagerProfile? manager,
  }) {
    final eligible = <String, Player>{};
    var filledSlots = 0;

    for (final slot in formation.slots) {
      final player = playersBySlot[slot.id];
      if (player == null) continue;
      filledSlots++;
      if (_isInPosition(player, slot.position)) {
        eligible[slot.id] = player;
      }
    }

    final contributingPlayers = eligible.values.toList();
    final bySlot = <String, int>{};
    final details = <String, ChemistrySlotDetail>{};

    for (final slot in formation.slots) {
      final player = playersBySlot[slot.id];
      if (player == null) continue;

      final inPosition = eligible.containsKey(slot.id);
      if (!inPosition) {
        bySlot[slot.id] = 0;
        details[slot.id] = ChemistrySlotDetail(
          slotId: slot.id,
          chemistry: 0,
          inPosition: false,
          clubCount: 0,
          leagueCount: 0,
          nationCount: 0,
          managerMatch: false,
          specialCard: false,
        );
        continue;
      }

      final special = _isIcon(player) || _isHero(player) || _isHallOfFut(player);
      final club = _weightedClubCount(player, contributingPlayers);
      final league = _weightedLeagueCount(player, contributingPlayers);
      final nation = _weightedNationCount(player, contributingPlayers);
      final managerMatched = _managerMatch(player, manager);

      var chemistry = 0;
      if (special) {
        chemistry = 3;
      } else {
        chemistry += _points(club, const [2, 4, 7]);
        chemistry += _points(league, const [3, 5, 8]);
        chemistry += _points(nation, const [2, 5, 8]);
        if (managerMatched) chemistry += 1;
        chemistry = chemistry.clamp(0, 3);
      }

      bySlot[slot.id] = chemistry;
      details[slot.id] = ChemistrySlotDetail(
        slotId: slot.id,
        chemistry: chemistry,
        inPosition: true,
        clubCount: club,
        leagueCount: league,
        nationCount: nation,
        managerMatch: managerMatched,
        specialCard: special,
      );
    }

    final total = bySlot.values.fold<int>(0, (sum, value) => sum + value);
    return ChemistryResult(
      total: total,
      bySlot: bySlot,
      details: details,
      filledSlots: filledSlots,
      inPositionSlots: eligible.length,
    );
  }

  bool _managerMatch(Player player, ManagerProfile? manager) {
    if (manager == null) return false;

    final leagueMatch = _same(manager.leagueName, player.leagueName);
    final nationMatch = _same(manager.nationName, player.nationName);
    return leagueMatch || nationMatch;
  }

  bool _isInPosition(Player player, String slotPosition) {
    final target = slotPosition.trim().toUpperCase();
    if (player.position.trim().toUpperCase() == target) return true;
    return player.positions.any((p) => p.trim().toUpperCase() == target);
  }

  int _points(int count, List<int> thresholds) {
    var points = 0;
    for (final threshold in thresholds) {
      if (count >= threshold) points++;
    }
    return points;
  }

  int _weightedClubCount(Player target, List<Player> players) {
    return players.where((p) => _same(p.clubName, target.clubName)).length;
  }

  int _weightedLeagueCount(Player target, List<Player> players) {
    var count = players.where((p) => _same(p.leagueName, target.leagueName)).length;

    for (final player in players) {
      if (_isIcon(player)) {
        count += 1;
      } else if ((_isHero(player) || _isHallOfFut(player)) &&
          _same(player.leagueName, target.leagueName)) {
        count += 1;
      }
    }

    return count;
  }

  int _weightedNationCount(Player target, List<Player> players) {
    var count = players.where((p) => _same(p.nationName, target.nationName)).length;

    for (final player in players) {
      if ((_isIcon(player) || _isHero(player) || _isHallOfFut(player)) &&
          _same(player.nationName, target.nationName)) {
        count += 1;
      }
    }

    return count;
  }

  bool _same(String a, String b) {
    final left = a.trim().toLowerCase();
    final right = b.trim().toLowerCase();
    return left.isNotEmpty && right.isNotEmpty && left == right;
  }

  bool _isIcon(Player player) => player.version.toLowerCase().contains('icon');

  bool _isHero(Player player) => player.version.toLowerCase().contains('hero');

  bool _isHallOfFut(Player player) {
    final version = player.version.toLowerCase();
    return version.contains('hall of fut') || version.contains('halloffut');
  }
}
