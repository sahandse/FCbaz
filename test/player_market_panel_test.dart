import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fcbaz/features/market/data/market_repository.dart';
import 'package:fcbaz/features/market/data/price_snapshot_store.dart';
import 'package:fcbaz/features/market/data/watchlist_repository.dart';
import 'package:fcbaz/features/market/domain/player_price.dart';
import 'package:fcbaz/features/market/presentation/player_market_panel.dart';
import 'package:fcbaz/features/market/presentation/price_history_chart.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';

class _FakeMarketRepository extends MarketRepository {
  _FakeMarketRepository({required this.price, this.history = const []});

  final PlayerPrice price;
  final List<PricePoint> history;

  @override
  Future<PlayerPrice> getPlayerPrice(
    String playerId, {
    String platform = 'console',
    bool forceRefresh = false,
  }) async => price;

  @override
  Future<List<PricePoint>> getPriceHistory(
    String playerId, {
    String platform = 'console',
    String range = '7d',
    bool forceRefresh = false,
  }) async => history;
}

class _FakeWatchlistRepository extends WatchlistRepository {
  @override
  Future<bool> contains(String playerId) async => false;
}

void main() {
  final now = DateTime(2026, 10, 23, 12);
  final livePrice = PlayerPrice(
    playerId: 'p1',
    platform: 'console',
    current: 5000,
    low: 4400,
    high: 5600,
    change24hPercent: null,
    updatedAt: now,
  );

  Widget host(Widget child) => MaterialApp(
    theme: FCBazTheme.dark(),
    builder: (context, inner) =>
        Directionality(textDirection: TextDirection.rtl, child: inner!),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  Widget panel({
    required List<PricePoint> serverHistory,
    required PriceSnapshotStore snapshots,
  }) => PlayerMarketPanel(
    playerId: 'p1',
    playerName: 'Player One',
    market: _FakeMarketRepository(price: livePrice, history: serverHistory),
    watchlist: _FakeWatchlistRepository(),
    snapshots: snapshots,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('falls back to real local observations when server history '
      'is unavailable', (tester) async {
    final store = PriceSnapshotStore(now: () => now);
    await store.record(
      'p1',
      price: 4500,
      observedAt: now.subtract(const Duration(days: 2)),
    );
    await store.record(
      'p1',
      price: 4800,
      observedAt: now.subtract(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      host(panel(serverHistory: const [], snapshots: store)),
    );
    await tester.pumpAndSettle();

    expect(find.text('نمودار قیمت ۷ روز (محلی)'), findsOneWidget);
    expect(find.textContaining('تاریخچه محلی'), findsOneWidget);
    expect(find.byType(PriceHistoryChart), findsOneWidget);
    expect(
      find.text('تاریخچه قیمت واقعی برای این کارت در دسترس نیست.'),
      findsNothing,
    );

    final stored = await store.getHistory('p1');
    expect(stored.map((e) => e.price), [4500, 4800, 5000]);
  });

  testWidgets('shows an honest note when only one local observation exists', (
    tester,
  ) async {
    final store = PriceSnapshotStore(now: () => now);

    await tester.pumpWidget(
      host(panel(serverHistory: const [], snapshots: store)),
    );
    await tester.pumpAndSettle();

    expect(find.text('داده کافی برای نمودار قیمت وجود ندارد'), findsOneWidget);
    expect(find.textContaining('تاریخچه محلی'), findsOneWidget);
  });

  testWidgets('prefers provider history when it is available', (tester) async {
    final store = PriceSnapshotStore(now: () => now);

    await tester.pumpWidget(
      host(
        panel(
          serverHistory: [
            PricePoint(
              time: now.subtract(const Duration(days: 1)),
              price: 4700,
            ),
            PricePoint(time: now, price: 5000),
          ],
          snapshots: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('نمودار قیمت ۷ روز'), findsOneWidget);
    expect(find.textContaining('تاریخچه محلی'), findsNothing);
    expect(find.byType(PriceHistoryChart), findsOneWidget);
  });
}
