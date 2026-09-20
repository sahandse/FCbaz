import 'package:flutter/material.dart';

import '../data/market_repository.dart';
import '../data/watchlist_repository.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final market = MarketRepository();
  final watchlist = WatchlistRepository();

  List<Map<String, dynamic>> feed = const [];
  List<WatchlistItem> saved = const [];
  bool loading = true;
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
      final result = await Future.wait([
        market.getMarketFeed(),
        watchlist.getAll(),
      ]);
      if (!mounted) return;
      setState(() {
        feed = result[0] as List<Map<String, dynamic>>;
        saved = result[1] as List<WatchlistItem>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _str(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بازار و قیمت‌ها')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Watchlist',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (saved.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.favorite_border_rounded),
                  title: Text('واچ‌لیست خالی است'),
                  subtitle: Text('از صفحه بازیکن، کارت‌های موردنظرت را ذخیره کن.'),
                ),
              )
            else
              for (final item in saved)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                    title: Text(item.playerName),
                    subtitle: Text(
                      item.targetPrice == null
                          ? 'هشدار قیمت تنظیم نشده'
                          : 'قیمت هدف: ' + item.targetPrice.toString(),
                    ),
                  ),
                ),
            const SizedBox(height: 22),
            Text(
              'بازار FC27',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (loading)
              const Padding(
                padding: EdgeInsets.all(42),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: const Text('بازار در دسترس نیست'),
                  subtitle: Text(error!),
                  trailing: IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
                ),
              )
            else if (feed.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.query_stats_rounded),
                  title: Text('داده بازار موجود نیست'),
                  subtitle: Text('Backend باید داده واقعی قیمت FC27 را ارائه کند.'),
                ),
              )
            else
              for (final item in feed)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.trending_up_rounded),
                    title: Text(_str(item, ['player_name', 'name'])),
                    subtitle: Text(_str(item, ['platform']) + ' • ' + _str(item, ['updated_at'])),
                    trailing: Text(
                      _str(item, ['current', 'price']) + ' C',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
