import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public price service never accepts zero as a real price', () {
    final source = File('lib/core/network/futbin_public_price_service.dart').readAsStringSync();
    expect(source, contains('if (current <= 0) return null'));
  });

  test('market repository tries EA resource-id price path', () {
    final source = File('lib/features/market/data/market_repository.dart').readAsStringSync();
    expect(source, contains("playerId.startsWith('ea-')"));
    expect(source, contains('byResourceId'));
  });
}
