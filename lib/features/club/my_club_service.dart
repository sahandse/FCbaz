import '../../core/network/fcbaz_api.dart';
import '../squad/domain/chemistry_engine.dart';
import '../squad/domain/squad_models.dart';
import 'data/my_club_repository.dart';

class ClubPlayerValue {
  const ClubPlayerValue({
    required this.item,
    required this.currentPrice,
  });

  final MyClubItem item;
  final int? currentPrice;

  int? get profitLoss {
    if (item.untradeable || currentPrice == null || item.acquisitionPrice <= 0) {
      return null;
    }
    return currentPrice! - item.acquisitionPrice;
  }
}

class ClubValuation {
  const ClubValuation({
    required this.players,
    required this.totalMarketValue,
    required this.tradeableMarketValue,
    required this.totalInvestment,
    required this.realizedComparableProfitLoss,
  });

  final List<ClubPlayerValue> players;
  final int totalMarketValue;
  final int tradeableMarketValue;
  final int totalInvestment;
  final int realizedComparableProfitLoss;
}

class BestClubSquad {
  const BestClubSquad({
    required this.formation,
    required this.playersBySlot,
    required this.chemistry,
    required this.averageRating,
  });

  final FormationDefinition formation;
  final Map<String, MyClubItem> playersBySlot;
  final ChemistryResult chemistry;
  final double averageRating;
}

class MyClubService {
  MyClubService({
    FCBazApi? api,
    ChemistryEngineFC27? chemistryEngine,
  })  : api = api ?? FCBazApi(),
        chemistryEngine = chemistryEngine ?? const ChemistryEngineFC27();

  final FCBazApi api;
  final ChemistryEngineFC27 chemistryEngine;

  Future<ClubValuation> valueClub(
    List<MyClubItem> items, {
    String platform = 'console',
    bool forceRefresh = false,
  }) async {
    if (items.isEmpty) {
      return const ClubValuation(
        players: [],
        totalMarketValue: 0,
        tradeableMarketValue: 0,
        totalInvestment: 0,
        realizedComparableProfitLoss: 0,
      );
    }

    final ids = items.map((e) => e.playerId).join(',');
    final platformParam = platform == 'pc' ? 'pc' : 'ps';
    final json = await api.getJson(
      '/api/v1/club/snapshot?player_ids=' +
          Uri.encodeQueryComponent(ids) +
          '&platform=' +
          platformParam,
      forceRefresh: forceRefresh,
      cacheTtl: const Duration(seconds: 45),
    );

    final raw = json is Map ? (json['data'] ?? const []) : json;
    if (raw is! List) {
      throw const FCBazApiException('ارزش لحظه‌ای باشگاه معتبر نیست.');
    }

    final prices = <String, int?>{};
    for (final row in raw.whereType<Map>()) {
      final id = (row['player_id'] ?? '').toString();
      final value = row['price'];
      prices[id] = value == null
          ? null
          : (value is int ? value : int.tryParse(value.toString()));
    }

    final valued = items
        .map((item) => ClubPlayerValue(
              item: item,
              currentPrice: prices[item.playerId],
            ))
        .toList();

    var total = 0;
    var tradeable = 0;
    var investment = 0;
    var profitLoss = 0;

    for (final value in valued) {
      final price = value.currentPrice;
      if (price != null && price > 0) {
        total += price;
        if (!value.item.untradeable) tradeable += price;
      }

      if (!value.item.untradeable && value.item.acquisitionPrice > 0) {
        investment += value.item.acquisitionPrice;
        if (value.profitLoss != null) profitLoss += value.profitLoss!;
      }
    }

    return ClubValuation(
      players: valued,
      totalMarketValue: total,
      tradeableMarketValue: tradeable,
      totalInvestment: investment,
      realizedComparableProfitLoss: profitLoss,
    );
  }

  BestClubSquad? buildBestSquad(List<MyClubItem> items) {
    if (items.length < 11) return null;

    BestClubSquad? best;
    var bestScore = -1e18;

    for (final formation in Formations.all) {
      final remaining = [...items];
      final selected = <String, MyClubItem>{};

      for (final slot in formation.slots) {
        MyClubItem? pick;
        var pickScore = -1e18;

        for (final item in remaining) {
          final score = _slotScore(item, slot.position);
          if (score > pickScore) {
            pickScore = score;
            pick = item;
          }
        }

        if (pick != null) {
          selected[slot.id] = pick;
          remaining.removeWhere((e) => e.playerId == pick!.playerId);
        }
      }

      if (selected.length != 11) continue;

      final typedPlayers = {
        for (final entry in selected.entries)
          entry.key: entry.value.toPlayer(),
      };

      final chemistry = chemistryEngine.calculate(
        formation: formation,
        playersBySlot: typedPlayers,
      );

      final avg = selected.values
              .map((e) => e.rating)
              .fold<int>(0, (sum, value) => sum + value) /
          11.0;

      final positionalFit = selected.entries.fold<double>(
        0,
        (sum, entry) {
          final slot = formation.slots.firstWhere((s) => s.id == entry.key);
          return sum + (_isInPosition(entry.value, slot.position) ? 1 : 0);
        },
      );

      final score = chemistry.total * 100000 +
          positionalFit * 10000 +
          avg * 100 +
          selected.entries.fold<double>(
            0,
            (sum, entry) {
              final slot = formation.slots.firstWhere((s) => s.id == entry.key);
              return sum + _roleScore(entry.value, slot.position);
            },
          );

      if (score > bestScore) {
        bestScore = score;
        best = BestClubSquad(
          formation: formation,
          playersBySlot: selected,
          chemistry: chemistry,
          averageRating: avg,
        );
      }
    }

    return best;
  }

  bool _isInPosition(MyClubItem item, String slot) =>
      item.position == slot || item.positions.contains(slot);

  double _slotScore(MyClubItem item, String slot) {
    final fit = _isInPosition(item, slot) ? 1 : 0;
    return fit * 100000 + item.rating * 1000 + _roleScore(item, slot);
  }

  double _roleScore(MyClubItem item, String slot) {
    if (slot == 'GK') return (item.rating * 10).toDouble();
    if (slot == 'CB') {
      return (item.defending * 6 + item.physical * 4 + item.pace * 2).toDouble();
    }
    if (slot == 'LB' || slot == 'RB') {
      return (item.pace * 4 +
          item.defending * 4 +
          item.passing * 2 +
          item.physical * 2).toDouble();
    }
    if (slot == 'CDM') {
      return (item.defending * 4 +
          item.physical * 3 +
          item.passing * 3 +
          item.dribbling).toDouble();
    }
    if (slot == 'CM') {
      return (item.passing * 4 +
          item.dribbling * 3 +
          item.physical * 2 +
          item.defending * 2 +
          item.shooting).toDouble();
    }
    if (slot == 'CAM') {
      return (item.passing * 4 +
          item.dribbling * 4 +
          item.shooting * 3 +
          item.pace).toDouble();
    }
    if (slot == 'LW' || slot == 'RW' || slot == 'LM' || slot == 'RM') {
      return (item.pace * 4 +
          item.dribbling * 4 +
          item.passing * 2 +
          item.shooting * 2).toDouble();
    }
    return (item.shooting * 4 +
        item.pace * 3 +
        item.dribbling * 2 +
        item.physical * 2).toDouble();
  }
}
