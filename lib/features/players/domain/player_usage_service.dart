import '../../club/data/my_club_repository.dart';
import '../../evolutions/domain/evolution.dart';
import '../../evolutions/domain/evolution_eligibility_engine.dart';
import '../../sbc/domain/sbc.dart';
import 'player.dart';

enum PlayerSbcFit { cardRulesPassed, blocked, needsReview }

class SbcCardRuleCheck {
  const SbcCardRuleCheck({
    required this.rule,
    required this.passed,
    required this.detail,
  });

  final String rule;
  final bool passed;
  final String detail;
}

class PlayerSbcMatch {
  const PlayerSbcMatch({
    required this.challenge,
    required this.fit,
    required this.checks,
    required this.squadRequirements,
    required this.unverifiedRules,
    this.blocker,
  });

  final SbcChallenge challenge;
  final PlayerSbcFit fit;
  final List<SbcCardRuleCheck> checks;
  final List<String> squadRequirements;
  final List<String> unverifiedRules;
  final String? blocker;
}

class PlayerEvoMatch {
  const PlayerEvoMatch({
    required this.evolution,
    required this.status,
    required this.reasons,
  });

  final Evolution evolution;
  final EvoEligibilityStatus status;
  final List<String> reasons;
}

/// Decides where a single card can actually be used.
///
/// SBC data mixes per-card limits with squad-level rules. Only unambiguous
/// per-card rules (global rating bounds and single-tier quality filters) are
/// judged automatically; everything else is reported as a squad requirement
/// instead of being guessed.
class PlayerUsageService {
  const PlayerUsageService();

  PlayerEvoMatch evaluateEvolution(
    Player player,
    Evolution evolution, {
    EvolutionEligibilityEngine engine = const EvolutionEligibilityEngine(),
  }) {
    final item = MyClubItem.fromPlayer(player, acquisitionPrice: 0);
    final result = engine.evaluate(item, evolution);
    return PlayerEvoMatch(
      evolution: evolution,
      status: result.status,
      reasons: result.reasons,
    );
  }

  PlayerSbcMatch evaluateSbc(Player player, SbcChallenge challenge) {
    final checks = <SbcCardRuleCheck>[];
    final squadOnly = <String>[];
    final unverified = <String>[];
    String? blocker;

    for (final line in challenge.requirements) {
      final normalized = _normalizeDigits(line).trim();
      if (normalized.isEmpty) continue;

      final ratingRule = _ratingRule(normalized);
      if (ratingRule != null) {
        final (min, max) = ratingRule;
        final passed =
            player.rating >= min && (max == null || player.rating <= max);
        final detail = max == null
            ? 'ریتینگ ${player.rating} در برابر حداقل $min'
            : 'ریتینگ ${player.rating} در برابر بازهٔ $min تا $max';
        checks.add(
          SbcCardRuleCheck(rule: line, passed: passed, detail: detail),
        );
        if (!passed && blocker == null) {
          blocker = max == null
              ? 'ریتینگ ${player.rating} کمتر از حداقل $min این SBC است.'
              : 'ریتینگ ${player.rating} بیرون از بازهٔ مجاز $min تا $max این SBC است.';
        }
        continue;
      }

      final qualityRule = _qualityRule(normalized);
      if (qualityRule != null) {
        final (requiredTier, exact) = qualityRule;
        final tier = _qualityTier(player);
        if (tier == null) {
          unverified.add(line);
          continue;
        }
        final passed = exact ? tier == requiredTier : tier >= requiredTier;
        checks.add(
          SbcCardRuleCheck(
            rule: line,
            passed: passed,
            detail: passed
                ? 'کیفیت کارت با شرط هم‌خوان است'
                : 'کیفیت کارت با شرط هم‌خوان نیست',
          ),
        );
        if (!passed && blocker == null) {
          blocker = 'کیفیت کارت با شرط «${line.trim()}» هم‌خوان نیست.';
        }
        continue;
      }

      squadOnly.add(line);
    }

    if (blocker != null) {
      return PlayerSbcMatch(
        challenge: challenge,
        fit: PlayerSbcFit.blocked,
        checks: List.unmodifiable(checks),
        squadRequirements: List.unmodifiable(squadOnly),
        unverifiedRules: List.unmodifiable(unverified),
        blocker: blocker,
      );
    }

    if (unverified.isNotEmpty) {
      return PlayerSbcMatch(
        challenge: challenge,
        fit: PlayerSbcFit.needsReview,
        checks: List.unmodifiable(checks),
        squadRequirements: List.unmodifiable(squadOnly),
        unverifiedRules: List.unmodifiable(unverified),
        blocker:
            'کیفیت کارت از داده قابل تشخیص نیست؛ شرط «${unverified.first.trim()}» دستی بررسی شود.',
      );
    }

    if (checks.isEmpty) {
      return PlayerSbcMatch(
        challenge: challenge,
        fit: PlayerSbcFit.needsReview,
        checks: const [],
        squadRequirements: List.unmodifiable(squadOnly),
        unverifiedRules: const [],
        blocker:
            'همهٔ شرط‌های این SBC به ترکیب وابسته‌اند و به‌تنهایی قابل تأیید نیست.',
      );
    }

    return PlayerSbcMatch(
      challenge: challenge,
      fit: PlayerSbcFit.cardRulesPassed,
      checks: List.unmodifiable(checks),
      squadRequirements: List.unmodifiable(squadOnly),
      unverifiedRules: const [],
    );
  }

  (int, int?)? _ratingRule(String line) {
    var match = RegExp(
      r'^rating:\s*min\.?\s*(\d+)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (match != null) return (int.parse(match.group(1)!), null);

    match = RegExp(
      r'^rating:\s*(\d+)\s*(?:-|to)\s*(\d+)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (match != null) {
      return (int.parse(match.group(1)!), int.parse(match.group(2)!));
    }

    match = RegExp(r'^حداقل امتیاز بازیکن:\s*(\d+)$').firstMatch(line);
    if (match != null) return (int.parse(match.group(1)!), null);

    match = RegExp(
      r'^امتیاز بازیکن بین\s*(\d+)\s*تا\s*(\d+)$',
    ).firstMatch(line);
    if (match != null) {
      return (int.parse(match.group(1)!), int.parse(match.group(2)!));
    }

    return null;
  }

  (int, bool)? _qualityRule(String line) {
    var match = RegExp(
      r'^quality:\s*(gold|silver|bronze)\s*only$',
      caseSensitive: false,
    ).firstMatch(line);
    if (match != null) return (_tierOf(match.group(1)!), true);

    match = RegExp(
      r'^quality:\s*min\.?\s*(gold|silver|bronze)$',
      caseSensitive: false,
    ).firstMatch(line);
    if (match != null) return (_tierOf(match.group(1)!), false);

    match = RegExp(r'^فقط بازیکن (طلایی|نقره‌ای|برنزی)$').firstMatch(line);
    if (match != null) return (_tierOf(match.group(1)!), true);

    match = RegExp(
      r'^حداقل کیفیت:\s*بازیکن (طلایی|نقره‌ای|برنزی)$',
    ).firstMatch(line);
    if (match != null) return (_tierOf(match.group(1)!), false);

    return null;
  }

  int _tierOf(String raw) {
    final value = raw.toLowerCase();
    if (value == 'gold' || value == 'طلایی') return 2;
    if (value == 'silver' || value == 'نقره‌ای') return 1;
    return 0;
  }

  int? _qualityTier(Player player) {
    final label = '${player.version} ${player.rarity} ${player.cardType}'
        .toLowerCase();
    if (label.contains('bronze')) return 0;
    if (label.contains('silver')) return 1;
    if (label.contains('gold')) return 2;
    return null;
  }

  String _normalizeDigits(String value) {
    return value.replaceAllMapped(
      RegExp('[۰-۹]'),
      (match) => '${match.group(0)!.codeUnitAt(0) - 0x06F0}',
    );
  }
}
