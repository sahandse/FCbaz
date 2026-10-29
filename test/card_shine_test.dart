import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/players/presentation/card/card_shine.dart';
import 'package:fcbaz/features/players/presentation/card/player_card_theme.dart';
import 'package:fcbaz/features/players/presentation/player_item_visual.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Player _player({required String rarity}) => Player(
  id: 'test-player',
  name: 'Test Player',
  rating: 90,
  position: 'ST',
  positions: const ['ST'],
  clubName: 'Test Club',
  leagueName: 'Test League',
  nationName: 'Test Nation',
  version: 'FC 27',
  imageUrl: '',
  pace: 90,
  shooting: 90,
  passing: 80,
  dribbling: 85,
  defending: 40,
  physical: 80,
  skillMoves: 4,
  weakFoot: 4,
  rarity: rarity,
);

Widget _host(Player player, {bool reduceMotion = false}) {
  return MaterialApp(
    theme: FCBazTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 240,
            child: PlayerItemVisual(player: player, showPrices: false),
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('premium finishes enable the foil sweep', () {
    expect(PlayerCardTheme.icon.shine, isTrue);
    expect(PlayerCardTheme.hero.shine, isTrue);
    expect(PlayerCardTheme.totw.shine, isTrue);
    expect(PlayerCardTheme.hallOfFut.shine, isTrue);
    expect(PlayerCardTheme.holographic.shine, isTrue);
    expect(PlayerCardTheme.gold.shine, isFalse);
    expect(PlayerCardTheme.silver.shine, isFalse);
    expect(PlayerCardTheme.standard.shine, isFalse);
  });

  testWidgets('premium cards paint the shine layer', (tester) async {
    await tester.pumpWidget(_host(_player(rarity: 'Hero')));
    await tester.pump();

    expect(find.byType(CardShine), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('standard cards stay calm', (tester) async {
    await tester.pumpWidget(_host(_player(rarity: 'Gold Rare')));
    await tester.pump();

    expect(find.byType(CardShine), findsNothing);
  });

  testWidgets('reduced motion keeps the shine static', (tester) async {
    await tester.pumpWidget(
      _host(_player(rarity: 'Team of the Week'), reduceMotion: true),
    );
    await tester.pump();

    expect(find.byType(CardShine), findsOneWidget);
    final controller = tester.state(find.byType(CardShine));
    expect(controller, isNotNull);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
