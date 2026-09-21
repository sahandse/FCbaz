import 'package:flutter/material.dart';

import '../../players/domain/player.dart';
import '../../players/presentation/player_details_screen.dart';
import '../data/market_repository.dart';
import '../data/watchlist_repository.dart';
import '../domain/player_price.dart';
import '../../settings/app_settings_repository.dart';
import 'fodder_screen.dart';
import 'tax_calculator_screen.dart';
import 'pack_value_screen.dart';

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
    'ST',
    'LW',
    'RW',
    'CAM',
    'CM',
    'CDM',
    'CB',
    'LB',
    'RB',
    'GK',
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

    if (!mounted) return;

    for (final result in results) {
      if (result == null) continue;
      savedPrices[result.$1] = result.$2;
    }
    setState(() {});
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
      return n.toStringAsFixed(n >= 10 ? 0 : 1) + 'M';
    }
    if (value >= 1000) {
      final n = value / 1000;
      return n.toStringAsFixed(n >= 100 ? 0 : 1) + 'K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بازار و قیمت‌ها')),
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
            Text(
              'واچ‌لیست و هشدار قیمت',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'قیمت‌ها از منبع زنده عمومی خوانده می‌شوند؛ اگر قطع باشد عدد جعلی نشان داده نمی‌شود.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.local_offer_outlined, size: 18),
                  label: const Text('Fodder'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FodderScreen()),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.calculate_outlined, size: 18),
                  label: const Text('مالیات ۵٪'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TaxCalculatorScreen(),
                    ),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.inventory_outlined, size: 18),
                  label: const Text('ارزش پک'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PackValueScreen()),
                  ),
                ),
              ],
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
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 22),
            Text(
              'ارزان‌ترین بازیکنان',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'مرتب‌سازی بر اساس قیمت واقعی بازار، نه امتیاز تخمینی.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
            Text(
              'بازار FC27',
              style: Theme.of(context).textTheme.titleLarge,
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
                      _str(item, ['platform']) +
                          ' • ' +
                          _str(item, ['updated_at']),
                    ),
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

class _WatchlistCard extends StatelessWidget {
  const _WatchlistCard({
    required this.item,
    required this.price,
  });

  final WatchlistItem item;
  final PlayerPrice? price;

  @override
  Widget build(BuildContext context) {
    final target = item.targetPrice;
    final current = price?.current ?? 0;
    final reached = target != null && current > 0 && current <= target;

    return Card(
      child: ListTile(
        leading: Icon(
          reached ? Icons.notifications_active_rounded : Icons.favorite_rounded,
          color: reached ? Theme.of(context).colorScheme.primary : Colors.redAccent,
        ),
        title: Text(
          item.playerName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          price == null
              ? 'قیمت زنده در دسترس نیست'
              : target == null
                  ? 'قیمت فعلی: ' + current.toString() + ' Coins'
                  : 'فعلی: ' +
                      current.toString() +
                      ' • هدف: ' +
                      target.toString(),
        ),
        trailing: reached
            ? const Chip(label: Text('به هدف رسید'))
            : null,
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
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: minRating,
                    decoration: const InputDecoration(labelText: 'حداقل ریتینگ'),
                    items: [
                      for (final value in [75, 80, 82, 84, 85, 86, 87, 88, 89, 90])
                        DropdownMenuItem(
                          value: value,
                          child: Text(value.toString()),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) onChanged(value, maxRating, position);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: position,
                    decoration: const InputDecoration(labelText: 'پست'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('همه'),
                      ),
                      for (final value in positions)
                        DropdownMenuItem<String?>(
                          value: value,
                          child: Text(value),
                        ),
                    ],
                    onChanged: (value) => onChanged(minRating, maxRating, value),
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
          MaterialPageRoute(
            builder: (_) => PlayerDetailsScreen(player: player),
          ),
        ),
        leading: CircleAvatar(
          backgroundImage:
              player.imageUrl.isEmpty ? null : NetworkImage(player.imageUrl),
          child: player.imageUrl.isEmpty
              ? Text(player.rating.toString())
              : null,
        ),
        title: Text(
          player.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          player.rating.toString() +
              ' • ' +
              player.position +
              ' • ' +
              player.clubName,
        ),
        trailing: price > 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    coins(price),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    platform == 'pc' ? 'PC' : 'Console',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              )
            : const Text('—'),
      ),
    );
  }
}
