import '../../../src/utils/persian_formatters.dart';
import 'sbc_rating_tools.dart';

class SbcShoppingCandidate {
  const SbcShoppingCandidate({
    required this.playerId,
    required this.playerName,
    required this.price,
  });

  final String playerId;
  final String playerName;
  final int price;

  bool get hasRealPrice => playerId.isNotEmpty && price > 0;
}

class SbcShoppingItem {
  const SbcShoppingItem({
    required this.rating,
    required this.count,
    required this.candidate,
  });

  final int rating;
  final int count;
  final SbcShoppingCandidate candidate;

  int get unitPrice => candidate.price;
  int get totalPrice => candidate.price * count;
}

/// Purchase plan for one rating combination. Only real market prices enter the
/// cost; ratings without a verified price stay in [unpricedCounts] and the
/// list refuses to compare itself against a budget until every row is priced.
class SbcShoppingList {
  const SbcShoppingList({
    required this.targetRating,
    required this.platform,
    required this.items,
    required this.unpricedCounts,
    required this.ownedCount,
    required this.budget,
  });

  final int targetRating;
  final String platform;
  final List<SbcShoppingItem> items;
  final Map<int, int> unpricedCounts;
  final int ownedCount;
  final int? budget;

  factory SbcShoppingList.build({
    required int targetRating,
    required SbcRatingCombination combination,
    required Map<int, SbcShoppingCandidate> candidates,
    String platform = 'console',
    Map<int, int> ownedCountByRating = const {},
    int? budget,
  }) {
    final items = <SbcShoppingItem>[];
    final unpriced = <int, int>{};
    var owned = 0;

    final ratings = combination.counts.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    for (final rating in ratings) {
      final required = combination.counts[rating] ?? 0;
      final ownedForRating = (ownedCountByRating[rating] ?? 0)
          .clamp(0, required)
          .toInt();
      owned += ownedForRating;
      final needed = required - ownedForRating;
      if (needed <= 0) continue;

      final candidate = candidates[rating];
      if (candidate == null || !candidate.hasRealPrice) {
        unpriced[rating] = needed;
      } else {
        items.add(
          SbcShoppingItem(rating: rating, count: needed, candidate: candidate),
        );
      }
    }

    return SbcShoppingList(
      targetRating: targetRating,
      platform: platform,
      items: List<SbcShoppingItem>.unmodifiable(items),
      unpricedCounts: Map<int, int>.unmodifiable(unpriced),
      ownedCount: owned,
      budget: budget != null && budget > 0 ? budget : null,
    );
  }

  int get purchaseCount =>
      items.fold<int>(0, (sum, item) => sum + item.count) +
      unpricedCounts.values.fold<int>(0, (sum, count) => sum + count);

  int get unpricedCount =>
      unpricedCounts.values.fold<int>(0, (sum, count) => sum + count);

  int get knownCost => items.fold<int>(0, (sum, item) => sum + item.totalPrice);

  bool get hasCompletePrices => unpricedCounts.isEmpty;

  bool get isEmpty => purchaseCount == 0;

  int? get remainingBudget {
    final limit = budget;
    if (limit == null || !hasCompletePrices) return null;
    return limit - knownCost;
  }

  int? get shortfall {
    final remaining = remainingBudget;
    if (remaining == null) return null;
    return remaining < 0 ? -remaining : 0;
  }

  bool get withinBudget {
    final remaining = remainingBudget;
    return remaining != null && remaining >= 0;
  }

  String get platformLabel => platform.toLowerCase() == 'pc' ? 'PC' : 'PS';

  String toShareText() {
    final buffer = StringBuffer()
      ..writeln('FCBaz • لیست خرید SBC')
      ..writeln('ریتینگ هدف ${faDigits(targetRating)} • بازار $platformLabel')
      ..writeln();

    if (isEmpty) {
      buffer.writeln('خرید لازم نیست؛ همه کارت‌ها از کلوب تأمین می‌شوند.');
    } else {
      for (final item in items) {
        buffer.writeln(
          '${faDigits(item.count)}× ${faDigits(item.rating)} '
          '${item.candidate.playerName} — ${formatCoinsFa(item.unitPrice)} سکه'
          ' (جمع ${formatCoinsFa(item.totalPrice)})',
        );
      }
      for (final entry in unpricedCounts.entries) {
        buffer.writeln(
          '${faDigits(entry.value)}× ریتینگ ${faDigits(entry.key)} — '
          'قیمت واقعی در دسترس نیست',
        );
      }
      buffer
        ..writeln()
        ..writeln(
          hasCompletePrices
              ? 'جمع خرید: ${formatCoinsFa(knownCost)} سکه'
              : 'جمع شناخته‌شده: ${formatCoinsFa(knownCost)} سکه؛ '
                    'برخی ردیف‌ها قیمت واقعی ندارند.',
        );
      final limit = budget;
      if (limit != null) {
        buffer.writeln('بودجه: ${formatCoinsFa(limit)} سکه');
        if (withinBudget) {
          buffer.writeln(
            'باقیمانده بودجه: ${formatCoinsFa(remainingBudget!)} سکه',
          );
        } else if (shortfall != null) {
          buffer.writeln('کمبود بودجه: ${formatCoinsFa(shortfall!)} سکه');
        } else {
          buffer.writeln(
            'کمبود بودجه: چون همه ردیف‌ها قیمت واقعی ندارند، مقایسه انجام نمی‌شود.',
          );
        }
      }
      buffer.writeln(
        'خرید بازار مالیات فروش ندارد؛ مالیات ۵٪ فقط هنگام فروش از موجودی کسر می‌شود.',
      );
    }

    buffer
      ..writeln()
      ..write('ساخته‌شده با FCBaz');
    return buffer.toString().trimRight();
  }
}
