import 'package:fcbaz/features/market/data/watchlist_repository.dart';
import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/players/presentation/player_details_screen.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _player = Player(
  id: 'quick-actions-player',
  name: 'Test Player',
  rating: 88,
  position: 'ST',
  positions: ['ST'],
  clubName: 'Test Club',
  leagueName: 'Test League',
  nationName: 'Testland',
  version: 'Gold',
  imageUrl: '',
  pace: 90,
  shooting: 88,
  passing: 80,
  dribbling: 85,
  defending: 40,
  physical: 75,
  skillMoves: 4,
  weakFoot: 4,
  pricePs: 120000,
  pricePc: 150000,
);

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: FCBazTheme.dark(),
      home: const PlayerDetailsScreen(player: _player),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('hero watch action stores the real price in the watchlist', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    expect(find.textContaining('به دیده‌بان بازار اضافه شد'), findsOneWidget);

    final items = await WatchlistRepository().getAll();
    expect(items, hasLength(1));
    expect(items.single.playerId, _player.id);
    expect(items.single.platform, 'console');
    expect(items.single.lastPrice, 120000);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('hero exposes the image share action', (tester) async {
    await _pump(tester);
    expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
