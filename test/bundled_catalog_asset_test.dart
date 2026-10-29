import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the live catalog is bundled from its single source path', () async {
    final raw = await rootBundle.loadString('data/live/catalog.json');
    final catalog = jsonDecode(raw) as Map<String, dynamic>;

    expect(catalog['game_year'], 27);
    expect(catalog['players'], isA<List<dynamic>>());
    expect(catalog['players'], isNotEmpty);
    expect(catalog['sbcs'], isA<List<dynamic>>());
  });
}
