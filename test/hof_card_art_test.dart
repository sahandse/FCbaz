import 'dart:convert';
import 'dart:io';

import 'package:fcbaz/features/players/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _catalog() =>
    jsonDecode(File('assets/data/catalog.json').readAsStringSync())
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
    }
  });

  test('the bundled catalog records when its coin prices were refreshed', () {
    final catalog = _catalog();
    expect(DateTime.tryParse('${catalog['price_updated_at']}'), isNotNull);
    expect(catalog['price_source'], isA<String>());
  });
}
