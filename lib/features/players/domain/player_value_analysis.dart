import 'player.dart';

enum PlayerMarketPlatform { console, pc }

class PlayerValueAnalysis {
  const PlayerValueAnalysis({
    required this.player,
    required this.platform,
    required this.price,
    required this.faceStatAverage,
    required this.performanceScore,
    required this.valueIndex,
  });

  final Player player;
  final PlayerMarketPlatform platform;
  final int price;
  final double faceStatAverage;
  final double performanceScore;
  final double? valueIndex;

  bool get hasRealPrice => price > 0;
}

class PlayerValueAnalyzer {
  const PlayerValueAnalyzer();

  PlayerValueAnalysis analyze(
    Player player, {
    PlayerMarketPlatform platform = PlayerMarketPlatform.console,
  }) {
    final price = platform == PlayerMarketPlatform.pc
        ? player.pricePc
        : player.pricePs;

    final faceStats = <int>[
      player.pace,
      player.shooting,
      player.passing,
      player.dribbling,
      player.defending,
      player.physical,
    ].where((value) => value > 0).toList();

    final faceAverage = faceStats.isEmpty
        ? 0.0
        : faceStats.reduce((a, b) => a + b) / faceStats.length;

    // This is an FCBaz local comparison metric, not a claim about market value.
    // It only uses real card fields already returned by the data provider.
    final performance =
        (player.rating * 0.34) +
        (faceAverage * 0.46) +
        (player.playStylesPlus.length * 2.5) +
        (player.playStyles.length * 0.35) +
        (player.roles.length * 0.45) +
        (player.skillMoves * 0.65) +
        (player.weakFoot * 0.65);

    final value = price <= 0 ? null : performance / (price / 10000.0);

    return PlayerValueAnalysis(
      player: player,
      platform: platform,
      price: price,
      faceStatAverage: faceAverage,
      performanceScore: performance,
      valueIndex: value,
    );
  }
}
