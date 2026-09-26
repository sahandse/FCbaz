import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('1.7 reusable player item supports FC27 rarity families', () {
    final source = File(
      'lib/features/players/presentation/player_item_visual.dart',
    ).readAsStringSync();

    for (final token in [
      'icon',
      'hero',
      'totw',
      'hall of fut',
      'holographic',
      'gold',
      'silver',
      'bronze',
    ]) {
      expect(source.toLowerCase(), contains(token));
    }

    expect(source, contains("label: 'PS'"));
    expect(source, contains("label: 'PC'"));
    expect(source, contains("if (value <= 0) return '—'"));
  });

  test('1.7 Evolutions uses live FC27 lab layout', () {
    final source = File(
      'lib/features/evolutions/presentation/evolutions_screen.dart',
    ).readAsStringSync();

    expect(source, contains('FC27 • LIVE LAB'));
    expect(source, contains('EVOLUTION\\nLAB'));
    expect(source, contains('CHECK MY CLUB'));
    expect(source, contains('BEFORE / AFTER'));
    expect(source, contains('EvoEligibilityStatus.eligible'));
    expect(source, contains('EvolutionProjectionEngine'));
  });
}
