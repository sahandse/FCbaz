import 'package:flutter/material.dart';

import '../../players/domain/player.dart';
import '../../players/presentation/player_details_screen.dart';
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
  bool loadingCheapest = true;
  String? error;
  String? cheapestError;

  String platform = 'console';
  int minRating = 80;
  int maxRating = 99;
  String? position;

  static const positions = [
    'ST', 'LW', 'RW', 'CAM', 'CM', 'CDM', 'CB', 'LB', 'RB', 'GK',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final settings = await settingsRepository.load();
    if (!mounted) return;
    setState(() => platform = settings.defaultPlatform);
    await _load();
    await _loadCheapest();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await Future.wait([
        market.getMarketFeed(forceRefresh: forceRefresh),
        watchlist.getAll(),
      ]);

      if (!mounted) return;
      final watchItems = result[1] as List<WatchlistItem>;
      setState(() {
        feed = result[0] as List<Map<String, dynamic>>;
        saved = watchItems;
      });

      await _refreshSavedPrices(watchItems, forceRefresh: forceRefresh);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _refreshSavedPrices(
    List<WatchlistItem> items, {
    bool forceRefresh = false,
  }) async {
    savedPrices.clear();

    final results = await Future.wait(
      items.map((item) async {
        try {
          final price = await market.getPlayerPrice(
            item.playerId,
            platform: platform,
            forceRefresh: forceRefresh,
          );
          return (item.playerId, price);
        } catch (_) {
          return null;
        }
      }),
    );

    for (final result in results) {
      if (result == null) continue;
      savedPrices[result.$1] = result.$2;
      await watchlist.recordPrice(
        result.$1,
        price: result.$2.current,
        platform: platform,
        checkedAt: result.$2.updatedAt ?? DateTime.now(),
      );
    }

    final refreshed = await watchlist.getAll();
    if (!mounted) return;
    setState(() => saved = refreshed);
  }

  Future<void> _loadCheapest({bool forceRefresh = false}) async {
    setState(() {
      loadingCheapest = true;
      cheapestError = null;
    });

    try {
      final data = await market.getCheapestPlayers(
        minRating: minRating,
        maxRating: maxRating,
        position: position,
        platform: platform,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() => cheapest = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => cheapestError = e.toString());
    } finally {
      if (mounted) setState(() => loadingCheapest = false);
    }
  }

  String _str(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return '—';
  }

  String _coins(int value) {
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

  Future<void> _changePlatform(String value) async {
    if (value == platform) return;
    setState(() => platform = value);
    await Future.wait([
      _load(forceRefresh: true),
      _loadCheapest(forceRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بازار و قیمت‌ها'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'console', label: Text('کنسول')),
                ButtonSegment(value: 'pc', label: Text('PC')),
              ],
              selected: {platform},
              onSelectionChanged: (value) => _changePlatform(value.first),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _load(forceRefresh: true),
            _loadCheapest(forceRefresh: true),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(
              title: 'واچ‌لیست و هشدار قیمت',
              subtitle: 'آخرین قیمت واقعی دریافت‌شده روی دستگاه و تغییر نسبت به بررسی قبلی.',
              icon: Icons.favorite_rounded,
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
              for (final item in saved) ...[
                _WatchlistCard(
                  item: item,
                  price: savedPrices[item.playerId],
                  coins: _coins,
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 22),
            _SectionHeader(
              title: 'ارزان‌ترین بازیکنان',
              subtitle: 'مرتب‌سازی بر اساس قیمت واقعی بازار، نه امتیاز تخمینی.',
              icon: Icons.savings_outlined,
            ),
            const SizedBox(height: 12),
            _CheapestFilters(
              minRating: minRating,
              maxRating: maxRating,
              position: position,
              positions: positions,
              onChanged: (min, max, pos) {
                setState(() {
                  minRating = min;
                  maxRating = max;
                  position = pos;
                });
                _loadCheapest();
              },
            ),
            const SizedBox(height: 12),
            if (loadingCheapest)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (cheapestError != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: const Text('لیست ارزان‌ترین‌ها در دسترس نیست'),
                  subtitle: Text(cheapestError!),
                  trailing: IconButton(
                    onPressed: _loadCheapest,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              )
            else if (cheapest.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.search_off_rounded),
                  title: Text('بازیکن قیمت‌داری پیدا نشد'),
                  subtitle: Text('فیلترها را تغییر بده یا بعداً دوباره بررسی کن.'),
                ),
              )
            else
              for (final player in cheapest.take(20)) ...[
                _CheapPlayerCard(
                  player: player,
                  platform: platform,
                  coins: _coins,
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 22),
            _SectionHeader(
              title: 'بازار FC27',
              subtitle: 'فقط داده‌ای که منبع زنده برمی‌گرداند نمایش داده می‌شود.',
              icon: Icons.query_stats_rounded,
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
                  trailing: IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              )
            else if (feed.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.query_stats_rounded),
                  title: Text('داده بازار موجود نیست'),
                  subtitle: Text('منبع زنده در حال حاضر داده‌ای برنگردانده است.'),
                ),
              )
            else
              for (final item in feed)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.trending_up_rounded),
                    title: Text(_str(item, ['player_name', 'name'])),
                    subtitle: Text(
                      '${_str(item, ['platform'])} • ${_str(item, ['updated_at'])}',
                    ),
                    trailing: Text(
                      '${_str(item, ['current', 'price'])} C',
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WatchlistCard extends StatelessWidget {
  const _WatchlistCard({
    required this.item,
    required this.price,
    required this.coins,
  });

  final WatchlistItem item;
  final PlayerPrice? price;
  final String Function(int) coins;

  @override
  Widget build(BuildContext context) {
    final current = price?.current ?? item.lastPrice ?? 0;
    final reached = item.targetPrice != null && current > 0 && current <= item.targetPrice!;
    final change = item.percentChange;

    IconData trendIcon = Icons.remove_rounded;
    if (change != null && change > 0) trendIcon = Icons.trending_up_rounded;
    if (change != null && change < 0) trendIcon = Icons.trending_down_rounded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  reached ? Icons.notifications_active_rounded : Icons.favorite_rounded,
                  color: reached ? Theme.of(context).colorScheme.primary : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.playerName, style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                if (reached) const Chip(label: Text('به هدف رسید')),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: 'قیمت فعلی',
                  value: current > 0 ? '${coins(current)} C' : 'ناموجود',
                ),
                if (item.targetPrice != null)
                  _MetricChip(label: 'هدف', value: '${coins(item.targetPrice!)} C'),
                if (change != null)
                  _MetricChip(
                    label: 'از بررسی قبل',
                    value: '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}٪',
                    icon: trendIcon,
                  ),
                if (item.platform != null)
                  _MetricChip(
                    label: 'بازار',
                    value: item.platform == 'pc' ? 'PC' : 'کنسول',
                  ),
              ],
            ),
            if (item.lastCheckedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'آخرین بررسی محلی: ${_timeLabel(item.lastCheckedAt!)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _timeLabel(DateTime value) {
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)} • ${two(local.hour)}:${two(local.minute)}';
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value, this.icon});
  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text('$label: ', style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _CheapestFilters extends StatelessWidget {
  const _CheapestFilters({
    required this.minRating,
    required this.maxRating,
    required this.position,
    required this.positions,
    required this.onChanged,
  });

  final int minRating;
  final int maxRating;
  final String? position;
  final List<String> positions;
  final void Function(int min, int max, String? position) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: minRating,
                decoration: const InputDecoration(labelText: 'حداقل ریتینگ'),
                items: [
                  for (final value in [75, 80, 82, 84, 85, 86, 87, 88, 89, 90])
                    DropdownMenuItem(value: value, child: Text(value.toString())),
                ],
                onChanged: (value) {
                  if (value != null) onChanged(value, maxRating, position);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: position,
                decoration: const InputDecoration(labelText: 'پست'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('همه')),
                  for (final value in positions)
                    DropdownMenuItem<String?>(value: value, child: Text(value)),
                ],
                onChanged: (value) => onChanged(minRating, maxRating, value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheapPlayerCard extends StatelessWidget {
  const _CheapPlayerCard({
    required this.player,
    required this.platform,
    required this.coins,
  });

  final Player player;
  final String platform;
  final String Function(int) coins;

  @override
  Widget build(BuildContext context) {
    final price = platform == 'pc' ? player.pricePc : player.pricePs;
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: player)),
        ),
        leading: CircleAvatar(
          backgroundImage: player.imageUrl.isEmpty ? null : NetworkImage(player.imageUrl),
          child: player.imageUrl.isEmpty ? Text(player.rating.toString()) : null,
        ),
        title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${player.rating} • ${player.position} • ${player.clubName}'),
        trailing: price > 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(coins(price), style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(platform == 'pc' ? 'PC' : 'کنسول', style: Theme.of(context).textTheme.labelSmall),
                ],
              )
            : const Text('—'),
      ),
    );
  }
}
