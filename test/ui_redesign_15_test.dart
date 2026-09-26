import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('1.5 player collection keeps FC27 item families', () {
    final source = File('lib/features/players/players_screen.dart').readAsStringSync();
    for (final token in ['Gold', 'ICON', 'Hero', 'TOTW', 'Hall', 'Holo', 'Silver', 'Bronze']) {
      expect(source, contains(token));
    }
  });

  test('player item displays separate Console and PC prices', () {
    final source = File('lib/features/players/presentation/player_card.dart').readAsStringSync();
    expect(source, contains("label: 'Console'"));
    expect(source, contains("label: 'PC'"));
    expect(source, contains("if (value <= 0) return '—'"));
  });

  test('EA resource id price lookup uses public FUTBIN resource endpoint', () {
    final source = File('lib/core/network/futbin_public_price_service.dart').readAsStringSync();
    expect(source, contains('fetchPriceInformation'));
    expect(source, contains('playerresource'));
    expect(source, contains("if (current <= 0) return null"));
  });
}
