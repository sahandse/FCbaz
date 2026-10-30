import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/market/domain/market_movers.dart';
import 'package:fcbaz/features/market/domain/player_price.dart';

PricePoint point(DateTime time, int price) =>
    PricePoint(time: time, price: price);

void main() {
  const analyzer = MarketMoversAnalyzer();
  final now = DateTime(2026, 10, 30, 12);

  test('requires two observations inside the window', () {
    final result = analyzer.analyze(
      {
        'one-sample': [point(now.subtract(const Duration(hours: 2)), 5000)],
        'two-samples': [
          point(now.subtract(const Duration(hours: 20)), 5000),
          point(now.subtract(const Duration(hours: 1)), 6000),
        ],
      },
      window: MoverWindow.day,
      now: now,
    );

    expect(result.observedPlayers, 2);
    expect(result.eligiblePlayers, 1);
    expect(result.movers.length, 1);
    expect(result.movers.single.playerId, 'two-samples');
    expect(result.movers.single.change, 1000);
    expect(result.movers.single.changePercent, closeTo(20, .0001));
  });

  test('ignores samples older than the selected window', () {
    final result = analyzer.analyze(
      {
        'old': [
          point(now.subtract(const Duration(days: 3)), 4000),
          point(now.subtract(const Duration(hours: 1)), 6000),
        ],
      },
      window: MoverWindow.day,
      now: now,
    );

    expect(result.eligiblePlayers, 0);
    expect(result.movers, isEmpty);
  });

  test('uses the week window when requested', () {
    final result = analyzer.analyze(
      {
        'weekly': [
          point(now.subtract(const Duration(days: 5)), 4000),
          point(now.subtract(const Duration(hours: 1)), 6000),
        ],
      },
      window: MoverWindow.week,
      now: now,
    );

    expect(result.eligiblePlayers, 1);
    expect(result.movers.single.changePercent, closeTo(50, .0001));
  });

  test('splits risers and fallers and ignores flat prices', () {
    final result = analyzer.analyze(
      {
        'up': [
          point(now.subtract(const Duration(hours: 10)), 10000),
          point(now.subtract(const Duration(hours: 1)), 12000),
        ],
        'down': [
          point(now.subtract(const Duration(hours: 10)), 10000),
          point(now.subtract(const Duration(hours: 1)), 7500),
        ],
        'flat': [
          point(now.subtract(const Duration(hours: 10)), 10000),
          point(now.subtract(const Duration(hours: 1)), 10000),
        ],
      },
      window: MoverWindow.day,
      now: now,
    );

    expect(result.eligiblePlayers, 3);
    expect(result.movers.length, 2);
    expect(result.risers.single.playerId, 'up');
    expect(result.fallers.single.playerId, 'down');
    expect(result.fallers.single.change, -2500);
    expect(result.fallers.single.changePercent, closeTo(-25, .0001));
  });

  test('orders movers by the strongest absolute move', () {
    final result = analyzer.analyze(
      {
        'small': [
          point(now.subtract(const Duration(hours: 10)), 10000),
          point(now.subtract(const Duration(hours: 1)), 11000),
        ],
        'big': [
          point(now.subtract(const Duration(hours: 10)), 10000),
          point(now.subtract(const Duration(hours: 1)), 8000),
        ],
      },
      window: MoverWindow.day,
      now: now,
    );

    expect(result.movers.map((mover) => mover.playerId), ['big', 'small']);
  });

  test('never builds a percent from a zero price sample', () {
    final result = analyzer.analyze(
      {
        'zero': [
          point(now.subtract(const Duration(hours: 10)), 0),
          point(now.subtract(const Duration(hours: 1)), 9000),
        ],
      },
      window: MoverWindow.day,
      now: now,
    );

    expect(result.observedPlayers, 1);
    expect(result.eligiblePlayers, 0);
    expect(result.movers, isEmpty);
  });
}
