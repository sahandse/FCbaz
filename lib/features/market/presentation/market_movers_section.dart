import 'package:flutter/material.dart';

import '../../../src/theme/fcbaz_theme.dart';
import '../../../src/ui/price_delta.dart';
import '../../../src/ui/price_sparkline.dart';
import '../../../src/utils/persian_formatters.dart';
import '../data/watchlist_repository.dart';
import '../domain/market_movers.dart';
import '../domain/player_price.dart';

/// Local-only movers board. Every row needs at least two real observations in
/// the selected window; otherwise the section explains what is missing.
class MarketMoversSection extends StatelessWidget {
  const MarketMoversSection({
    required this.saved,
    required this.histories,
    required this.window,
    required this.onWindowChanged,
    required this.onOpenPlayer,
    this.loading = false,
    this.now,
    this.analyzer = const MarketMoversAnalyzer(),
    super.key,
  });

  final List<WatchlistItem> saved;
  final Map<String, List<PricePoint>> histories;
  final MoverWindow window;
  final ValueChanged<MoverWindow> onWindowChanged;
  final ValueChanged<String> onOpenPlayer;
  final bool loading;
  final DateTime? now;
  final MarketMoversAnalyzer analyzer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final result = analyzer.analyze(histories, window: window, now: now);
    final names = {for (final item in saved) item.playerId: item.playerName};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نوسان بازار',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'فقط از مشاهده‌های محلی واچ‌لیست؛ پیش‌بینی نیست.',
                    style: TextStyle(color: palette.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
            SegmentedButton<MoverWindow>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: MoverWindow.day, label: Text('۲۴ ساعت')),
                ButtonSegment(value: MoverWindow.week, label: Text('۷ روز')),
              ],
              selected: {window},
              onSelectionChanged: (values) {
                if (values.isNotEmpty) onWindowChanged(values.first);
              },
            ),
          ],
        ),
        const SizedBox(height: 9),
        if (loading)
          const _MoversSkeleton()
        else if (saved.isEmpty)
          const _MoversNote(
            icon: Icons.star_border_rounded,
            message: 'واچ‌لیست خالی است. برای دیدن نوسان، کارت‌ها را ستاره کن.',
          )
        else if (result.movers.isEmpty)
          _MoversNote(
            icon: Icons.timeline_rounded,
            message: result.eligiblePlayers == 0
                ? 'برای محاسبه نوسان هر کارت حداقل دو مشاهده محلی در ${window.labelFa} لازم است. '
                      'تا الان ${faDigits(result.observedPlayers)} کارت مشاهده ثبت شده است.'
                : 'بین مشاهده‌های محلی ${window.labelFa} تغییری ثبت نشده است.',
          )
        else ...[
          if (result.risers.isNotEmpty)
            _MoverGroup(
              title: 'بیشترین افزایش',
              icon: Icons.trending_up_rounded,
              color: palette.success,
              movers: result.risers,
              names: names,
              onOpenPlayer: onOpenPlayer,
            ),
          if (result.risers.isNotEmpty && result.fallers.isNotEmpty)
            const SizedBox(height: 8),
          if (result.fallers.isNotEmpty)
            _MoverGroup(
              title: 'بیشترین کاهش',
              icon: Icons.trending_down_rounded,
              color: palette.danger,
              movers: result.fallers,
              names: names,
              onOpenPlayer: onOpenPlayer,
            ),
          const SizedBox(height: 4),
          Text(
            'مبنا: ${faDigits(result.eligiblePlayers)} کارت با حداقل دو مشاهده در این بازه.',
            style: TextStyle(color: palette.textMuted, fontSize: 9.5),
          ),
        ],
      ],
    );
  }
}

class _MoverGroup extends StatelessWidget {
  const _MoverGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.movers,
    required this.names,
    required this.onOpenPlayer,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<MarketMover> movers;
  final Map<String, String> names;
  final ValueChanged<String> onOpenPlayer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        for (final mover in movers)
          _MoverRow(
            mover: mover,
            name: names[mover.playerId] ?? mover.playerId,
            onTap: () => onOpenPlayer(mover.playerId),
          ),
      ],
    );
  }
}

class _MoverRow extends StatelessWidget {
  const _MoverRow({
    required this.mover,
    required this.name,
    required this.onTap,
  });

  final MarketMover mover;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final rising = mover.isUp;
    final color = rising ? palette.success : palette.danger;
    final percent = mover.changePercent!;
    final percentText = percent.abs() >= 10
        ? percent.abs().toStringAsFixed(0)
        : percent.abs().toStringAsFixed(1);

    return Semantics(
      button: true,
      label:
          '$name، ${rising ? 'صعود' : 'نزول'} ${faDigits(percentText)} درصد، '
          'از ${faDigits(mover.first.price)} به ${faDigits(mover.last.price)} سکه '
          'در ${faDigits(mover.sampleCount)} مشاهده محلی',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.line),
            ),
            child: Row(
              children: [
                PriceSparkline(
                  prices: mover.points.map((point) => point.price).toList(),
                  width: 54,
                  height: 20,
                  color: color,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${formatCoinsFa(mover.first.price)} ← ${formatCoinsFa(mover.last.price)}'
                        ' • ${faDigits(mover.sampleCount)} مشاهده',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 9.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          rising
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 11,
                          color: color,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rising ? 'صعود' : 'نزول',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    PriceDelta(percent: percent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoversNote extends StatelessWidget {
  const _MoversNote({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: palette.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 10.5,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoversSkeleton extends StatelessWidget {
  const _MoversSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: 'در حال بارگذاری نوسان محلی',
      child: Column(
        children: [
          for (var i = 0; i < 2; i++)
            Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    palette.surface,
                    palette.surfaceRaised,
                    palette.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.line),
              ),
            ),
        ],
      ),
    );
  }
}
