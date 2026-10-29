import 'dart:convert';
import 'dart:io';

import 'package:fcbaz/features/players/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _catalog() =>
    jsonDecode(File('data/live/catalog.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('Hall of FUT cards carry their verified item artwork', () {
    final catalog = _catalog();
    final players = (catalog['players'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final hof = players
        .where((p) => '${p['card_type']}'.toLowerCase().contains('hall of fut'))
        .toList();

    expect(hof, isNotEmpty);
    // FUT.GG lists one item per inductee; the catalogue used to publish each
    // card twice (Gallery label and campaign label), so guard the dedupe.
    final identities = hof
        .map((p) => '${p['name']}|${p['rating']}|${p['position']}')
        .toSet();
    expect(identities, hasLength(hof.length));
    final artwork = RegExp(
      r'^https://game-assets\.fut\.gg/2027/futgg-player-item-card/'
      r'27-\d+\.[0-9a-f]{64}\.webp$',
    );
    for (final entry in hof) {
      final player = Player.fromJson(entry);
      expect(
        player.cardArtUrl,
        matches(artwork),
        reason: '${player.name} has no resolved Hall of FUT artwork',
      );
      // Gallery items have no verified market quote, so a placeholder coin
      // value must never be shown as if it were a real price.
      expect(
        player.pricePs,
        0,
        reason: '${player.name} must not publish an unverified price',
      );
    }
  });

  test('the bundled catalog records when its coin prices were refreshed', () {
    final catalog = _catalog();
    expect(DateTime.tryParse('${catalog['price_updated_at']}'), isNotNull);
    expect(catalog['price_source'], isA<String>());
  });
}
