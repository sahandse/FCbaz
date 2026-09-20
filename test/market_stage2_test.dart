import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fcbaz/features/market/data/watchlist_repository.dart';
import 'package:fcbaz/features/market/domain/player_price.dart';

void main() {
  test('parses market payload', () {
    final price = PlayerPrice.fromJson({
      'player_id': 'p1',
      'platform': 'console',
      'current': 125000,
      'low': 120000,
      'high': 132000,
      'change_24h_percent': -3.2,
      'updated_at': '2026-09-20T12:00:00Z',
    });

    expect(price.playerId, 'p1');
    expect(price.current, 125000);
    expect(price.change24hPercent, -3.2);
  });

  test('watchlist stores and removes players locally', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = WatchlistRepository();
    const item = WatchlistItem(playerId: 'p1', playerName: 'Player One');

    await repo.toggle(item);
    expect(await repo.contains('p1'), isTrue);

    await repo.setTargetPrice('p1', 99000);
    final saved = await repo.getAll();
    expect(saved.single.targetPrice, 99000);

    await repo.toggle(item);
    expect(await repo.contains('p1'), isFalse);
  });
}
