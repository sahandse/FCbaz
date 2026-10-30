import 'package:flutter/material.dart';

import '../../players/domain/player.dart';
import '../../players/presentation/player_card.dart';
import '../data/watchlist_repository.dart';
import '../domain/market_movers.dart';
import '../domain/player_price.dart';
import 'market_movers_section.dart';
import 'market_table_screen.dart';
import 'price_alert_sheet.dart';
import 'package:fcbaz/src/app_dependencies.dart';
import 'package:fcbaz/src/navigation/app_navigator.dart';
import 'package:fcbaz/src/ui/price_delta.dart';
import 'package:fcbaz/src/ui/price_ticker.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final market = AppDependencies.instance.market;
  final watchlist = AppDependencies.instance.watchlist;
  final settingsRepository = AppDependencies.instance.settings;

  List<Map<String, dynamic>> feed = const [];
  List<WatchlistItem> saved = const [];
  List<Player> cheapest = const [];
  final Map<String, PlayerPrice> savedPrices = {};
  Map<String, List<PricePoint>> localHistories = const {};

  bool loading = true;
  String platform = 'console';
  int minRating = 83;
  MoverWindow moverWindow = MoverWindow.day;

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
    var savedItems = await watchlist.getAll();
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
        try {
          await AppDependencies.instance.priceSnapshots.record(
            item.playerId,
            price: price.current,
            platform: platform,
            observedAt: price.updatedAt ?? DateTime.now(),
          );
        } catch (_) {
          // A failed local snapshot must not hide the verified price.
        }
      } catch (_) {}
    }

    Map<String, List<PricePoint>> histories = const {};
    try {
      histories = await AppDependencies.instance.priceSnapshots.getAllHistories(
        platform: platform,
      );
    } catch (_) {
      // The chart stays empty rather than showing invented observations.
    }

    var alertsTriggered = 0;
    for (final item in savedItems.take(12)) {
      final price = savedPrices[item.playerId];
      if (price == null || item.targetPrice == null) continue;
      try {
        final hit = await AppDependencies.instance.priceAlerts
            .evaluateObservedPrice(
              playerId: item.playerId,
              playerName: item.playerName,
              currentPrice: price.current,
              targetPrice: item.targetPrice,
            );
        if (hit) alertsTriggered++;
      } catch (_) {
        // Foreground alert evaluation is best-effort; the price stays shown.
      }
    }
    try {
      savedItems = await watchlist.getAll();
    } catch (_) {
      // Keep the items already loaded when the refresh fails.
    }

    if (!mounted) return;
    setState(() {
      feed = liveFeed;
      saved = savedItems;
      cheapest = low;
      localHistories = histories;
      loading = false;
    });
    if (alertsTriggered > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${faDigits(alertsTriggered)} هشدار قیمت محلی ثبت شد؛ جزئیات در اعلان‌ها.',
          ),
        ),
      );
    }
  }

  Future<void> _editAlert(WatchlistItem item, int currentPrice) async {
    final choice = await showPriceAlertSheet(
      context,
      playerName: item.playerName,
      currentPrice: currentPrice > 0 ? currentPrice : null,
      initialTarget: item.targetPrice,
    );
    if (choice == null || !mounted) return;

    try {
      await watchlist.setTargetPrice(
        item.playerId,
        choice.remove ? null : choice.targetPrice,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ذخیره هشدار ممکن نشد.')));
      return;
    }

    var triggered = false;
    if (!choice.remove && currentPrice > 0 && choice.targetPrice != null) {
      try {
        triggered = await AppDependencies.instance.priceAlerts
            .evaluateObservedPrice(
              playerId: item.playerId,
              playerName: item.playerName,
              currentPrice: currentPrice,
              targetPrice: choice.targetPrice,
            );
      } catch (_) {
        // The target is saved; the next load or background check will retry.
      }
    }

    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          choice.remove
              ? 'هشدار این کارت حذف شد.'
              : triggered
              ? 'هدف ذخیره شد و قیمت فعلی از قبل به آن رسیده؛ هشدار ثبت شد.'
              : 'هدف ذخیره شد؛ هشدار محلی روی همین دستگاه بررسی می‌شود.',
        ),
      ),
    );
  }

  Future<void> _changePlatform(String value) async {
    if (value == platform) return;
    setState(() => platform = value);
    await _load(forceRefresh: true);
  }

  int _int(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  double? _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString());
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
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: .26),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.query_stats_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VERIFIED PRICE MODE',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'فقط قیمت واقعی؛ مقدار صفر و History ساختگی نمایش داده نمی‌شود.',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _Section(
              title: 'WATCHLIST',
              subtitle: 'قیمت‌های ذخیره‌شده روی دستگاه',
            ),
            const SizedBox(height: 8),
            if (saved.isEmpty)
              const _Empty(
                text: 'واچ‌لیست خالی است.',
                icon: Icons.star_border_rounded,
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: saved.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (_, index) {
                    final item = saved[index];
                    final price = savedPrices[item.playerId];
                    final current = price?.current ?? item.lastPrice ?? 0;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _editAlert(item, current),
                        child: Container(
                          width: 190,
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: item.targetReached
                                  ? scheme.primary
                                  : scheme.outline,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.playerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 15,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              PriceTicker(
                                price: current,
                                changePercent: item.percentChange,
                                updatedAt:
                                    price?.updatedAt ?? item.lastCheckedAt,
                                compact: true,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.targetPrice == null
                                    ? 'بدون هشدار — برای تنظیم ضربه بزن'
                                    : 'هدف: ${formatCoinsFa(item.targetPrice!)} سکه',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: item.targetReached
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 22),
            MarketMoversSection(
              saved: saved,
              histories: localHistories,
              window: moverWindow,
              loading: loading,
              onWindowChanged: (value) => setState(() => moverWindow = value),
              onOpenPlayer: (playerId) =>
                  AppNavigator.playerById(context, playerId),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                await AppNavigator.push<void>(
                  context,
                  MarketTableScreen(platform: platform),
                );
                if (mounted) await _load();
              },
              icon: const Icon(Icons.table_rows_rounded, size: 18),
              label: const Text('جدول فشرده قیمت‌ها · PS و PC'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: _Section(
                    title: 'CHEAPEST',
                    subtitle: 'فقط کارت دارای قیمت مثبت واقعی',
                  ),
                ),
                DropdownButton<int>(
                  value: minRating,
                  items: [80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90]
                      .map(
                        (v) => DropdownMenuItem(value: v, child: Text('$v+')),
                      )
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
              const _CheapestSkeleton()
            else if (cheapest.isEmpty)
              const _Empty(
                text: 'قیمت معتبر برای این فیلتر پیدا نشد.',
                icon: Icons.search_off_rounded,
              )
            else
              SizedBox(
                height: 255,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cheapest.take(12).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (_, index) => SizedBox(
                    width: 168,
                    child: PlayerCard(
                      player: cheapest[index],
                      pricePlatform: platform,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const _Section(
              title: 'LIVE MARKET',
              subtitle: 'فقط ردیف‌هایی که منبع زنده قیمت برگرداند',
            ),
            const SizedBox(height: 8),
            if (!loading && feed.isEmpty)
              const _Empty(
                text: 'در حال حاضر Market Feed معتبر موجود نیست.',
                icon: Icons.cloud_off_rounded,
              )
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
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: scheme.primary,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          (item['name'] ?? item['player_name'] ?? '—')
                              .toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (_double(item['change_24h_percent']) != null) ...[
                        PriceDelta(
                          percent: _double(item['change_24h_percent']),
                        ),
                        const SizedBox(width: 7),
                      ],
                      Text(
                        '${compactCoinsFa(_int(item['current'] ?? item['price']))} سکه',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
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
        Text(
          title,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: -.3,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, this.icon = Icons.inbox_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card-sized placeholders while the verified cheapest list loads, so the
/// section keeps its height instead of collapsing to a spinner.
class _CheapestSkeleton extends StatelessWidget {
  const _CheapestSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'در حال بارگذاری کارت‌ها',
      child: SizedBox(
        height: 255,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (_, __) => Container(
            width: 168,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0, .55, 1],
                colors: [
                  scheme.surface,
                  scheme.primary.withValues(alpha: .08),
                  scheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outline),
            ),
          ),
        ),
      ),
    );
  }
}
