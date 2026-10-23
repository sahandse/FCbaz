import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/players/presentation/card/nation_flags.dart';
import 'package:fcbaz/features/players/presentation/card/player_card_theme.dart';
import 'package:fcbaz/features/players/presentation/player_item_visual.dart';

Player _player({
  String name = 'Alexia Putellas',
  int rating = 91,
  String position = 'CM',
  List<String>? positions,
  String version = 'Gold',
  String imageUrl = '',
  Map<String, int> inGameStats = const {},
}) => Player(
  id: '1',
  name: name,
  rating: rating,
  position: position,
  positions: positions ?? [position],
  clubName: 'London City',
  leagueName: 'Barclays WSL',
  nationName: 'Spain',
  version: version,
  imageUrl: imageUrl,
  pace: 80,
  shooting: 90,
  passing: 91,
  dribbling: 92,
  defending: 72,
  physical: 75,
  skillMoves: 4,
  weakFoot: 4,
  pricePs: 846000,
  pricePc: 904000,
  inGameStats: inGameStats,
);

Future<void> _pumpCard(
  WidgetTester tester,
  Player player, {
  double width = 180,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: width / .72,
            child: PlayerItemVisual(player: player, compact: true),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'outfield card shows FC27 rating, title-case name, stats and prices',
    (tester) async {
      await _pumpCard(tester, _player());

      expect(find.text('91'), findsWidgets);
      expect(find.text('CM'), findsOneWidget);
      expect(find.text('Alexia Putellas'), findsOneWidget);
      for (final label in ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('846K PS'), findsOneWidget);
      expect(find.text('904K PC'), findsOneWidget);
      expect(find.text('4★4'), findsOneWidget);
      expect(find.text('GOLD'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('alternate position is tagged on the card edge', (tester) async {
    await _pumpCard(
      tester,
      _player(position: 'CM', positions: const ['CM', 'CDM']),
    );

    expect(find.text('CDM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('goalkeeper card swaps in goalkeeper stat labels', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      _player(
        name: 'Gianluigi Donnarumma',
        position: 'GK',
        inGameStats: const {
          'DIV': 90,
          'HAN': 88,
          'KIC': 82,
          'REF': 89,
          'SPD': 51,
          'POS': 87,
        },
      ),
    );

    for (final label in ['DIV', 'HAN', 'KIC', 'REF', 'SPD', 'POS']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('PAC'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing portrait falls back to a silhouette', (tester) async {
    await _pumpCard(tester, _player());

    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long names and narrow widths do not overflow', (tester) async {
    final player = _player(name: 'Maximiliano Gastón López Hernández');
    for (final width in [145.0, 176.0, 220.0]) {
      await _pumpCard(tester, player, width: width);
      expect(
        tester.takeException(),
        isNull,
        reason: 'overflow at width $width',
      );
      expect(find.text('Maximiliano Gastón López Hernández'), findsOneWidget);
    }
  });

  test('FC27 shield, finishes and edge tags are code-drawn', () {
    final painters = File(
      'lib/features/players/presentation/card/player_card_painters.dart',
    ).readAsStringSync();
    final visual = File(
      'lib/features/players/presentation/player_item_visual.dart',
    ).readAsStringSync();
    final theme = File(
      'lib/features/players/presentation/card/player_card_theme.dart',
    ).readAsStringSync();

    expect(painters, contains('fc27CardPath'));
    expect(painters, contains('CardFinish.satin'));
    expect(painters, contains('CardFinish.marble'));
    expect(painters, contains('CardFinish.holo'));
    expect(theme, contains('ornate: true'));
    expect(theme, contains('finish: CardFinish.marble'));
    expect(visual, contains('CardTag'));
    expect(visual, contains('RoleDiamond'));
    expect(visual, contains('_titleCase'));
  });

  test('rarity themes map to distinct palettes', () {
    expect(PlayerCardTheme.forRarity('Gold'), same(PlayerCardTheme.gold));
    expect(PlayerCardTheme.forRarity('Silver'), same(PlayerCardTheme.silver));
    expect(PlayerCardTheme.forRarity('Bronze'), same(PlayerCardTheme.bronze));
    expect(PlayerCardTheme.forRarity('ICON'), same(PlayerCardTheme.icon));
    expect(
      PlayerCardTheme.forRarity('team of the week'),
      same(PlayerCardTheme.totw),
    );
    expect(
      PlayerCardTheme.forRarity('something else'),
      same(PlayerCardTheme.standard),
    );
    expect(
      PlayerCardTheme.gold.gradient,
      isNot(equals(PlayerCardTheme.silver.gradient)),
    );
  });

  test('nation names resolve to flag emojis', () {
    expect(nationFlagEmoji('Spain'), '🇪🇸');
    expect(nationFlagEmoji('England'), '🏴󠁧󠁢󠁥󠁮󠁧󠁿');
    expect(nationFlagEmoji('Korea Republic'), '🇰🇷');
    expect(nationFlagEmoji('Nowhere Land'), isNull);
  });
}
