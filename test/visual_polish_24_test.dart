import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/players/presentation/player_market_tile.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/ui/state_views.dart';

Player _player() => const Player(
  id: '1',
  name: 'Alexia Putellas',
  rating: 91,
  position: 'CM',
  positions: ['CM'],
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
  pricePs: 846000,
  pricePc: 904000,
);

Future<void> _pumpTile(
  WidgetTester tester, {
  String? heroTag,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? FCBazTheme.dark(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              height: 320,
              child: PlayerMarketTile(
                player: _player(),
                heroTag: heroTag,
              ),
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

  test('collection tiles opt into a shared-element tag', () {
    final source = File(
      'lib/features/players/presentation/cards_screen.dart',
    ).readAsStringSync();
    final details = File(
      'lib/features/players/presentation/player_details_screen.dart',
    ).readAsStringSync();

    expect(source, contains('heroTag: playerHeroTag('));
    expect(details, contains('tag: playerHeroTag(player.id)'));
  });

  test('item artwork decodes at paint size and shows a placeholder', () {
    final source = File(
      'lib/features/players/presentation/player_item_visual.dart',
    ).readAsStringSync();

    expect(source, contains('cacheWidth: cacheWidth'));
    expect(source, contains('loadingBuilder:'));
    expect(source, contains('_ArtworkSkeleton'));
    expect(source, contains('FontFeature.tabularFigures()'));
  });

  testWidgets('tile renders a Hero only when a tag is provided', (tester) async {
    await _pumpTile(tester);
    expect(find.byType(Hero), findsNothing);

    await _pumpTile(tester, heroTag: 'fc27-player-card-1');
    expect(find.byType(Hero), findsOneWidget);
    expect(
      tester.widget<Hero>(find.byType(Hero)).tag,
      'fc27-player-card-1',
    );
  });

  testWidgets('price and stats use tabular figures', (tester) async {
    await _pumpTile(tester);

    final price = tester.widget<Text>(find.text('۸۴۶,۰۰۰'));
    expect(
      price.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );

    final stat = tester.widget<Text>(find.text('۹۶'));
    expect(
      stat.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('grid skeleton matches the collection grid ratio', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FCBazTheme.dark(),
        home: const Scaffold(
          body: SingleChildScrollView(child: PlayerGridSkeleton(count: 2)),
        ),
      ),
    );

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.childAspectRatio, .5);
  });

  test('light theme separates white cards from the canvas', () {
    final light = FCBazTheme.light();
    final dark = FCBazTheme.dark();
    final lightPalette = light.extension<FcbazPalette>()!;

    expect(light.cardTheme.elevation, greaterThan(0));
    expect(dark.cardTheme.elevation, 0);
    expect(lightPalette.line, isNot(const Color(0xFFD3DBC9)));
  });
}
