import '../../../src/utils/persian_formatters.dart';

enum SbcRewardKind { coins, packs, mixed, playerCard, unknown }

enum SbcValueLevel { good, fair, poor, unknown }

class SbcValueAssessment {
  const SbcValueAssessment({
    required this.cost,
    required this.rewardCoins,
    required this.kind,
    required this.ratio,
    required this.level,
    required this.headlineFa,
    required this.detailFa,
  });

  final int? cost;
  final int rewardCoins;
  final SbcRewardKind kind;
  final double? ratio;
  final SbcValueLevel level;
  final String headlineFa;
  final String detailFa;
}

/// Compares only what the source actually states: an estimated coin cost and
/// any coin amount inside the reward text. Packs and player cards have no
/// fixed price, so their value stays explicitly unknown instead of guessed.
class SbcValueAdvisor {
  const SbcValueAdvisor();

  static int parseCoins(String raw) {
    if (raw.trim().isEmpty) return 0;
    final normalized = raw
        .replaceAllMapped(
          RegExp('[۰-۹]'),
          (match) => '${match.group(0)!.codeUnitAt(0) - 0x06F0}',
        )
        .replaceAll('٫', '.')
        .replaceAll(RegExp('[،,]'), '');
    final pattern = RegExp(
      r'(\d+(?:\.\d+)?)\s*(k|m|هزار|میلیون)?\s*(?:سکه|coins?)',
      caseSensitive: false,
    );
    var total = 0;
    for (final match in pattern.allMatches(normalized)) {
      final amount = double.tryParse(match.group(1)!);
      if (amount == null) continue;
      final unit = (match.group(2) ?? '').toLowerCase();
      final multiplier = unit == 'k' || unit == 'هزار'
          ? 1000
          : unit == 'm' || unit == 'میلیون'
          ? 1000000
          : 1;
      total += (amount * multiplier).round();
    }
    return total;
  }

  SbcValueAssessment assess({
    required int? cost,
    required String reward,
    required String category,
    required String title,
  }) {
    final coins = parseCoins(reward);
    final hasPack =
        reward.contains('بسته') ||
        RegExp(r'\bpack', caseSensitive: false).hasMatch(reward) ||
        reward.contains('Player Pick') ||
        reward.contains('انتخاب بازیکن');
    final isPlayerChallenge =
        category.trim().toLowerCase() == 'players' ||
        category.contains('Primary Player');

    final SbcRewardKind kind;
    if (coins > 0 && hasPack) {
      kind = SbcRewardKind.mixed;
    } else if (coins > 0) {
      kind = SbcRewardKind.coins;
    } else if (hasPack) {
      kind = SbcRewardKind.packs;
    } else if (isPlayerChallenge) {
      kind = SbcRewardKind.playerCard;
    } else {
      kind = SbcRewardKind.unknown;
    }

    if (cost == null || cost <= 0) {
      return SbcValueAssessment(
        cost: null,
        rewardCoins: coins,
        kind: kind,
        ratio: null,
        level: SbcValueLevel.unknown,
        headlineFa: 'هزینهٔ ساخت نامشخص',
        detailFa:
            'منبع، هزینهٔ تخمینی برای این چالش برنگردانده است؛ FCBaz عددی جایگزین نمی‌سازد.',
      );
    }

    if (kind == SbcRewardKind.playerCard) {
      final name = title.trim().isEmpty ? 'این چالش' : title.trim();
      return SbcValueAssessment(
        cost: cost,
        rewardCoins: coins,
        kind: kind,
        ratio: null,
        level: SbcValueLevel.unknown,
        headlineFa: 'قیمت کارت جایزه نامشخص',
        detailFa:
            'جایزهٔ $name یک کارت ویژه است و قیمت آن کارت در منبع بازار موجود نیست؛ '
            'هزینهٔ تخمینی ${formatCoinsFa(cost)} سکه با ارزش کارت پایه مقایسه نمی‌شود.',
      );
    }

    if (kind == SbcRewardKind.packs ||
        kind == SbcRewardKind.unknown ||
        coins <= 0) {
      return SbcValueAssessment(
        cost: cost,
        rewardCoins: coins,
        kind: kind,
        ratio: null,
        level: SbcValueLevel.unknown,
        headlineFa: 'ارزش پاداش نامشخص',
        detailFa:
            'پاداش این چالش بستهٔ بازیکن یا آیتم بدون قیمت ثابت است؛ '
            'ارزش ساختگی برای آن محاسبه نمی‌شود. هزینهٔ تخمینی: ${formatCoinsFa(cost)} سکه.',
      );
    }

    final ratio = coins / cost;
    final percent = (ratio * 100).round();
    final SbcValueLevel level;
    if (ratio >= 1) {
      level = SbcValueLevel.good;
    } else if (ratio >= .5) {
      level = SbcValueLevel.fair;
    } else {
      level = SbcValueLevel.poor;
    }
    final packNote = kind == SbcRewardKind.mixed
        ? ' بسته‌های همراه در این نسبت لحاظ نشده‌اند.'
        : '';
    return SbcValueAssessment(
      cost: cost,
      rewardCoins: coins,
      kind: kind,
      ratio: ratio,
      level: level,
      headlineFa: 'بازگشت نقدی ${faDigits(percent)}٪',
      detailFa:
          'پاداش نقدی ${formatCoinsFa(coins)} سکه در برابر هزینهٔ تخمینی '
          '${formatCoinsFa(cost)} سکه.$packNote',
    );
  }
}
