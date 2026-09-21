/// Finds practical 11-player rating mixes for SBC squad rating targets.
class RatingCombinationSolver {
  const RatingCombinationSolver();

  List<RatingCombination> solve({
    required int targetRating,
    int squadSize = 11,
    int limit = 15,
  }) {
    if (squadSize <= 0 || targetRating < 40) return const [];
    final needed = targetRating * squadSize;
    final results = <RatingCombination>[];

    // Practical mixes around the target (R, R-1, R-2, R+1).
    for (var high = targetRating + 1; high >= targetRating - 1; high--) {
      for (var mid = high; mid >= high - 2; mid--) {
        for (var low = mid; low >= mid - 2; low--) {
          if (low < 45) continue;
          for (var highCount = 0; highCount <= squadSize; highCount++) {
            for (var midCount = 0;
                midCount <= squadSize - highCount;
                midCount++) {
              final lowCount = squadSize - highCount - midCount;
              if (lowCount < 0) continue;
              final sum =
                  highCount * high + midCount * mid + lowCount * low;
              if (sum < needed) continue;

              final counts = <int, int>{};
              void add(int rating, int count) {
                if (count <= 0) return;
                counts[rating] = (counts[rating] ?? 0) + count;
              }

              add(high, highCount);
              add(mid, midCount);
              add(low, lowCount);

              final ratings = <int>[
                for (final e in counts.entries)
                  for (var i = 0; i < e.value; i++) e.key,
              ]..sort((a, b) => b.compareTo(a));

              results.add(
                RatingCombination(
                  ratings: ratings,
                  average: sum / squadSize,
                  counts: counts,
                ),
              );
            }
          }
        }
      }
    }

    // Deduplicate by summary signature.
    final seen = <String>{};
    final unique = <RatingCombination>[];
    for (final item in results) {
      if (seen.add(item.summary)) unique.add(item);
    }

    unique.sort((a, b) {
      final byWaste = (a.average - targetRating).compareTo(b.average - targetRating);
      if (byWaste != 0) return byWaste;
      return a.summary.compareTo(b.summary);
    });

    return unique.take(limit).toList();
  }
}

class RatingCombination {
  const RatingCombination({
    required this.ratings,
    required this.average,
    required this.counts,
  });

  final List<int> ratings;
  final double average;
  final Map<int, int> counts;

  String get summary {
    final parts = counts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return parts.map((e) => '${e.value}×${e.key}').join(' + ');
  }
}
