import 'package:flutter/material.dart';

import '../data/market_repository.dart';
import '../data/watchlist_repository.dart';
import '../domain/player_price.dart';

class PlayerMarketPanel extends StatefulWidget {
  const PlayerMarketPanel({
    required this.playerId,
    required this.playerName,
    super.key,
  });

  final String playerId;
  final String playerName;

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
        market.getPriceHistory(widget.playerId),
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
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
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
      WatchlistItem(playerId: widget.playerId, playerName: widget.playerName),
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
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
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
              Icon(Icons.monitor_heart_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              const Text('قیمت بازار در دسترس نیست', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: _load, child: const Text('تلاش دوباره')),
            ],
          ),
        ),
      );
    }

    final current = price!;
    final positive = current.change24hPercent >= 0;
    final line = history.isEmpty
        ? 'تاریخچه‌ای موجود نیست'
        : history.map((e) => _coins(e.price)).join('  •  ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('بازار', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                ),
                IconButton(
                  onPressed: _toggleWatchlist,
                  icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                  color: saved ? Colors.redAccent : null,
                  tooltip: 'واچ‌لیست',
                ),
              ],
            ),
            Text(
              _coins(current.current) + ' Coins',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _Metric(label: 'کمترین', value: _coins(current.low)),
                const SizedBox(width: 10),
                _Metric(label: 'بیشترین', value: _coins(current.high)),
                const SizedBox(width: 10),
                _Metric(
                  label: '24h',
                  value: (positive ? '+' : '') + current.change24hPercent.toStringAsFixed(1) + '%',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('تاریخچه ۷ روز', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(
              line,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _setAlert,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('تنظیم هشدار قیمت'),
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
