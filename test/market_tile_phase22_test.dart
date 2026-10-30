import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fcbaz/features/market/data/watchlist_repository.dart';
import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/players/presentation/player_market_tile.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';

Player _player({int pricePs = 846000, int pricePc = 904000}) => Player(
  id: '1',
  name: 'Alexia Putellas',
  rating: 91,
  position: 'CM',
  positions: const ['CM', 'ST'],
  clubName: 'London City',
  leagueName: 'Barclays WSL',
  nationName: 'Spain',
  version: 'Gold',
  imageUrl: '',
  pace: 96,
  shooting: 91,
  passing: 80,
  dribbling: 92,
  defending: 29,
  physical: 76,
  skillMoves: 5,
  weakFoot: 5,
  pricePs: pricePs,
  pricePc: pricePc,
);

Future<void> _pumpTile(
  WidgetTester tester,
  Player player, {
  String platform = 'console',
  double width = 160,
  double height = 320,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: FCBazTheme.dark(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: height,
              child: PlayerMarketTile(player: player, pricePlatform: platform),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('full coin prices use Persian digits and thousands separators', () {
    expect(formatCoinsFa(2888000), '۲,۸۸۸,۰۰۰');
    expect(formatCoinsFa(846000), '۸۴۶,۰۰۰');
    expect(formatCoinsFa(999), '۹۹۹');
    expect(formatCoinsFa(0), '—');
  });

  testWidgets('tile shows card, colored stats, club and price', (tester) async {
    await _pumpTile(tester, _player());

    expect(find.text('PAC'), findsWidgets);
    expect(find.text('London City · Barclays WSL'), findsOneWidget);
    expect(
      find.text('قیمت ثبت‌شده برای نسخه کارت و پلتفرم انتخاب‌شده'),
      findsOneWidget,
    );
    expect(find.text('۸۴۶,۰۰۰'), findsOneWidget);
    expect(find.text('سکه'), findsOneWidget);

    Color colorOf(String value) =>
        tester.widget<Text>(find.text(value)).style!.color!;

    expect(colorOf('۹۶'), FcbazPalette.dark.success);
    expect(colorOf('۸۰'), FcbazPalette.dark.success);
    expect(colorOf('۷۶'), FcbazPalette.dark.warning);
    expect(colorOf('۲۹'), FcbazPalette.dark.danger);
  });

  testWidgets('price follows the selected platform', (tester) async {
    await _pumpTile(tester, _player(), platform: 'pc');
    expect(find.text('۹۰۴,۰۰۰'), findsOneWidget);
    expect(find.text('۸۴۶,۰۰۰'), findsNothing);
  });

  testWidgets('missing price is labelled honestly', (tester) async {
    await _pumpTile(tester, _player(pricePs: 0, pricePc: 0));
    expect(find.text('قیمت معتبری برای این نسخه ثبت نشده است'), findsOneWidget);
    expect(find.text('سکه'), findsNothing);
  });

  testWidgets('star toggles local favorite', (tester) async {
    await _pumpTile(tester, _player());
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_border_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('watch action stores the card for the selected platform', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _pumpTile(tester, _player(), platform: 'pc');
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.compare_arrows_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    final items = await WatchlistRepository().getAll();
    expect(items.single.playerId, '1');
    expect(items.single.platform, 'pc');
    expect(items.single.lastPrice, 904000);
    expect(
      calls.any(
        (call) =>
            call.method == 'HapticFeedback.vibrate' &&
            call.arguments.toString().contains('selectionClick'),
      ),
      isTrue,
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('narrow tile does not overflow', (tester) async {
    for (final width in [140.0, 154.0, 220.0]) {
      await _pumpTile(tester, _player(), width: width, height: width * 2);
      expect(
        tester.takeException(),
        isNull,
        reason: 'overflow at width $width',
      );
    }
  });
}
