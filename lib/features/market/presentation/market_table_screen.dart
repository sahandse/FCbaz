import 'package:flutter/material.dart';

import '../../../src/app_dependencies.dart';
import '../../../src/navigation/app_navigator.dart';
import '../../../src/theme/fcbaz_theme.dart';
import '../../../src/ui/price_sparkline.dart';
import '../../../src/ui/state_views.dart';
import '../../../src/utils/persian_formatters.dart';
import '../../players/data/player_repository.dart';
import '../../players/domain/player.dart';
import '../data/price_snapshot_store.dart';
import '../data/watchlist_repository.dart';
import '../domain/player_price.dart';

enum _TableSort {
  cheapest('ارزان‌ترین'),
  expensive('گران‌ترین'),
  rating('بالاترین ریتینگ');

  const _TableSort(this.labelFa);

  final String labelFa;
}

/// Compact market table: one dense row per priced card, both PS and PC prices,
/// a local-only sparkline, sticky search and sort, and a watch toggle.
class MarketTableScreen extends StatefulWidget {
  const MarketTableScreen({
    this.platform = 'console',
    this.playersRepository,
    this.snapshots,
    this.watchlistRepository,
    super.key,
  });

  final String platform;
  final PlayerRepository? playersRepository;
  final PriceSnapshotStore? snapshots;
  final WatchlistRepository? watchlistRepository;

  @override
  State<MarketTableScreen> createState() => _MarketTableScreenState();
}

class _MarketTableScreenState extends State<MarketTableScreen> {
  late final PlayerRepository _players =
      widget.playersRepository ?? AppDependencies.instance.players;
  late final PriceSnapshotStore _snapshots =
      widget.snapshots ?? AppDependencies.instance.priceSnapshots;
  late final WatchlistRepository _watchlist =
      widget.watchlistRepository ?? AppDependencies.instance.watchlist;

  final TextEditingController _search = TextEditingController();

  late String _platform = widget.platform;
  List<Player> _all = const [];
  Map<String, List<PricePoint>> _histories = const {};
  Set<String> _watched = {};
  _TableSort _sort = _TableSort.cheapest;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    List<Player> players;
    try {
      players = await _players.getPlayers();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'کاتالوگ بازیکنان بارگذاری نشد. اتصال را بررسی کن و دوباره تلاش کن.';
      });
      return;
    }

    final histories = await _loadHistories(_platform);
    var watched = <String>{};
    try {
      watched = (await _watchlist.getAll())
          .map((item) => item.playerId)
          .toSet();
    } catch (_) {
      // Watch state is local convenience only.
    }

    if (!mounted) return;
    setState(() {
      _all = players
          .where((player) => player.id.isNotEmpty && player.name.isNotEmpty)
          .toList();
      _histories = histories;
      _watched = watched;
      _loading = false;
    });
  }

  Future<Map<String, List<PricePoint>>> _loadHistories(String platform) async {
    try {
      return await _snapshots.getAllHistories(platform: platform);
    } catch (_) {
      return const {};
    }
  }

  Future<void> _changePlatform(String value) async {
    if (value == _platform) return;
    setState(() => _platform = value);
    final histories = await _loadHistories(value);
    if (!mounted || _platform != value) return;
    setState(() => _histories = histories);
  }

  int _priceFor(Player player) {
    final preferred = _platform == 'pc' ? player.pricePc : player.pricePs;
    if (preferred > 0) return preferred;
    return _platform == 'pc' ? player.pricePs : player.pricePc;
  }

  List<Player> get _visible {
    final query = _search.text.trim().toLowerCase();
    final priced = _all
        .where((player) => player.pricePs > 0 || player.pricePc > 0)
        .where((player) {
          if (query.isEmpty) return true;
          return player.name.toLowerCase().contains(query) ||
              player.clubName.toLowerCase().contains(query) ||
              player.leagueName.toLowerCase().contains(query) ||
              player.position.toLowerCase() == query;
        })
        .toList();

    int compare(Player a, Player b) {
      switch (_sort) {
        case _TableSort.cheapest:
        case _TableSort.expensive:
          final pa = _priceFor(a);
          final pb = _priceFor(b);
          final byPrice = _sort == _TableSort.cheapest
              ? pa.compareTo(pb)
              : pb.compareTo(pa);
          if (byPrice != 0) return byPrice;
          return b.rating.compareTo(a.rating);
        case _TableSort.rating:
          final byRating = b.rating.compareTo(a.rating);
          if (byRating != 0) return byRating;
          return _priceFor(a).compareTo(_priceFor(b));
      }
    }

    priced.sort(compare);
    return priced;
  }

  int get _pricedCount =>
      _all.where((player) => player.pricePs > 0 || player.pricePc > 0).length;

  Future<void> _toggleWatch(Player player) async {
    try {
      await _watchlist.toggle(
        WatchlistItem(playerId: player.id, playerName: player.name),
      );
    } catch (_) {
      _showMessage('ثبت در واچ‌لیست ممکن نشد.');
      return;
    }
    if (!mounted) return;
    final nowWatched = !_watched.contains(player.id);
    setState(() {
      if (nowWatched) {
        _watched.add(player.id);
      } else {
        _watched.remove(player.id);
      }
    });
    _showMessage(
      nowWatched
          ? '${player.name} به واچ‌لیست اضافه شد؛ هشدار قیمت از صفحه بازار تنظیم می‌شود.'
          : '${player.name} از واچ‌لیست حذف شد.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openPlayer(Player player) {
    AppNavigator.playerDetails(context, player);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final visible = _loading ? const <Player>[] : _visible;
    final countLabel = _loading
        ? 'در حال بارگذاری کاتالوگ و روند محلی…'
        : _all.isEmpty
        ? 'کاتالوگ خالی است.'
        : '${faDigits(visible.length)} از ${faDigits(_pricedCount)} کارت قیمت‌دار'
              ' · روند فقط از مشاهده‌های محلی';

    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول قیمت‌ها'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'console', label: Text('PS')),
                ButtonSegment(value: 'pc', label: Text('PC')),
              ],
              selected: {_platform},
              onSelectionChanged: (values) {
                if (values.isNotEmpty) _changePlatform(values.first);
              },
            ),
          ),
          IconButton(
            onPressed: _load,
            tooltip: 'به‌روزرسانی',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: palette.canvas,
              border: Border(bottom: BorderSide(color: palette.line)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'جستجوی نام، باشگاه، لیگ یا پست',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'پاک کردن جستجو',
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final sort in _TableSort.values) ...[
                        ChoiceChip(
                          label: Text(sort.labelFa),
                          selected: _sort == sort,
                          onSelected: (_) => setState(() => _sort = sort),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: palette.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  if (_loading)
                    const _TableSkeleton()
                  else if (_error != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: AppErrorState(message: _error!, onRetry: _load),
                      ),
                    )
                  else if (_all.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: AppEmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'کاتالوگ خالی است',
                          message:
                              'هیچ کارتی برای ساخت جدول بارگذاری نشد؛ جدول چیزی از خودش نمی‌سازد.',
                          actionLabel: 'تلاش دوباره',
                          onAction: _load,
                        ),
                      ),
                    )
                  else if (visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: _search.text.trim().isEmpty
                            ? AppEmptyState(
                                icon: Icons.price_change_outlined,
                                title: 'قیمت ثبت‌شده‌ای نیست',
                                message:
                                    'هیچ کارتی قیمت مثبت PS یا PC در کاتالوگ ندارد؛ '
                                    'برای همین جدول بدون ردیف می‌ماند.',
                                actionLabel: 'تلاش دوباره',
                                onAction: _load,
                              )
                            : AppEmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'نتیجه‌ای پیدا نشد',
                                message:
                                    'برای «${_search.text.trim()}» کارت قیمت‌داری پیدا نشد. '
                                    'جستجو یا مرتب‌سازی دیگری را امتحان کن.',
                              ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                      sliver: SliverList.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final player = visible[index];
                          return _MarketTableRow(
                            player: player,
                            platform: _platform,
                            history: _histories[player.id] ?? const [],
                            watched: _watched.contains(player.id),
                            onTap: () => _openPlayer(player),
                            onToggleWatch: () => _toggleWatch(player),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketTableRow extends StatelessWidget {
  const _MarketTableRow({
    required this.player,
    required this.platform,
    required this.history,
    required this.watched,
    required this.onTap,
    required this.onToggleWatch,
  });

  final Player player;
  final String platform;
  final List<PricePoint> history;
  final bool watched;
  final VoidCallback onTap;
  final VoidCallback onToggleWatch;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final clubLeague = [
      player.clubName,
      player.leagueName,
    ].where((part) => part.trim().isNotEmpty).join(' · ');
    final sparkPrices = history.length > 12
        ? history.sublist(history.length - 12).map((p) => p.price).toList()
        : history.map((p) => p.price).toList();
    final ratingLabel = [
      if (player.rating > 0) faDigits(player.rating),
      if (player.position.isNotEmpty) player.position,
    ].join(' · ');

    return Semantics(
      button: true,
      label:
          '${player.name}، ${ratingLabel.isEmpty ? 'کارت' : ratingLabel}'
          '${player.pricePs > 0 ? '، PS ${faDigits(player.pricePs)} سکه' : '، PS نامشخص'}'
          '${player.pricePc > 0 ? '، PC ${faDigits(player.pricePc)} سکه' : '، PC نامشخص'}'
          '${watched ? '، در واچ‌لیست' : ''}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: palette.surface,
          borderRadius: BorderRadius.circular(FcbazRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(FcbazRadius.md),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FcbazRadius.md),
                border: Border.all(color: palette.line),
              ),
              child: Row(
                children: [
                  _PlayerThumb(imageUrl: player.imageUrl),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  player.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            if (ratingLabel.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: palette.primary.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ratingLabel,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: palette.primary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (clubLeague.isNotEmpty)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              clubLeague,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: palette.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _PricePair(player: player, platform: platform),
                            const Spacer(),
                            PriceSparkline(
                              prices: sparkPrices,
                              width: 46,
                              height: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleWatch,
                    tooltip: watched ? 'حذف از واچ‌لیست' : 'افزودن به واچ‌لیست',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      watched ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 20,
                      color: watched ? palette.warning : palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerThumb extends StatelessWidget {
  const _PlayerThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fallback = Container(
      color: palette.surfaceRaised,
      alignment: Alignment.center,
      child: Icon(
        Icons.sports_soccer_rounded,
        size: 18,
        color: palette.textMuted,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(FcbazRadius.sm),
      child: SizedBox(
        width: 40,
        height: 40,
        child: imageUrl.isEmpty
            ? fallback
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}

class _PricePair extends StatelessWidget {
  const _PricePair({required this.player, required this.platform});

  final Player player;
  final String platform;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget column(String label, int price, {required bool active}) {
      final color = active ? palette.text : palette.textMuted;
      return SizedBox(
        width: 52,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: active ? palette.primary : palette.textMuted,
                    letterSpacing: .4,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 3),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            Text(
              price > 0 ? compactCoinsFa(price) : '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: price > 0 ? color : palette.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          column('PS', player.pricePs, active: platform != 'pc'),
          const SizedBox(width: 6),
          column('PC', player.pricePc, active: platform == 'pc'),
        ],
      ),
    );
  }
}

class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
      sliver: SliverList.builder(
        itemCount: 8,
        itemBuilder: (_, __) => Semantics(
          label: 'در حال بارگذاری جدول',
          child: Container(
            height: 76,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  palette.surface,
                  palette.surfaceRaised,
                  palette.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(FcbazRadius.md),
              border: Border.all(color: palette.line),
            ),
          ),
        ),
      ),
    );
  }
}
