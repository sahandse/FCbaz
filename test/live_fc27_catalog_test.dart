import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live FC27 catalog has verified non-empty sections', () async {
    final file = File('data/live/catalog.json');
    expect(await file.exists(), isTrue);

    final json = jsonDecode(await file.readAsString());
    expect(json, isA<Map>());
    final map = Map<String, dynamic>.from(json as Map);

    expect(map['game_year'], 27);
    expect(DateTime.tryParse((map['generated_at'] ?? '').toString()), isNotNull);

    final players = map['players'];
    expect(players, isA<List>());
    expect(players as List, isNotEmpty, reason: 'players must not be empty');
    final playerIds = <String>{};
    for (final value in players.whereType<Map>()) {
      final player = Map<String, dynamic>.from(value);
      final id = (player['id'] ?? '').toString();
      final name = (player['name'] ?? '').toString();
      final source = (player['source_url'] ?? '').toString();
      final rating = int.tryParse((player['rating'] ?? '').toString()) ?? 0;
      final position = (player['position'] ?? '').toString();
      expect(id, isNotEmpty);
      expect(name, isNotEmpty);
      expect(playerIds.add(id), isTrue, reason: 'duplicate player id: $id');
      expect(rating, inInclusiveRange(40, 99), reason: 'invalid rating: $name');
      expect(position, isNotEmpty, reason: 'missing position: $name');
      expect(
        source.startsWith('https://www.fut.gg/') ||
            source.startsWith('https://www.futbin.org/') ||
            source.startsWith('https://www.ea.com/'),
        isTrue,
        reason: 'player missing trusted real source: $name',
      );
    }

    for (final key in ['evolutions', 'sbcs', 'objectives']) {
      final raw = map[key];
      expect(raw, isA<List>(), reason: '$key must be a list');
      final items = raw as List;
      expect(items, isNotEmpty, reason: '$key must not be empty');

      final ids = <String>{};
      for (final value in items.whereType<Map>()) {
        final item = Map<String, dynamic>.from(value);
        final id = (item['id'] ?? '').toString();
        final title = (item['title'] ?? item['title_en'] ?? '').toString();
        final source = (item['source_url'] ?? '').toString();

        expect(id, isNotEmpty, reason: '$key item missing id');
        expect(title, isNotEmpty, reason: '$key item missing title');
        expect(ids.add(id), isTrue, reason: '$key duplicate id: $id');
        expect(
          source.startsWith('https://www.fut.gg/'),
          isTrue,
          reason: '$key item missing verified FUT.GG source: $title',
        );
      }
    }
  });
}
