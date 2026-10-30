import 'package:fcbaz/features/evolutions/domain/evolution.dart';
import 'package:fcbaz/features/evolutions/domain/evolution_eligibility_engine.dart';
import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/players/domain/player_usage_service.dart';
import 'package:fcbaz/features/sbc/domain/sbc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = PlayerUsageService();

  Player player({
    int rating = 80,
    String position = 'RW',
    String version = 'Gold Rare',
  }) => Player(
    id: 'p1',
    name: 'Test Player',
    rating: rating,
    position: position,
    positions: [position],
    clubName: 'Club',
    leagueName: 'League',
    nationName: 'Nation',
    version: version,
    imageUrl: '',
    pace: 80,
    shooting: 80,
    passing: 80,
    dribbling: 80,
    defending: 40,
    physical: 70,
    skillMoves: 3,
    weakFoot: 3,
  );

  Evolution evolutionWithRequirements() => Evolution.fromJson({
    'id': 'evo-1',
    'title': 'Evo One',
    'requirements_raw': [
      {'type': 'overall', 'max': 84},
      {
        'type': 'position',
        'values': ['RM', 'RW'],
      },
    ],
  });

  SbcChallenge sbc(List<String> requirements, {String id = 'sbc-1'}) =>
      SbcChallenge.fromJson({
        'id': id,
        'title': 'SBC $id',
        'requirements': requirements,
      });

  group('evolution usage', () {
    test('reuses the shared eligibility engine for positive results', () {
      final match = service.evaluateEvolution(
        player(rating: 84),
        evolutionWithRequirements(),
      );
      expect(match.status, EvoEligibilityStatus.eligible);
      expect(match.reasons, ['همه شروط قابل‌تشخیص پاس شده‌اند.']);
    });

    test('reports a rating above the maximum as ineligible', () {
      final match = service.evaluateEvolution(
        player(rating: 85),
        evolutionWithRequirements(),
      );
      expect(match.status, EvoEligibilityStatus.ineligible);
      expect(match.reasons.join(' '), contains('سازگار نیست'));
    });

    test('reports a position outside the allowed list as ineligible', () {
      final match = service.evaluateEvolution(
        player(position: 'ST'),
        evolutionWithRequirements(),
      );
      expect(match.status, EvoEligibilityStatus.ineligible);
      expect(match.reasons.join(' '), contains('پست'));
    });
  });

  group('SBC card rules', () {
    test('passes a global rating minimum and keeps squad lines separate', () {
      final match = service.evaluateSbc(
        player(rating: 80),
        sbc(['Rating: Min. 79', 'Min. 5 Gold players']),
      );
      expect(match.fit, PlayerSbcFit.cardRulesPassed);
      expect(match.checks, hasLength(1));
      expect(match.checks.first.passed, isTrue);
      expect(match.squadRequirements, ['Min. 5 Gold players']);
    });

    test('blocks a card below the global rating minimum', () {
      final match = service.evaluateSbc(
        player(rating: 78),
        sbc(['Rating: Min. 79']),
      );
      expect(match.fit, PlayerSbcFit.blocked);
      expect(match.blocker, contains('کمتر از حداقل 79'));
      expect(match.checks.single.passed, isFalse);
    });

    test('reads a Persian rating range and blocks outside values', () {
      final passing = service.evaluateSbc(
        player(rating: 70),
        sbc(['امتیاز بازیکن بین ۴۵ تا ۷۴', 'حداقل امتیاز تیم: ۷۵']),
      );
      expect(passing.fit, PlayerSbcFit.cardRulesPassed);
      expect(passing.squadRequirements, ['حداقل امتیاز تیم: ۷۵']);

      final failing = service.evaluateSbc(
        player(rating: 80),
        sbc(['امتیاز بازیکن بین ۴۵ تا ۷۴']),
      );
      expect(failing.fit, PlayerSbcFit.blocked);
      expect(failing.blocker, contains('بازهٔ مجاز 45 تا 74'));
    });

    test('reads the Persian per-card minimum', () {
      expect(
        service
            .evaluateSbc(player(rating: 79), sbc(['حداقل امتیاز بازیکن: ۷۹']))
            .fit,
        PlayerSbcFit.cardRulesPassed,
      );
      final failing = service.evaluateSbc(
        player(rating: 78),
        sbc(['حداقل امتیاز بازیکن: ۷۹']),
      );
      expect(failing.fit, PlayerSbcFit.blocked);
      expect(failing.blocker, contains('حداقل 79'));
    });

    test('judges exact quality filters from the card label', () {
      final rule = ['فقط بازیکن طلایی'];
      expect(
        service.evaluateSbc(player(version: 'Gold Rare'), sbc(rule)).fit,
        PlayerSbcFit.cardRulesPassed,
      );
      final failing = service.evaluateSbc(player(version: 'Silver'), sbc(rule));
      expect(failing.fit, PlayerSbcFit.blocked);
      expect(failing.blocker, contains('کیفیت کارت'));
    });

    test('marks unreadable card quality as needing review', () {
      final match = service.evaluateSbc(
        player(version: ''),
        sbc(['فقط بازیکن طلایی']),
      );
      expect(match.fit, PlayerSbcFit.needsReview);
      expect(match.unverifiedRules, ['فقط بازیکن طلایی']);
      expect(match.blocker, contains('دستی بررسی شود'));
    });

    test('reads English minimum quality filters', () {
      final match = service.evaluateSbc(
        player(version: 'Silver'),
        sbc(['Quality: Min. Gold']),
      );
      expect(match.fit, PlayerSbcFit.blocked);
      expect(match.blocker, contains('کیفیت کارت'));
    });

    test('keeps squad-only SBCs as needing review', () {
      final match = service.evaluateSbc(
        player(),
        sbc(['حداقل امتیاز تیم: ۷۵', 'حداقل ۵ بازیکن طلایی']),
      );
      expect(match.fit, PlayerSbcFit.needsReview);
      expect(match.checks, isEmpty);
      expect(match.squadRequirements, hasLength(2));
      expect(match.blocker, contains('به ترکیب وابسته‌اند'));
    });
  });
}
