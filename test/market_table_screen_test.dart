import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fcbaz/features/market/data/price_snapshot_store.dart';
import 'package:fcbaz/features/market/data/watchlist_repository.dart';
import 'package:fcbaz/features/market/presentation/market_table_screen.dart';
import 'package:fcbaz/features/players/data/player_repository.dart';
import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';

Player _player({
  required String id,
  required String name,
  int rating = 85,
  int pricePs = 0,
  int pricePc = 0,
}) {
  return Player(
    id: id,
    name: name,
    rating: rating,
    position: 'ST',
    positions: const ['ST'],
    clubName: 'Club',
    leagueName: 'League',
    nationName: 'Nation',
    version: 'Gold',
    imageUrl: '',
    pace: 80,
    shooting: 80,
    passing: 80,
    dribbling: 80,
    defending: 40,
    physical: 70,
    skillMoves: 4,
    weakFoot: 4,
    pricePs: pricePs,
    pricePc: pricePc,
  );
}

class _FakePlayerRepository extends PlayerRepository {
  _FakePlayerRepository(this.result);

  final List<Player> result;

  @override
  Future<List<Player>> getPlayers() async => result;
}

Widget _app({
  required List<Player> players,
  required WatchlistRepository watchlist,
  PriceSnapshotStore? snapshots,
}) {
  return MaterialApp(
    theme: FCBazTheme.dark(),
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
    home: MarketTableScreen(
      playersRepository: _FakePlayerRepository(players),
      snapshots: snapshots ?? PriceSnapshotStore(),
      watchlistRepository: watchlist,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 10, 30, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'fcbaz_price_snapshots_v1_p1_console': jsonEncode([
        {
          'time': now.subtract(const Duration(hours: 6)).toIso8601String(),
          'price': 5000,
        },
        {'time': now.toIso8601String(), 'price': 5200},
      ]),
    });
  });

  testWidgets('shows both platform prices, hides unpriced cards', (
    tester,
  ) async {
    final watchlist = WatchlistRepository();
    await tester.pumpWidget(
      _app(
        players: [
          _player(
            id: 'p1',
            name: 'Erling Haaland',
            pricePs: 5000,
            pricePc: 7000,
          ),
          _player(id: 'p2', name: 'Unpriced Player'),
        ],
        watchlist: watchlist,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Erling Haaland'), findsOneWidget);
    expect(find.text('Unpriced Player'), findsNothing);
    expect(find.text('PS'), findsWidgets);
    expect(find.text('PC'), findsWidgets);
    expect(find.text('۵.۰K'), findsOneWidget);
    expect(find.text('۷.۰K'), findsOneWidget);
  });

  testWidgets('search filters rows and can be cleared', (tester) async {
    final watchlist = WatchlistRepository();
    await tester.pumpWidget(
      _app(
        players: [
          _player(id: 'p1', name: 'Erling Haaland', pricePs: 5000),
          _player(id: 'p2', name: 'Kylian Mbappe', pricePs: 7000),
        ],
        watchlist: watchlist,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Haaland');
    await tester.pump();
    expect(find.text('Erling Haaland'), findsOneWidget);
    expect(find.text('Kylian Mbappe'), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(find.text('Kylian Mbappe'), findsOneWidget);
  });

  testWidgets('watch toggle stores and removes the card', (tester) async {
    final watchlist = WatchlistRepository();
    await tester.pumpWidget(
      _app(
        players: [
          _player(id: 'p1', name: 'Erling Haaland', pricePs: 5000),
          _player(id: 'p2', name: 'Kylian Mbappe', pricePs: 7000),
        ],
        watchlist: watchlist,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.star_border_rounded).first);
    await tester.pumpAndSettle();
    expect((await watchlist.getAll()).map((item) => item.playerId), ['p1']);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_rounded));
    await tester.pumpAndSettle();
    expect(await watchlist.getAll(), isEmpty);
  });

  testWidgets('explains when no card has a real price', (tester) async {
    final watchlist = WatchlistRepository();
    await tester.pumpWidget(
      _app(
        players: [_player(id: 'p1', name: 'Erling Haaland')],
        watchlist: watchlist,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('قیمت ثبت‌شده‌ای نیست'), findsOneWidget);
  });
}
