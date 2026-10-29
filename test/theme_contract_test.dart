import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/players/presentation/player_market_tile.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';

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
  skillMoves: 5,
  weakFoot: 5,
  pricePs: 846000,
  pricePc: 904000,
);

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + .05) / (min(la, lb) + .05);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('both palettes keep text readable on surfaces', () {
    for (final palette in [FcbazPalette.dark, FcbazPalette.light]) {
      expect(_contrast(palette.text, palette.canvas), greaterThanOrEqualTo(7));
      expect(
        _contrast(palette.text, palette.surface),
        greaterThanOrEqualTo(7),
      );
      expect(
        _contrast(palette.textMuted, palette.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(palette.textMuted, palette.surfaceRaised),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(palette.onPrimary, palette.primary),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('feature screens no longer hardcode the dark-only palette', () {
    const forbidden = [
      '0xFFCAFF38',
      '0xFF0A100B',
      '0xFF090E0A',
      '0xFF101A12',
      '0xFF131F15',
      '0xFF0F1710',
      '0xFF0F1511',
      '0xFF162319',
      '0xFF132A17',
      '0xFF071014',
      '0xFF0C120D',
      '0xFF070B08',
    ];
    final offenders = <String>[];
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final literal in forbidden) {
        if (source.contains(literal)) {
          offenders.add('${entity.path}: $literal');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  testWidgets('market tile uses the active theme surfaces', (tester) async {
    final theme = FCBazTheme.light();
    final palette = theme.extension<FcbazPalette>()!;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                height: 320,
                child: PlayerMarketTile(player: _player()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('player-market-tile-surface')),
    );
    final gradient = (surface.decoration as BoxDecoration).gradient;
    expect(gradient, isA<LinearGradient>());
    expect(
      (gradient as LinearGradient).colors,
      [palette.surfaceRaised, palette.surface],
    );
  });
}
