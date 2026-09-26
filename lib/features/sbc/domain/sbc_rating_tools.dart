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
    final entries = counts.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
    for (final entry in entries) {
      out.addAll(List<int>.filled(entry.value, entry.key));
    }
    return out;
  }
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
    int squadSize = 11,
    int? minCardRating,
    int? maxCardRating,
    int limit = 30,
  }) {
    final minRating = (minCardRating ?? targetRating - 5).clamp(40, 99);
    final maxRating = (maxCardRating ?? targetRating + 5).clamp(40, 99);
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
  }) {
    final ratings = <int>[];
    for (final entry in counts.entries) {
      ratings.addAll(List<int>.filled(entry.value, entry.key));
    }
    if (ratings.isEmpty) return;

    final squadRating = calculateSquadRating(ratings);
    if (squadRating < targetRating) return;

    int? cost;
    if (cheapestPriceByRating.isNotEmpty &&
        counts.keys.every((rating) => (cheapestPriceByRating[rating] ?? 0) > 0)) {
      cost = 0;
      for (final entry in counts.entries) {
        cost += cheapestPriceByRating[entry.key]! * entry.value;
      }
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
}
