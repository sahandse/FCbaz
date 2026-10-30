import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../src/share/share_card.dart';
import '../../../src/share/share_service.dart';
import '../../../src/theme/fcbaz_theme.dart';
import '../../../src/utils/persian_formatters.dart';
import '../domain/sbc_shopping_list.dart';

class SbcShoppingListSheet extends StatelessWidget {
  const SbcShoppingListSheet({
    required this.list,
    this.title = 'لیست خرید SBC',
    super.key,
  });

  final SbcShoppingList list;
  final String title;

  Future<void> _copy(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: list.toShareText()));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('متن لیست خرید کپی شد.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('کپی متن ممکن نشد.')));
    }
  }

  Future<void> _share(BuildContext context) async {
    final text = list.toShareText();
    final budget = list.budget;
    String? budgetLabel;
    String? budgetValue;
    if (budget != null) {
      if (list.withinBudget) {
        budgetLabel = 'باقی بودجه';
        budgetValue = formatCoinsFa(list.remainingBudget!);
      } else if (list.shortfall != null) {
        budgetLabel = 'کمبود';
        budgetValue = formatCoinsFa(list.shortfall!);
      } else {
        budgetLabel = 'بودجه';
        budgetValue = formatCoinsFa(budget);
      }
    }

    final data = ShareCardData(
      eyebrow: 'FCBAZ • SBC',
      title: title,
      subtitle:
          'ریتینگ هدف ${faDigits(list.targetRating)} • ${list.platformLabel}',
      metrics: [
        ShareCardMetric(
          label: list.hasCompletePrices ? 'جمع خرید' : 'جمع شناخته‌شده',
          value: '${formatCoinsFa(list.knownCost)} سکه',
        ),
        if (budgetLabel != null && budgetValue != null)
          ShareCardMetric(label: budgetLabel, value: '$budgetValue سکه'),
      ],
      rows: [
        for (final item in list.items)
          ShareCardRow(
            position: '×${faDigits(item.count)}',
            name: item.candidate.playerName,
            rating: item.rating,
          ),
      ],
      footer: 'FCBaz • قیمت واقعی بازار • بدون مالیات فروش',
    );

    ShareOutcome outcome;
    try {
      final png = await const ShareCardRenderer().renderPng(data);
      outcome = await ShareService().shareImage(
        pngBytes: png,
        fileName: 'fcbaz-sbc-shopping.png',
        fallbackText: text,
      );
    } catch (_) {
      try {
        await Clipboard.setData(ClipboardData(text: text));
        outcome = ShareOutcome.copiedToClipboard;
      } catch (_) {
        outcome = ShareOutcome.unavailable;
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome == ShareOutcome.shared
              ? 'پنجره اشتراک‌گذاری باز شد.'
              : outcome == ShareOutcome.copiedToClipboard
              ? 'اشتراک تصویری ممکن نشد؛ متن لیست خرید کپی شد.'
              : 'اشتراک‌گذاری لیست خرید ممکن نشد.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final budget = list.budget;
    final budgetText = budget == null
        ? 'بدون سقف'
        : list.withinBudget
        ? 'باقی ${formatCoinsFa(list.remainingBudget!)}'
        : list.shortfall != null
        ? 'کمبود ${formatCoinsFa(list.shortfall!)}'
        : 'نامشخص';

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(FcbazRadius.sm),
                  ),
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    size: 19,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'ریتینگ هدف ${faDigits(list.targetRating)} • '
                        'بازار ${list.platformLabel}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'خرید لازم',
                    value: '${faDigits(list.purchaseCount)} کارت',
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _SummaryTile(
                    label: list.hasCompletePrices
                        ? 'جمع خرید'
                        : 'جمع شناخته‌شده',
                    value: '${formatCoinsFa(list.knownCost)} سکه',
                    emphasized: true,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _SummaryTile(
                    label: budget == null ? 'بودجه' : 'وضعیت بودجه',
                    value: budgetText,
                    color: budget == null
                        ? null
                        : list.withinBudget
                        ? palette.success
                        : list.shortfall != null
                        ? palette.danger
                        : palette.warning,
                  ),
                ),
              ],
            ),
            if (list.ownedCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${faDigits(list.ownedCount)} جایگاه از کلوب تأمین می‌شود و در خرید حساب نشده است.',
                style: TextStyle(fontSize: 10, color: palette.textMuted),
              ),
            ],
            const SizedBox(height: 12),
            if (list.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: BorderRadius.circular(FcbazRadius.md),
                  border: Border.all(color: palette.line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: palette.success),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'خرید لازم نیست؛ همه جایگاه‌های این ترکیب از کلوب تأمین می‌شوند.',
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              for (final item in list.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(FcbazRadius.sm),
                      border: Border.all(color: palette.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: palette.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            faDigits(item.rating),
                            style: TextStyle(
                              color: palette.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${faDigits(item.count)}× ${item.candidate.playerName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'واحد ${formatCoinsFa(item.unitPrice)} سکه',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${formatCoinsFa(item.totalPrice)} سکه',
                          style: TextStyle(
                            color: palette.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              for (final entry in list.unpricedCounts.entries)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.warning.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(FcbazRadius.sm),
                    border: Border.all(
                      color: palette.warning.withValues(alpha: .32),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: palette.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${faDigits(entry.value)}× ریتینگ ${faDigits(entry.key)} — '
                          'قیمت واقعی برای این ریتینگ در دسترس نیست.',
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.5,
                            color: palette.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Text(
              'قیمت‌ها از ارزان‌ترین کارت واقعی همان ریتینگ خوانده می‌شوند. '
              'خرید از بازار مالیات فروش ندارد؛ مالیات ۵٪ فقط هنگام فروش کسر می‌شود.',
              style: TextStyle(
                fontSize: 10,
                height: 1.6,
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy_rounded, size: 17),
                    label: const Text('کپی متن'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _share(context),
                    icon: const Icon(Icons.ios_share_rounded, size: 17),
                    label: const Text('اشتراک تصویر'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.color,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(FcbazRadius.sm),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: color ?? (emphasized ? palette.primary : palette.text),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}
