import 'package:flutter/material.dart';

import '../../../core/market/tax_calculator.dart';
import '../data/market_repository.dart';
import '../data/watchlist_repository.dart';
import '../domain/player_price.dart';
import '../domain/player_price_ext.dart';
import 'price_history_chart.dart';
import 'tax_calculator_screen.dart';

class PlayerMarketPanel extends StatefulWidget {
  const PlayerMarketPanel({
    required this.playerId,
    required this.playerName,
    this.seedPricePs = 0,
    this.seedPricePc = 0,
    super.key,
  });

  final String playerId;
  final String playerName;
  final int seedPricePs;
  final int seedPricePc;

  @override
  State<PlayerMarketPanel> createState() => _PlayerMarketPanelState();
}

class _PlayerMarketPanelState extends State<PlayerMarketPanel> {
  final market = MarketRepository();
  final watchlist = WatchlistRepository();

  PlayerPrice? price;
  List<PricePoint> history = const [];
  bool loading = true;
  bool saved = false;
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
      final results = await Future.wait([
        market.getPlayerPrice(widget.playerId),
        market.getPriceHistory(widget.playerId, range: range),
        watchlist.contains(widget.playerId),
      ]);

      if (!mounted) return;

      setState(() {
        price = results[0] as PlayerPrice;
        history = results[1] as List<PricePoint>;
        saved = results[2] as bool;
      });
    } catch (e) {
      if (!mounted) return;
      final seed = widget.seedPricePs > 0
          ? widget.seedPricePs
          : widget.seedPricePc;
      if (seed > 0) {
        setState(() {
          price = PlayerPrice(
            playerId: widget.playerId,
            platform: widget.seedPricePs > 0 ? 'console' : 'pc',
            current: seed,
            low: 0,
            high: 0,
            change24hPercent: 0,
            updatedAt: null,
          );
          error = null;
        });
      } else {
        setState(() => error = 'قیمت زنده فعلاً در دسترس نیست.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _changeRange(String value) async {
    if (value == range) return;
    setState(() => range = value);
    await _load();
  }

  String _coins(int value) {
    if (value >= 1000000) {
      final v = value / 1000000;
      return v.toStringAsFixed(v >= 10 ? 0 : 1) + 'M';
    }
    if (value >= 1000) {
      final v = value / 1000;
      return v.toStringAsFixed(v >= 100 ? 0 : 1) + 'K';
    }
    return value.toString();
  }

  Future<void> _toggleWatchlist() async {
    await watchlist.toggle(
      WatchlistItem(
        playerId: widget.playerId,
        playerName: widget.playerName,
      ),
    );

    if (!mounted) return;
    setState(() => saved = !saved);
  }

  Future<void> _setAlert() async {
    final controller = TextEditingController();

    final target = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('هشدار قیمت'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'قیمت هدف',
            suffixText: 'Coins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              int.tryParse(controller.text.trim()),
            ),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (target == null) return;

    if (!saved) {
      await watchlist.toggle(
        WatchlistItem(
          playerId: widget.playerId,
          playerName: widget.playerName,
          targetPrice: target,
        ),
      );
      saved = true;
    } else {
      await watchlist.setTargetPrice(widget.playerId, target);
    }

    if (mounted) setState(() {});
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

    if (error != null) {
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
              Text(error!, textAlign: TextAlign.center),
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
    final positive = current.change24hPercent >= 0;

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
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '24h', label: Text('24h')),
                    ButtonSegment(value: '7d', label: Text('7d')),
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
            Text(
              _coins(current.current) + ' Coins',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'بعد از مالیات: ${_coins(current.netAfterTax)}  ·  مالیات: ${_coins(current.taxAmount)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Metric(label: 'Low', value: _coins(current.low)),
                const SizedBox(width: 8),
                _Metric(label: 'High', value: _coins(current.high)),
                const SizedBox(width: 8),
                _Metric(
                  label: '24h',
                  value: current.change24hPercent == 0
                      ? '—'
                      : ((positive ? '+' : '') +
                          current.change24hPercent.toStringAsFixed(1) +
                          '%'),
                ),
              ],
            ),
            if (current.displayBins.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Lowest BIN',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < current.displayBins.length; i++)
                    Chip(
                      label: Text(
                        '#${i + 1}  ${_coins(current.displayBins[i])}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            PriceHistoryChart(
              points: history,
              rangeLabel: range == '24h' ? '۲۴ ساعت' : '۷ روز',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _setAlert,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('هشدار قیمت'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TaxCalculatorScreen(
                            initialPrice: current.current,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calculate_outlined),
                    label: Text(
                      'حداکثر خرید ${_coins(TaxCalculator.maxBuyForProfit(current.current))}',
                      overflow: TextOverflow.ellipsis,
                    ),
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
