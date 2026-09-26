import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production FC27 catalog is broad, sourced and non-placeholder', () async {
    final file = File('data/live/catalog.json');
    expect(await file.exists(), isTrue);

    final raw = jsonDecode(await file.readAsString());
    expect(raw, isA<Map>());
    final catalog = Map<String, dynamic>.from(raw as Map);
    expect(catalog['game_year'], 27);
    expect(DateTime.tryParse((catalog['generated_at'] ?? '').toString()), isNotNull);

    final players = (catalog['players'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    expect(players.length, greaterThanOrEqualTo(200));

    final ids = <String>{};
    var completeStatRows = 0;
    var specialCards = 0;
    final clubs = <String>{};
    final leagues = <String>{};
    final nations = <String>{};

    for (final player in players) {
      final id = (player['id'] ?? '').toString();
      final name = (player['name'] ?? '').toString().trim();
      final rating = int.tryParse((player['rating'] ?? '').toString()) ?? 0;
      final position = (player['position'] ?? '').toString().trim();
      final version = (player['version'] ?? '').toString().toLowerCase();
      final source = (player['source_url'] ?? '').toString();

      expect(id, isNotEmpty);
      expect(ids.add(id), isTrue, reason: 'duplicate player id: $id');
      expect(name, isNotEmpty);
      expect(name.toLowerCase(), isNot(anyOf('test', 'demo', 'placeholder', 'player')));
      expect(rating, inInclusiveRange(40, 99), reason: name);
      expect(position, isNotEmpty, reason: name);
      expect(source.startsWith('https://'), isTrue, reason: 'missing source: $name');

      final stats = [
        'pace',
        'shooting',
        'passing',
        'dribbling',
        'defending',
        'physical',
      ].map((key) => int.tryParse((player[key] ?? '').toString()) ?? 0).toList();
      if (stats.where((value) => value > 0).length >= 5) completeStatRows++;

      if (!version.contains('gold') &&
          !version.contains('silver') &&
          !version.contains('bronze')) {
        specialCards++;
      }

      final club = (player['club_name'] ?? '').toString().trim();
      final league = (player['league_name'] ?? '').toString().trim();
      final nation = (player['nation_name'] ?? '').toString().trim();
      if (club.isNotEmpty) clubs.add(club);
      if (league.isNotEmpty) leagues.add(league);
      if (nation.isNotEmpty) nations.add(nation);
    }

    expect(completeStatRows, greaterThanOrEqualTo(100));
    expect(specialCards, greaterThanOrEqualTo(10));
    expect(clubs.length, greaterThanOrEqualTo(20));
    expect(leagues.length, greaterThanOrEqualTo(5));
    expect(nations.length, greaterThanOrEqualTo(20));

    for (final key in ['sbcs', 'evolutions', 'objectives']) {
      final items = (catalog[key] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      expect(items, isNotEmpty, reason: '$key must contain real FC27 data');
      final sectionIds = <String>{};
      for (final item in items) {
        final id = (item['id'] ?? '').toString();
        final source = (item['source_url'] ?? '').toString();
        expect(id, isNotEmpty);
        expect(sectionIds.add(id), isTrue, reason: '$key duplicate id: $id');
        expect(source.startsWith('https://www.fut.gg/'), isTrue);
      }
    }
  });
}
