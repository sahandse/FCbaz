import 'package:flutter/material.dart';

import '../../players/domain/player.dart';
import '../../players/presentation/player_card.dart';
import '../../settings/app_settings_repository.dart';
import '../data/market_repository.dart';
import '../data/watchlist_repository.dart';
import '../domain/player_price.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final market = MarketRepository();
  final watchlist = WatchlistRepository();
  final settingsRepository = AppSettingsRepository();

  List<Map<String, dynamic>> feed = const [];
  List<WatchlistItem> saved = const [];
  List<Player> cheapest = const [];
  final Map<String, PlayerPrice> savedPrices = {};

  bool loading = true;
  String platform = 'console';
  int minRating = 83;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final settings = await settingsRepository.load();
    if (!mounted) return;
    platform = settings.defaultPlatform;
    await _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() => loading = true);
    final savedItems = await watchlist.getAll();
    List<Map<String, dynamic>> liveFeed = const [];
    List<Player> low = const [];
    try {
      liveFeed = await market.getMarketFeed(forceRefresh: forceRefresh);
    } catch (_) {}
    try {
      low = await market.getCheapestPlayers(
        minRating: minRating,
        maxRating: 99,
        platform: platform,
        forceRefresh: forceRefresh,
      );
    } catch (_) {}

    savedPrices.clear();
    for (final item in savedItems.take(12)) {
      try {
        final price = await market.getPlayerPrice(
          item.playerId,
          platform: platform,
          forceRefresh: forceRefresh,
        );
        savedPrices[item.playerId] = price;
        await watchlist.recordPrice(
          item.playerId,
          price: price.current,
          platform: platform,
          checkedAt: price.updatedAt ?? DateTime.now(),
        );
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      feed = liveFeed;
      saved = savedItems;
      cheapest = low;
      loading = false;
    });
  }

  Future<void> _changePlatform(String value) async {
    if (value == platform) return;
    setState(() => platform = value);
    await _load(forceRefresh: true);
  }

  String _coins(int value) {
    if (value <= 0) return '—';
    if (value >= 1000000) {
      final n = value / 1000000;
      return '${n.toStringAsFixed(n >= 10 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final n = value / 1000;
      return '${n.toStringAsFixed(n >= 100 ? 0 : 1)}K';
    }
    return value.toString();
  }

  int _int(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MARKET', textDirection: TextDirection.ltr),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'console', label: Text('Console')),
                ButtonSegment(value: 'pc', label: Text('PC')),
              ],
              selected: {platform},
              onSelectionChanged: (value) => _changePlatform(value.first),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF090E0A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary.withValues(alpha: .26)),
              ),
              child: Row(
                children: [
                  Icon(Icons.query_stats_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('VERIFIED PRICE MODE', textDirection: TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                        Text(
                          'فقط قیمت واقعی؛ مقدار صفر و History ساختگی نمایش داده نمی‌شود.',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _Section(title: 'WATCHLIST', subtitle: 'قیمت‌های ذخیره‌شده روی دستگاه'),
            const SizedBox(height: 8),
            if (saved.isEmpty)
              const _Empty(text: 'واچ‌لیست خالی است.')
            else
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: saved.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (_, index) {
                    final item = saved[index];
                    final price = savedPrices[item.playerId];
                    final current = price?.current ?? item.lastPrice ?? 0;
                    return Container(
                      width: 174,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: item.targetReached ? scheme.primary : scheme.outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.playerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.toll_rounded, size: 14, color: scheme.primary),
                              const SizedBox(width: 4),
                              Text('${_coins(current)} C', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900)),
                              const Spacer(),
                              if (item.targetReached) Icon(Icons.notifications_active_rounded, size: 16, color: scheme.primary),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: _Section(title: 'CHEAPEST', subtitle: 'فقط کارت دارای قیمت مثبت واقعی')),
                DropdownButton<int>(
                  value: minRating,
                  items: [80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90]
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v+')))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => minRating = value);
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 9),
            if (loading)
              const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
            else if (cheapest.isEmpty)
              const _Empty(text: 'قیمت معتبر برای این فیلتر پیدا نشد.')
            else
              SizedBox(
                height: 255,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cheapest.take(12).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (_, index) => SizedBox(
                    width: 168,
                    child: PlayerCard(player: cheapest[index], pricePlatform: platform),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const _Section(title: 'LIVE MARKET', subtitle: 'فقط ردیف‌هایی که منبع زنده قیمت برگرداند'),
            const SizedBox(height: 8),
            if (!loading && feed.isEmpty)
              const _Empty(text: 'در حال حاضر Market Feed معتبر موجود نیست.')
            else
              for (final item in feed.take(12)) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 7),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: Icon(Icons.trending_up_rounded, color: scheme.primary, size: 19),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          (item['name'] ?? item['player_name'] ?? '—').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        '${_coins(_int(item['current'] ?? item['price']))} C',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -.3)),
        Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
