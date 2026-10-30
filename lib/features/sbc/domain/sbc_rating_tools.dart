class SbcRatingCombination {
  const SbcRatingCombination({
    required this.counts,
    required this.squadRating,
    this.estimatedCost,
  });

  final Map<int, int> counts;
  final int squadRating;
  final int? estimatedCost;

  int get playerCount => counts.values.fold(0, (sum, value) => sum + value);

  List<int> get ratings {
    final out = <int>[];
    final entries = counts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    for (final entry in entries) {
      out.addAll(List<int>.filled(entry.value, entry.key));
    }
    return out;
  }
}

class SbcClubSquad<T> {
  const SbcClubSquad({
    required this.selected,
    required this.untradeables,
    required this.tradeables,
    required this.counts,
    required this.squadRating,
    required this.targetRating,
  });

  final List<T> selected;
  final List<T> untradeables;
  final List<T> tradeables;
  final Map<int, int> counts;
  final int squadRating;
  final int targetRating;

  bool get meetsTarget => squadRating >= targetRating;
  int get shortfall => meetsTarget ? 0 : targetRating - squadRating;
  int get playerCount => selected.length;
}

class SbcRatingCalculator {
  const SbcRatingCalculator();

  int calculateSquadRating(List<int> ratings) {
    if (ratings.isEmpty) return 0;

    final sum = ratings.fold<int>(0, (total, value) => total + value);
    final average = sum / ratings.length;
    var correction = 0.0;

    for (final rating in ratings) {
      if (rating > average) correction += rating - average;
    }

    final adjusted = (sum + correction).round();
    return (adjusted / ratings.length).floor();
  }

  bool meetsTarget(List<int> ratings, int target) {
    return calculateSquadRating(ratings) >= target;
  }

  List<SbcRatingCombination> combinations({
    required int targetRating,
    Map<int, int> cheapestPriceByRating = const {},
    Map<int, int> ownedCountByRating = const {},
    int squadSize = 11,
    int? minCardRating,
    int? maxCardRating,
    int limit = 30,
  }) {
    final minRating = (minCardRating ?? targetRating - 5).clamp(40, 99).toInt();
    final maxRating = (maxCardRating ?? targetRating + 5).clamp(40, 99).toInt();
    final ratingBand = <int>[
      for (var rating = minRating; rating <= maxRating; rating++) rating,
    ];

    final results = <SbcRatingCombination>[];
    final counts = <int, int>{};

    void walk(int index, int remaining) {
      if (index == ratingBand.length - 1) {
        if (remaining > 0) counts[ratingBand[index]] = remaining;
        _maybeAdd(
          results: results,
          counts: counts,
          targetRating: targetRating,
          cheapestPriceByRating: cheapestPriceByRating,
          ownedCountByRating: ownedCountByRating,
        );
        counts.remove(ratingBand[index]);
        return;
      }

      final rating = ratingBand[index];
      for (var count = 0; count <= remaining; count++) {
        if (count > 0) counts[rating] = count;
        walk(index + 1, remaining - count);
        counts.remove(rating);
      }
    }

    walk(0, squadSize);

    results.sort((a, b) {
      final aCost = a.estimatedCost;
      final bCost = b.estimatedCost;
      if (aCost != null && bCost != null && aCost != bCost) {
        return aCost.compareTo(bCost);
      }
      if (aCost != null && bCost == null) return -1;
      if (aCost == null && bCost != null) return 1;

      final aWaste = a.squadRating - targetRating;
      final bWaste = b.squadRating - targetRating;
      if (aWaste != bWaste) return aWaste.compareTo(bWaste);

      final aSpread = _spread(a.counts);
      final bSpread = _spread(b.counts);
      return aSpread.compareTo(bSpread);
    });

    return results.take(limit).toList(growable: false);
  }

  void _maybeAdd({
    required List<SbcRatingCombination> results,
    required Map<int, int> counts,
    required int targetRating,
    required Map<int, int> cheapestPriceByRating,
    required Map<int, int> ownedCountByRating,
  }) {
    final ratings = <int>[];
    for (final entry in counts.entries) {
      ratings.addAll(List<int>.filled(entry.value, entry.key));
    }
    if (ratings.isEmpty) return;

    final squadRating = calculateSquadRating(ratings);
    if (squadRating < targetRating) return;

    int? cost;
    if (cheapestPriceByRating.isNotEmpty) {
      var totalCost = 0;
      var priced = true;
      for (final entry in counts.entries) {
        final owned = (ownedCountByRating[entry.key] ?? 0).clamp(
          0,
          entry.value,
        );
        final paidCount = entry.value - owned;
        if (paidCount <= 0) continue;
        final price = cheapestPriceByRating[entry.key] ?? 0;
        if (price <= 0) {
          priced = false;
          break;
        }
        totalCost += price * paidCount;
      }
      if (priced) cost = totalCost;
    }

    results.add(
      SbcRatingCombination(
        counts: Map<int, int>.unmodifiable(Map<int, int>.from(counts)),
        squadRating: squadRating,
        estimatedCost: cost,
      ),
    );
  }

  int _spread(Map<int, int> counts) {
    if (counts.isEmpty) return 0;
    final ratings = counts.keys.toList()..sort();
    return ratings.last - ratings.first;
  }

  /// Builds the club-aware SBC squad for [targetRating].
  ///
  /// Priority: use the fewest tradeable cards (untradeable cards cost nothing
  /// to sacrifice), then the lowest ratings that still reach the target. The
  /// result is data driven; when the club cannot reach the target the best
  /// achievable squad is returned with [SbcClubSquad.meetsTarget] false and a
  /// real [SbcClubSquad.shortfall], never a padded estimate.
  SbcClubSquad<T>? solveClubSquad<T>({
    required List<T> clubItems,
    required int Function(T item) getRating,
    required bool Function(T item) isUntradeable,
    required int targetRating,
    int squadSize = 11,
  }) {
    if (squadSize <= 0 || clubItems.length < squadSize) return null;

    final untradeable = clubItems.where(isUntradeable).toList()
      ..sort((a, b) => getRating(a).compareTo(getRating(b)));
    final tradeable = clubItems.where((item) => !isUntradeable(item)).toList()
      ..sort((a, b) => getRating(a).compareTo(getRating(b)));

    for (
      var tradeableCount = 0;
      tradeableCount <= squadSize;
      tradeableCount++
    ) {
      final untradeableCount = squadSize - tradeableCount;
      if (untradeableCount > untradeable.length ||
          tradeableCount > tradeable.length) {
        continue;
      }

      var untradeableStart = 0;
      var tradeableStart = 0;

      while (true) {
        final selected = <T>[
          for (var i = 0; i < untradeableCount; i++)
            untradeable[untradeableStart + i],
          for (var i = 0; i < tradeableCount; i++)
            tradeable[tradeableStart + i],
        ];
        final squadRating = calculateSquadRating(
          selected.map(getRating).toList(),
        );

        if (squadRating >= targetRating) {
          return _buildClubSquad(
            selected: selected,
            getRating: getRating,
            isUntradeable: isUntradeable,
            squadRating: squadRating,
            targetRating: targetRating,
          );
        }

        final canUpgradeUntradeable =
            untradeableCount > 0 &&
            untradeableStart + untradeableCount < untradeable.length;
        final canUpgradeTradeable =
            tradeableCount > 0 &&
            tradeableStart + tradeableCount < tradeable.length;
        if (!canUpgradeUntradeable && !canUpgradeTradeable) break;

        final nextUntradeable = canUpgradeUntradeable
            ? getRating(untradeable[untradeableStart + untradeableCount])
            : null;
        final nextTradeable = canUpgradeTradeable
            ? getRating(tradeable[tradeableStart + tradeableCount])
            : null;

        if (nextUntradeable != null &&
            (nextTradeable == null || nextUntradeable <= nextTradeable)) {
          untradeableStart++;
        } else {
          tradeableStart++;
        }
      }
    }

    final best = [...clubItems]
      ..sort((a, b) => getRating(b).compareTo(getRating(a)));
    final selected = best.take(squadSize).toList();
    return _buildClubSquad(
      selected: selected,
      getRating: getRating,
      isUntradeable: isUntradeable,
      squadRating: calculateSquadRating(selected.map(getRating).toList()),
      targetRating: targetRating,
    );
  }

  SbcClubSquad<T> _buildClubSquad<T>({
    required List<T> selected,
    required int Function(T item) getRating,
    required bool Function(T item) isUntradeable,
    required int squadRating,
    required int targetRating,
  }) {
    final counts = <int, int>{};
    for (final item in selected) {
      final rating = getRating(item);
      counts.update(rating, (value) => value + 1, ifAbsent: () => 1);
    }
    final ordered = [...selected]
      ..sort((a, b) => getRating(b).compareTo(getRating(a)));
    return SbcClubSquad(
      selected: List<T>.unmodifiable(ordered),
      untradeables: List<T>.unmodifiable(ordered.where(isUntradeable)),
      tradeables: List<T>.unmodifiable(
        ordered.where((item) => !isUntradeable(item)),
      ),
      counts: Map<int, int>.unmodifiable(counts),
      squadRating: squadRating,
      targetRating: targetRating,
    );
  }
}
