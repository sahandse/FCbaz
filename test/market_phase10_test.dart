import 'package:fcbaz/features/market/data/watchlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 10 market tracker', () {
    test('old watchlist JSON stays backward compatible', () {
      final item = WatchlistItem.fromJson({
        'player_id': 'p1',
        'player_name': 'Player One',
        'target_price': 12000,
      });

      expect(item.playerId, 'p1');
      expect(item.targetPrice, 12000);
      expect(item.lastPrice, isNull);
      expect(item.previousPrice, isNull);
      expect(item.percentChange, isNull);
    });

    test('calculates local change only from real stored snapshots', () {
      final item = WatchlistItem(
        playerId: 'p1',
        playerName: 'Player One',
        targetPrice: 9000,
        previousPrice: 10000,
        lastPrice: 9000,
        lastCheckedAt: DateTime.utc(2026, 9, 26),
        platform: 'console',
      );

      expect(item.absoluteChange, -1000);
      expect(item.percentChange, closeTo(-10, 0.001));
      expect(item.targetReached, isTrue);
    });

    test('does not invent a change without two snapshots', () {
      const item = WatchlistItem(
        playerId: 'p2',
        playerName: 'Player Two',
        lastPrice: 50000,
      );

      expect(item.absoluteChange, isNull);
      expect(item.percentChange, isNull);
      expect(item.targetReached, isFalse);
    });
  });
}
