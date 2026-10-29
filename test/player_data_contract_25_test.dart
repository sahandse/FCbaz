import 'dart:convert';
import 'dart:io';

import 'package:fcbaz/features/players/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FC27 source camelCase fields survive JSON conversion', () {
    final player = Player.fromJson({
      'id': '231747',
      'name': 'Kylian Mbappé',
      'rating': 91,
      'position': 'ST',
      'positions': ['ST', 'LW'],
      'club': 'Real Madrid',
      'leagueFA': 'LALIGA EA SPORTS',
      'nat': 'France',
      'cardType': 'gold',
      'skillMoves': 5,
      'weakFoot': 4,
      'foot': 'Right',
      'playStyles': ['Finesse Shot', 'Rapid'],
      'playStylesPlus': ['Quick Step+'],
      'inGameStats': {'PAC': 96, 'SHO': 91, 'PAS': 80},
      'portraitUrl':
          'https://ratings-images-prod.pulse.ea.com/FC25/full/player-portraits/p231747.png?padding=0.7',
      'cardImageUrl':
          'https://ratings-images-prod.pulse.ea.com/FC27/components/items/231747_en-GB.webp',
      'price_ps': 3200000,
      'price_pc': 3450000,
    });

    expect(player.id, '231747');
    expect(player.positions, ['ST', 'LW']);
    expect(player.version.toLowerCase(), 'gold');
    expect(player.skillMoves, 5);
    expect(player.weakFoot, 4);
    expect(player.foot, 'Right');
    expect(player.playStyles, ['Finesse Shot', 'Rapid']);
    expect(player.playStylesPlus, ['Quick Step+']);
    expect(player.inGameStats['PAC'], 96);
    expect(player.imageUrl, contains('p231747.png'));
    expect(player.cardImageUrl, contains('/231747_en-GB.webp'));
    expect(player.pricePs, 3200000);
    expect(player.pricePc, 3450000);
  });

  test('missing portrait stays unavailable instead of guessing a URL', () {
    final player = Player.fromJson({
      'id': '123456',
      'name': 'No Portrait',
      'rating': 80,
      'position': 'CM',
    });

    expect(player.imageUrl, isEmpty);
  });

  test('zero and negative prices are never reported as real', () {
    final player = Player.fromJson({
      'id': '1',
      'name': 'No Price',
      'rating': 80,
      'position': 'CM',
      'price_ps': 0,
      'price_pc': -5,
    });

    expect(player.pricePs, 0);
    expect(player.pricePc, 0);
  });

  test(
    'bundled catalog keeps verified FC27 fields and per-platform prices',
    () async {
      final raw =
          jsonDecode(await File('data/live/catalog.json').readAsString())
              as Map<String, dynamic>;
      final players = (raw['players'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final byId = {for (final player in players) '${player['id']}': player};
      final mbappe = byId['231747'];
      expect(mbappe, isNotNull);
      expect(mbappe!['positions'], contains('LW'));
      expect((mbappe['playstyles'] as List), isNotEmpty);
      expect((mbappe['in_game_stats'] as Map)['PAC'], 96);
      expect(int.parse('${mbappe['price_ps']}'), greaterThan(0));
      expect(int.parse('${mbappe['price_pc']}'), greaterThan(0));

      var withPlayStyles = 0;
      var withStats = 0;
      for (final entry in players) {
        if (entry['playstyles'] is List &&
            (entry['playstyles'] as List).isNotEmpty) {
          withPlayStyles++;
        }
        if (entry['in_game_stats'] is Map &&
            (entry['in_game_stats'] as Map).isNotEmpty) {
          withStats++;
        }
        for (final key in ['price_ps', 'price_pc']) {
          final value = int.tryParse('${entry[key] ?? ''}') ?? 0;
          expect(value, greaterThanOrEqualTo(0));
        }
        final image = '${entry['image_url'] ?? ''}';
        expect(image.isEmpty || image.startsWith('https://'), isTrue);
        final card = '${entry['card_image_url'] ?? ''}';
        final cardId = RegExp(r'/items/(\d+)_en-GB\.webp$').firstMatch(card);
        if (cardId != null) {
          expect(cardId.group(1), '${entry['id']}');
        }
      }

      expect(withPlayStyles, greaterThan(1000));
      expect(withStats, greaterThanOrEqualTo(19000));
      expect(DateTime.tryParse('${raw['price_updated_at']}'), isNotNull);
      expect('${raw['price_source']}', isNotEmpty);
    },
  );
}
