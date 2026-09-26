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
