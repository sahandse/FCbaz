import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('1.9 live catalog contains sourced positive FC27 prices', () {
    final catalog = jsonDecode(File('data/live/catalog.json').readAsStringSync())
        as Map<String, dynamic>;
    final players = (catalog['players'] as List).cast<Map<String, dynamic>>();
    final priced = players.where((player) {
      final price = (player['price_ps'] ?? player['market_price'] ?? 0) as num;
      return price > 0;
    }).toList();

    expect(priced, isNotEmpty);
    const providers = {'fut.gg-public', 'fcdata-public'};
    for (final player in priced) {
      expect(
        providers,
        contains((player['price_source'] ?? '').toString()),
        reason: '${player['name']} publishes a price without a verified source',
      );
      expect((player['price_ps'] as num), greaterThan(0));
    }

    // Cards without a verified quote stay at zero instead of showing a guess.
    final unavailable = players.where(
      (player) => player['price_status'] == 'unavailable',
    );
    expect(unavailable, isNotEmpty);
    for (final player in unavailable) {
      expect((player['price_ps'] as num?) ?? 0, 0);
      expect((player['price_pc'] as num?) ?? 0, 0);
    }
  });

  test('1.9 SBC catalog keeps real sourced requirements and public guides', () {
    final catalog = jsonDecode(File('data/live/catalog.json').readAsStringSync())
        as Map<String, dynamic>;
    final sbcs = (catalog['sbcs'] as List).cast<Map<String, dynamic>>();
    final guided = sbcs.where((sbc) {
      final requirements = sbc['requirements'];
      final guide = sbc['guide_fa'];
      final challenges = sbc['challenges'];
      return (requirements is List && requirements.isNotEmpty) ||
          (guide is List && guide.isNotEmpty) ||
          (challenges is List && challenges.isNotEmpty);
    }).toList();

    expect(guided, isNotEmpty);
    for (final sbc in guided) {
      expect((sbc['source_url'] as String? ?? '').startsWith('https://www.fut.gg/'), isTrue);
    }
  });

  test('1.9 SBC UI offers public guide instead of backend-only solution', () {
    final source = File('lib/features/sbc/presentation/sbc_screen.dart').readAsStringSync();
    final repository = File('lib/features/sbc/data/sbc_repository.dart').readAsStringSync();

    expect(source, contains('نمایش راه‌حل و راهنمای عمومی'));
    expect(source, contains("solution.players.isEmpty ? 'PUBLIC GUIDE' : 'SOLUTION'"));
    expect(repository, contains("item['public_solution']"));
    expect(repository, contains('داده ساختگی نمایش داده نمی‌شود'));
  });

  test('1.9 player item labels PlayStation source accurately', () {
    final source = File('lib/features/players/presentation/player_item_visual.dart').readAsStringSync();
    expect(source, contains('_Price('));
    expect(source, contains("label: 'PS'"));
    expect(source, contains("label: 'PC'"));
    expect(source, contains("if (value <= 0) return '—'"));
  });

  test('2.3 version is production increment', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version: (\d+)\.(\d+)\.(\d+)\+(\d+)$',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull);
    final major = int.parse(match!.group(1)!);
    final minor = int.parse(match.group(2)!);
    expect(major, greaterThanOrEqualTo(2));
    expect(minor, greaterThanOrEqualTo(3));
    expect(int.parse(match.group(4)!), greaterThanOrEqualTo(40));
  });
}
