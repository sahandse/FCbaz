import 'player_price.dart';

enum MoverWindow { day, week }

extension MoverWindowInfo on MoverWindow {
  Duration get span => this == MoverWindow.day
      ? const Duration(hours: 24)
      : const Duration(days: 7);

  String get labelFa => this == MoverWindow.day ? '۲۴ ساعت' : '۷ روز';
}

/// One card's real, locally observed movement. [points] only contains samples
/// the app actually recorded inside the selected window.
class MarketMover {
  const MarketMover({
    required this.playerId,
    required this.points,
    required this.first,
    required this.last,
  });

  final String playerId;
  final List<PricePoint> points;
  final PricePoint first;
  final PricePoint last;

  int get change => last.price - first.price;
  double? get changePercent =>
      first.price <= 0 ? null : (last.price - first.price) / first.price * 100;
  bool get isUp => change > 0;
  bool get isDown => change < 0;
  int get sampleCount => points.length;

  DateTime get firstAt => first.time;
  DateTime get lastAt => last.time;
}

class MarketMoversResult {
  const MarketMoversResult({
    required this.window,
    required this.movers,
    required this.observedPlayers,
    required this.eligiblePlayers,
  });

  final MoverWindow window;

  /// Only cards whose price actually changed, strongest move first.
  final List<MarketMover> movers;
  final int observedPlayers;
  final int eligiblePlayers;

  List<MarketMover> get risers =>
      movers.where((mover) => mover.isUp).take(4).toList(growable: false);

  List<MarketMover> get fallers =>
      movers.where((mover) => mover.isDown).take(4).toList(growable: false);

  bool get isEmpty => movers.isEmpty;
}

/// Computes 24h/7d movement strictly from local price observations. A card
/// needs at least two samples inside the window; a single point is reported as
/// missing data instead of being turned into a fake zero change.
class MarketMoversAnalyzer {
  const MarketMoversAnalyzer({this.minSamples = 2});

  final int minSamples;

  MarketMoversResult analyze(
    Map<String, List<PricePoint>> historyByPlayer, {
    required MoverWindow window,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final cutoff = currentTime.subtract(window.span);
    final movers = <MarketMover>[];
    var observed = 0;
    var eligible = 0;

    historyByPlayer.forEach((playerId, points) {
      final inWindow =
          points
              .where(
                (point) =>
                    point.price > 0 &&
                    !point.time.isBefore(cutoff) &&
                    !point.time.isAfter(currentTime),
              )
              .toList()
            ..sort((a, b) => a.time.compareTo(b.time));
      if (inWindow.isEmpty) return;
      observed++;
      if (inWindow.length < minSamples) return;
      eligible++;

      final first = inWindow.first;
      final last = inWindow.last;
      if (first.price == last.price) return;

      movers.add(
        MarketMover(
          playerId: playerId,
          points: List.unmodifiable(inWindow),
          first: first,
          last: last,
        ),
      );
    });

    movers.sort((a, b) {
      final byMove = b.changePercent!.abs().compareTo(a.changePercent!.abs());
      if (byMove != 0) return byMove;
      return a.playerId.compareTo(b.playerId);
    });

    return MarketMoversResult(
      window: window,
      movers: List.unmodifiable(movers),
      observedPlayers: observed,
      eligiblePlayers: eligible,
    );
  }
}
