import '../../players/domain/player.dart';
import '../../players/domain/player_value_analysis.dart';
import 'transfer_tax.dart';

/// Local purchase-efficiency numbers derived from a card's real price and
/// rating. Nothing here predicts the market; it only divides values the data
/// provider already returned.
class PurchaseValue {
  const PurchaseValue({
    required this.player,
    required this.platform,
    required this.price,
    required this.rating,
    required this.coinsPerRating,
    required this.taxAdjustedPrice,
    required this.taxAdjustedCoinsPerRating,
  });

  final Player player;
  final PlayerMarketPlatform platform;
  final int price;
  final int rating;
  final double? coinsPerRating;

  /// Sale price required to recover [price] after the 5% transfer tax.
  final int? taxAdjustedPrice;
  final double? taxAdjustedCoinsPerRating;

  bool get hasRealPrice => price > 0;
  bool get hasRating => rating > 0;
}

class PurchaseValueAnalyzer {
  const PurchaseValueAnalyzer({this.tax = const TransferTaxCalculator()});

  final TransferTaxCalculator tax;

  int priceFor(Player player, PlayerMarketPlatform platform) =>
      platform == PlayerMarketPlatform.pc ? player.pricePc : player.pricePs;

  PurchaseValue analyze(
    Player player, {
    PlayerMarketPlatform platform = PlayerMarketPlatform.console,
  }) {
    final price = priceFor(player, platform);
    final rating = player.rating;
    if (price <= 0 || rating <= 0) {
      return PurchaseValue(
        player: player,
        platform: platform,
        price: price,
        rating: rating,
        coinsPerRating: null,
        taxAdjustedPrice: null,
        taxAdjustedCoinsPerRating: null,
      );
    }
    final breakEven = (price / (1 - tax.rate)).ceil();
    return PurchaseValue(
      player: player,
      platform: platform,
      price: price,
      rating: rating,
      coinsPerRating: price / rating,
      taxAdjustedPrice: breakEven,
      taxAdjustedCoinsPerRating: breakEven / rating,
    );
  }

  /// Cheapest real-price cards first. Cards without a price for [platform]
  /// are dropped instead of being ranked with an invented value.
  List<PurchaseValue> rank(
    Iterable<Player> players, {
    PlayerMarketPlatform platform = PlayerMarketPlatform.console,
    int minRating = 0,
  }) {
    final values = <PurchaseValue>[];
    for (final player in players) {
      if (player.rating < minRating) continue;
      final value = analyze(player, platform: platform);
      if (!value.hasRealPrice) continue;
      values.add(value);
    }
    values.sort((a, b) {
      final byCoins = a.coinsPerRating!.compareTo(b.coinsPerRating!);
      if (byCoins != 0) return byCoins;
      final byRating = b.rating.compareTo(a.rating);
      if (byRating != 0) return byRating;
      return a.player.name.toLowerCase().compareTo(b.player.name.toLowerCase());
    });
    return values;
  }
}

class CheaperAlternative {
  const CheaperAlternative({
    required this.player,
    required this.platform,
    required this.price,
    required this.savings,
    required this.ratingGap,
  });

  final Player player;
  final PlayerMarketPlatform platform;
  final int price;
  final int savings;
  final int ratingGap;
}

/// Finds a same-position card that costs less and stays within a small rating
/// gap. It returns null when the local data has no honest candidate.
class CheaperAlternativeFinder {
  const CheaperAlternativeFinder({
    this.analyzer = const PurchaseValueAnalyzer(),
  });

  final PurchaseValueAnalyzer analyzer;

  CheaperAlternative? find(
    Player target,
    Iterable<Player> candidates, {
    PlayerMarketPlatform platform = PlayerMarketPlatform.console,
    int maxRatingGap = 2,
  }) {
    final targetPrice = analyzer.priceFor(target, platform);
    if (targetPrice <= 0 || target.rating <= 0) return null;

    CheaperAlternative? best;
    for (final candidate in candidates) {
      if (candidate.id == target.id) continue;
      if (candidate.position.toUpperCase() != target.position.toUpperCase()) {
        continue;
      }
      final ratingGap = target.rating - candidate.rating;
      if (ratingGap < 0 || ratingGap > maxRatingGap) continue;
      final price = analyzer.priceFor(candidate, platform);
      if (price <= 0 || price >= targetPrice) continue;
      if (best == null ||
          candidate.rating > best.player.rating ||
          (candidate.rating == best.player.rating && price < best.price)) {
        best = CheaperAlternative(
          player: candidate,
          platform: platform,
          price: price,
          savings: targetPrice - price,
          ratingGap: ratingGap,
        );
      }
    }
    return best;
  }
}
