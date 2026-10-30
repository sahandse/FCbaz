import 'package:flutter/material.dart';

import '../data/market_repository.dart';
import '../data/price_snapshot_store.dart';
import '../data/watchlist_repository.dart';
import '../domain/player_price.dart';
import 'price_alert_sheet.dart';
import 'price_history_chart.dart';
import 'package:fcbaz/src/app_dependencies.dart';
import 'package:fcbaz/src/ui/price_ticker.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';

class PlayerMarketPanel extends StatefulWidget {
  const PlayerMarketPanel({
    required this.playerId,
    required this.playerName,
    this.market,
    this.watchlist,
    this.snapshots,
    super.key,
  });

  final String playerId;
  final String playerName;
  final MarketRepository? market;
  final WatchlistRepository? watchlist;
  final PriceSnapshotStore? snapshots;

  @override
  State<PlayerMarketPanel> createState() => _PlayerMarketPanelState();
}

class _PlayerMarketPanelState extends State<PlayerMarketPanel> {
  late final market = widget.market ?? AppDependencies.instance.market;
  late final watchlist = widget.watchlist ?? AppDependencies.instance.watchlist;
  late final snapshots =
      widget.snapshots ?? AppDependencies.instance.priceSnapshots;

  PlayerPrice? price;
  List<PricePoint> history = const [];
  bool localHistory = false;
  int localSampleCount = 0;
  DateTime? localLastObservedAt;
  bool loading = true;
  bool saved = false;
  int? targetPrice;
  String? error;
  String range = '7d';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final livePrice = await market.getPlayerPrice(widget.playerId);

      var observed = const <PricePoint>[];
      try {
        observed = await snapshots.record(
          widget.playerId,
          price: livePrice.current,
        );
      } catch (_) {
        // Snapshot storage is best-effort; the live price stays usable.
      }

      final isSaved = await watchlist.contains(widget.playerId);
      int? storedTarget;
      try {
        for (final item in await watchlist.getAll()) {
          if (item.playerId == widget.playerId) {
            storedTarget = item.targetPrice;
            break;
          }
        }
      } catch (_) {
        // A missing local watchlist entry simply means no saved target.
      }
      List<PricePoint> realHistory = const [];
      try {
        realHistory = await market.getPriceHistory(
          widget.playerId,
          range: range,
        );
      } catch (_) {
        // Current price remains useful even when the provider has no real history.
      }

      final useLocal = realHistory.isEmpty;
      final localPoints = useLocal
          ? _localRange(observed)
          : const <PricePoint>[];

      if (!mounted) return;
      setState(() {
        price = livePrice;
        history = useLocal ? localPoints : realHistory;
        localHistory = useLocal;
        localSampleCount = observed.length;
        localLastObservedAt = observed.isEmpty ? null : observed.last.time;
        saved = isSaved;
        targetPrice = storedTarget;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _changeRange(String value) async {
    if (value == range) return;
    setState(() => range = value);
    await _load();
  }

  List<PricePoint> _localRange(List<PricePoint> points) {
    if (points.length < 2) return points;
    final span = range == '24h'
        ? const Duration(hours: 24)
        : const Duration(days: 7);
    final cutoff = points.last.time.subtract(span);
    return points.where((p) => !p.time.isBefore(cutoff)).toList();
  }

  Future<void> _toggleWatchlist() async {
    await watchlist.toggle(
      WatchlistItem(playerId: widget.playerId, playerName: widget.playerName),
    );

    if (!mounted) return;
    setState(() {
      saved = !saved;
      if (!saved) targetPrice = null;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setAlert() async {
    final choice = await showPriceAlertSheet(
      context,
      playerName: widget.playerName,
      currentPrice: price?.current,
      initialTarget: targetPrice,
    );
    if (choice == null || !mounted) return;

    if (choice.remove) {
      await watchlist.setTargetPrice(widget.playerId, null);
      if (!mounted) return;
      setState(() => targetPrice = null);
      _showMessage('هشدار این کارت حذف شد.');
      return;
    }

    final target = choice.targetPrice!;
    if (!saved) {
      await watchlist.toggle(
        WatchlistItem(
          playerId: widget.playerId,
          playerName: widget.playerName,
          targetPrice: target,
        ),
      );
    } else {
      await watchlist.setTargetPrice(widget.playerId, target);
    }

    final current = price?.current ?? 0;
    var triggered = false;
    if (current > 0) {
      try {
        triggered = await AppDependencies.instance.priceAlerts
            .evaluateObservedPrice(
              playerId: widget.playerId,
              playerName: widget.playerName,
              currentPrice: current,
              targetPrice: target,
            );
      } catch (_) {
        // The target is stored; a foreground alert check is best-effort.
      }
    }

    if (!mounted) return;
    setState(() {
      saved = true;
      targetPrice = target;
    });
    _showMessage(
      triggered
          ? 'هدف ذخیره شد و قیمت فعلی از قبل به آن رسیده؛ هشدار همین حالا ثبت شد.'
          : 'هدف ذخیره شد؛ هشدار محلی روی همین دستگاه بررسی می‌شود.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (error != null || price == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              const Text(
                'قیمت بازار در دسترس نیست',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              if (error != null) Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _load,
                child: const Text('تلاش دوباره'),
              ),
            ],
          ),
        ),
      );
    }

    final current = price!;
    final change = current.change24hPercent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'بازار',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '24h', label: Text('۲۴ ساعت')),
                    ButtonSegment(value: '7d', label: Text('۷ روز')),
                  ],
                  selected: {range},
                  onSelectionChanged: (values) {
                    if (values.isNotEmpty) _changeRange(values.first);
                  },
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _toggleWatchlist,
                  icon: Icon(
                    saved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                  ),
                  color: saved ? Colors.redAccent : null,
                  tooltip: 'واچ‌لیست',
                ),
              ],
            ),
            const SizedBox(height: 10),
            PriceTicker(
              price: current.current,
              changePercent: change,
              updatedAt: current.updatedAt,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Metric(label: 'کف قیمت', value: compactCoinsFa(current.low)),
                const SizedBox(width: 8),
                _Metric(label: 'سقف قیمت', value: compactCoinsFa(current.high)),
              ],
            ),
            const SizedBox(height: 14),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    localHistory && localSampleCount > 0
                        ? 'تاریخچه سرور در دسترس نیست. ${faDigits(localSampleCount)} مشاهده محلی ثبت شده، اما در بازه انتخابی به حداقل ۲ نقطه برای نمودار نیاز است.'
                        : 'تاریخچه قیمت واقعی برای این کارت در دسترس نیست.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              if (localHistory)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.smartphone_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تاریخچه محلی: ${faDigits(history.length)} نقطه در این بازه از ${faDigits(localSampleCount)} مشاهده واقعی روی همین دستگاه. '
                          'آخرین مشاهده: ${formatJalaliDateTime(localLastObservedAt!)}. تاریخچه سرور در دسترس نیست و نقطه‌ای ساختگی اضافه نشده است.',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              PriceHistoryChart(
                points: history,
                rangeLabel: localHistory
                    ? '${range == '24h' ? '۲۴ ساعت' : '۷ روز'} (محلی)'
                    : range == '24h'
                    ? '۲۴ ساعت'
                    : '۷ روز',
              ),
            ],
            const SizedBox(height: 14),
            if (targetPrice != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'هدف فعلی: ${formatCoinsFa(targetPrice!)} سکه — هشدار محلی روی همین دستگاه؛ '
                      'بررسی خودکار حدود هر ۳۰ دقیقه. هیچ قیمتی پیش‌بینی نمی‌شود.',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _setAlert,
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(
                  targetPrice == null
                      ? 'تنظیم هشدار قیمت'
                      : 'ویرایش هشدار قیمت',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
