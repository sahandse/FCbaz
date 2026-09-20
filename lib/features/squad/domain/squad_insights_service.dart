import '../../players/data/player_repository.dart';
import '../../players/domain/player.dart';
import 'chemistry_engine.dart';
import 'squad_models.dart';

class SquadWeakness {
  const SquadWeakness({
    required this.title,
    required this.detail,
    required this.severity,
    this.slotId,
  });

  final String title;
  final String detail;
  final int severity;
  final String? slotId;
}

class SquadReplacementSuggestion {
  const SquadReplacementSuggestion({
    required this.slotId,
    required this.currentPlayer,
    required this.replacement,
    required this.currentScore,
    required this.replacementScore,
    required this.price,
  });

  final String slotId;
  final Player currentPlayer;
  final Player replacement;
  final double currentScore;
  final double replacementScore;
  final int price;

  double get scoreGain => replacementScore - currentScore;
}

class SquadInsights {
  const SquadInsights({
    required this.metaScore,
    required this.attackScore,
    required this.midfieldScore,
    required this.defenseScore,
    required this.averageRating,
    required this.playStylesPlusCount,
    required this.roleConfiguredCount,
    required this.weaknesses,
  });

  final double metaScore;
  final double attackScore;
  final double midfieldScore;
  final double defenseScore;
  final double averageRating;
  final int playStylesPlusCount;
  final int roleConfiguredCount;
  final List<SquadWeakness> weaknesses;
}

class SquadInsightsService {
  SquadInsightsService({PlayerRepository? playerRepository})
      : playerRepository = playerRepository ?? PlayerRepository();

  final PlayerRepository playerRepository;

  SquadInsights analyze({
    required SquadStateModel squad,
    required FormationDefinition formation,
    required ChemistryResult chemistry,
  }) {
    final players = squad.playersBySlot.values.toList();

    if (players.isEmpty) {
      return const SquadInsights(
        metaScore: 0,
        attackScore: 0,
        midfieldScore: 0,
        defenseScore: 0,
        averageRating: 0,
        playStylesPlusCount: 0,
        roleConfiguredCount: 0,
        weaknesses: [
          SquadWeakness(
            title: 'ترکیب خالی است',
            detail: 'برای تحلیل Squad بازیکن اضافه کن.',
            severity: 3,
          ),
        ],
      );
    }

    final attackScores = <double>[];
    final midfieldScores = <double>[];
    final defenseScores = <double>[];
    final weaknesses = <SquadWeakness>[];

    var totalMeta = 0.0;
    var roleConfigured = 0;
    var plusCount = 0;

    for (final slot in formation.slots) {
      final player = squad.playersBySlot[slot.id];
      if (player == null) {
        weaknesses.add(SquadWeakness(
          title: 'جای خالی در ' + slot.position,
          detail: 'این پست هنوز بازیکن ندارد.',
          severity: 3,
          slotId: slot.id,
        ));
        continue;
      }

      final chemistryValue = chemistry.bySlot[slot.id] ?? 0;
      final config = squad.playerConfigs[slot.id];
      final score = playerMetaScore(
        player,
        slot.position,
        chemistry: chemistryValue,
        selectedRole: config?.role ?? '',
      );
      totalMeta += score;

      plusCount += player.playStylesPlus.length;
      if (config != null && config.role.isNotEmpty) roleConfigured++;

      if (!_inPosition(player, slot.position)) {
        weaknesses.add(SquadWeakness(
          title: 'Out of Position',
          detail: player.name + ' در ' + slot.position + ' Chemistry صفر می‌گیرد.',
          severity: 4,
          slotId: slot.id,
        ));
      } else if (chemistryValue == 0) {
        weaknesses.add(SquadWeakness(
          title: 'Chemistry پایین',
          detail: player.name + ' در حال حاضر 0 Chemistry دارد.',
          severity: 3,
          slotId: slot.id,
        ));
      } else if (chemistryValue == 1) {
        weaknesses.add(SquadWeakness(
          title: 'Chemistry قابل بهبود',
          detail: player.name + ' فقط 1 Chemistry دارد.',
          severity: 2,
          slotId: slot.id,
        ));
      }

      if (player.roles.isNotEmpty &&
          (config == null || config.role.isEmpty)) {
        weaknesses.add(SquadWeakness(
          title: 'Role انتخاب نشده',
          detail: player.name + ' Role واقعی دارد ولی برای Squad تنظیم نشده است.',
          severity: 1,
          slotId: slot.id,
        ));
      }

      if (_isAttack(slot.position)) {
        attackScores.add(_attackScore(player));
      } else if (_isDefense(slot.position)) {
        defenseScores.add(_defenseScore(player));
      } else {
        midfieldScores.add(_midfieldScore(player));
      }
    }

    if (chemistry.total < 22 && squad.playersBySlot.length == 11) {
      weaknesses.add(SquadWeakness(
        title: 'Chemistry کلی پایین',
        detail: 'Chemistry فعلی ' + chemistry.total.toString() + '/33 است.',
        severity: 3,
      ));
    }

    if (plusCount == 0 && players.length >= 8) {
      weaknesses.add(const SquadWeakness(
        title: 'PlayStyles+ محدود',
        detail: 'Starting XI هیچ PlayStyle+ ثبت‌شده‌ای در داده فعلی ندارد.',
        severity: 1,
      ));
    }

    weaknesses.sort((a, b) => b.severity.compareTo(a.severity));

    final averageRating =
        players.fold<int>(0, (sum, p) => sum + p.rating) / players.length;

    final completionFactor = squad.playersBySlot.length / 11.0;
    final chemistryFactor = chemistry.total / 33.0;
    final averagePlayerMeta = totalMeta / players.length;

    final squadMeta = (
      averagePlayerMeta * .68 +
      chemistryFactor * 100 * .22 +
      completionFactor * 100 * .10
    ).clamp(0, 100).toDouble();

    return SquadInsights(
      metaScore: squadMeta,
      attackScore: _average(attackScores),
      midfieldScore: _average(midfieldScores),
      defenseScore: _average(defenseScores),
      averageRating: averageRating,
      playStylesPlusCount: plusCount,
      roleConfiguredCount: roleConfigured,
      weaknesses: weaknesses.take(8).toList(),
    );
  }

  Future<List<SquadReplacementSuggestion>> replacementSuggestions({
    required SquadStateModel squad,
    required FormationDefinition formation,
    required ChemistryResult chemistry,
    required int maxBudget,
    String platform = 'console',
    int maxSlots = 3,
  }) async {
    if (maxBudget <= 0) return const [];

    final scored = <({FormationSlot slot, Player player, double score})>[];

    for (final slot in formation.slots) {
      final player = squad.playersBySlot[slot.id];
      if (player == null) continue;
      final config = squad.playerConfigs[slot.id];

      scored.add((
        slot: slot,
        player: player,
        score: playerMetaScore(
          player,
          slot.position,
          chemistry: chemistry.bySlot[slot.id] ?? 0,
          selectedRole: config?.role ?? '',
        ),
      ));
    }

    scored.sort((a, b) => a.score.compareTo(b.score));
    final suggestions = <SquadReplacementSuggestion>[];
    final usedIds = squad.playersBySlot.values.map((e) => e.id).toSet();

    for (final current in scored.take(maxSlots)) {
      try {
        final result = await playerRepository.advanced(
          PlayerFilter(
            position: current.slot.position,
            minRating: current.player.rating,
            maxRating: 99,
            minPrice: 1,
            maxPrice: maxBudget,
            platform: platform,
            sort: PlayerSort.priceAsc,
          ),
        );

        SquadReplacementSuggestion? best;

        for (final candidate in result.players.take(30)) {
          if (usedIds.contains(candidate.id)) continue;

          final price =
              platform == 'pc' ? candidate.pricePc : candidate.pricePs;
          if (price <= 0 || price > maxBudget) continue;

          final candidateScore = playerMetaScore(
            candidate,
            current.slot.position,
            chemistry: 0,
            selectedRole: '',
          );

          if (candidateScore <= current.score + 2) continue;

          final suggestion = SquadReplacementSuggestion(
            slotId: current.slot.id,
            currentPlayer: current.player,
            replacement: candidate,
            currentScore: current.score,
            replacementScore: candidateScore,
            price: price,
          );

          if (best == null ||
              suggestion.scoreGain / suggestion.price >
                  best.scoreGain / best.price) {
            best = suggestion;
          }
        }

        if (best != null) suggestions.add(best);
      } catch (_) {
        // No suggestion is safer than fabricating one.
      }
    }

    suggestions.sort((a, b) => b.scoreGain.compareTo(a.scoreGain));
    return suggestions;
  }

  double playerMetaScore(
    Player p,
    String slotPosition, {
    required int chemistry,
    required String selectedRole,
  }) {
    final roleFit = selectedRole.isNotEmpty && p.roles.contains(selectedRole);
    final plusBonus = (p.playStylesPlus.length * 2.2).clamp(0, 6).toDouble();
    final styleBonus = (p.playStyles.length * .35).clamp(0, 3).toDouble();
    final chemistryBonus = chemistry * 1.6;
    final roleBonus = roleFit ? 3.0 : 0.0;

    double base;
    if (_isAttack(slotPosition)) {
      base = p.shooting * .27 +
          p.pace * .22 +
          p.dribbling * .22 +
          p.passing * .12 +
          p.physical * .08 +
          p.rating * .09;
    } else if (_isDefense(slotPosition)) {
      base = p.defending * .30 +
          p.physical * .22 +
          p.pace * .18 +
          p.passing * .10 +
          p.dribbling * .06 +
          p.rating * .14;
    } else {
      base = p.passing * .24 +
          p.dribbling * .21 +
          p.pace * .12 +
          p.defending * .13 +
          p.physical * .12 +
          p.shooting * .08 +
          p.rating * .10;
    }

    if (slotPosition == 'GK') {
      base = p.rating.toDouble();
    }

    return (base + plusBonus + styleBonus + chemistryBonus + roleBonus)
        .clamp(0, 100)
        .toDouble();
  }

  bool _inPosition(Player p, String position) =>
      p.position == position || p.positions.contains(position);

  bool _isAttack(String p) =>
      const {'ST', 'CF', 'LW', 'RW'}.contains(p);

  bool _isDefense(String p) =>
      const {'GK', 'CB', 'LB', 'RB', 'LWB', 'RWB'}.contains(p);

  double _attackScore(Player p) =>
      (p.shooting * .32 + p.pace * .25 + p.dribbling * .25 + p.passing * .18);

  double _midfieldScore(Player p) =>
      (p.passing * .30 + p.dribbling * .25 + p.pace * .12 +
          p.defending * .12 + p.physical * .11 + p.shooting * .10);

  double _defenseScore(Player p) =>
      (p.defending * .38 + p.physical * .26 + p.pace * .21 + p.passing * .15);

  double _average(List<double> values) =>
      values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
}
