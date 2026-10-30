import 'package:flutter/material.dart';

import '../../club/data/my_club_repository.dart';
import '../domain/sbc_rating_tools.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';

class SbcClubSolverCard extends StatelessWidget {
  const SbcClubSolverCard({
    required this.items,
    required this.targetRating,
    this.calculator = const SbcRatingCalculator(),
    super.key,
  });

  final List<MyClubItem> items;
  final int targetRating;
  final SbcRatingCalculator calculator;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final solution = calculator.solveClubSquad<MyClubItem>(
      clubItems: items,
      getRating: (item) => item.rating,
      isUntradeable: (item) => item.untradeable,
      targetRating: targetRating,
    );

    if (solution == null) {
      return Card(
        child: ListTile(
          leading: Icon(Icons.inventory_2_outlined, color: scheme.primary),
          title: const Text('کلوب برای حل SBC کافی نیست'),
          subtitle: Text(
            'برای ساخت تیم ${faDigits(11)} نفره از کلوب حداقل ${faDigits(11)} کارت لازم است؛ '
            'الان ${faDigits(items.length)} کارت ثبت شده.',
          ),
        ),
      );
    }

    final entries = solution.counts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final acquisitionValue = solution.tradeables.fold<int>(
      0,
      (sum, item) =>
          sum + (item.acquisitionPrice > 0 ? item.acquisitionPrice : 0),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ساخت از کلوب من',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
                _SolverChip(
                  label: 'ریتینگ ${faDigits(solution.squadRating)}',
                  emphasized: solution.meetsTarget,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              solution.meetsTarget
                  ? 'این ترکیب از کارت‌های کلوب، ریتینگ هدف ${faDigits(targetRating)} را می‌دهد و خرید اضافه لازم ندارد.'
                  : 'حتی با بهترین کارت‌های کلوب هم ریتینگ ${faDigits(solution.squadRating)} به دست می‌آید؛ ${faDigits(solution.shortfall)} امتیاز کمتر از هدف است و عدد ساختگی جایگزین نمی‌شود.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.6,
                color: solution.meetsTarget
                    ? scheme.onSurfaceVariant
                    : scheme.error,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SolverChip(
                  label:
                      'غیرقابل‌فروش ${faDigits(solution.untradeables.length)}',
                ),
                _SolverChip(
                  label: 'قابل‌فروش ${faDigits(solution.tradeables.length)}',
                ),
                const _SolverChip(label: 'خرید اضافه ۰ سکه'),
                for (final entry in entries)
                  _SolverChip(
                    label: '${faDigits(entry.value)}× ${faDigits(entry.key)}',
                  ),
              ],
            ),
            if (acquisitionValue > 0) ...[
              const SizedBox(height: 8),
              Text(
                'جمع قیمت خرید ثبت‌شده کارت‌های قابل‌فروش: ${formatCoinsFa(acquisitionValue)} سکه',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              leading: const Icon(Icons.list_alt_rounded),
              title: const Text(
                'کارت‌های انتخابی از کلوب',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              children: [
                for (final item in solution.selected)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      item.untradeable
                          ? Icons.lock_rounded
                          : Icons.sell_outlined,
                      size: 18,
                      color: item.untradeable
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    title: Text(
                      item.playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item.version.isEmpty
                          ? item.position
                          : '${item.position} • ${item.version}',
                    ),
                    trailing: Text(
                      faDigits(item.rating),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'اولویت انتخاب با کارت‌های غیرقابل‌فروش است؛ سپس کمترین ریتینگ ممکن برای رسیدن به هدف انتخاب می‌شود. استفاده از کارت قابل‌فروش ارزش فروش آن را از بین می‌برد.',
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolverChip extends StatelessWidget {
  const _SolverChip({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? scheme.primary.withValues(alpha: .16)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: emphasized ? scheme.primary : scheme.onSurface,
        ),
      ),
    );
  }
}
