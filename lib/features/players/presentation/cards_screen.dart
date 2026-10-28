import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/network/live_fc27_catalog.dart';
import '../../../src/theme/fcbaz_theme.dart';
import '../../../src/ui/section_header.dart';
import '../../../src/utils/persian_formatters.dart';
import '../../../src/ui/state_views.dart';
import '../../market/presentation/market_screen.dart';
import '../../search/search_history_repository.dart';
import '../../settings/app_settings_repository.dart';
import '../data/player_repository.dart';
import '../domain/player.dart';
import 'advanced_player_filter_sheet.dart';
import 'player_item_visual.dart';
import 'player_market_tile.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({this.focusRequests, super.key});

  final ValueNotifier<int>? focusRequests;

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final repository = PlayerRepository();
  final historyRepository = SearchHistoryRepository();
  final settingsRepository = AppSettingsRepository();
  final controller = TextEditingController();
  final searchFocus = FocusNode();
  final scrollController = ScrollController();

  Timer? debounce;
  List<Player> players = const [];
  List<Player> trending = const [];
  List<Player> favorites = const [];
  List<String> recent = const [];
  List<SavedPlayerFilter> savedFilters = const [];
  PlayerFilter filter = const PlayerFilter();
  PlayerFacets facets = const PlayerFacets();
  bool loading = true;
  bool loadingDiscovery = true;
  String? error;
  String quickRarity = 'همه';
  DateTime? priceUpdatedAt;
  int requestId = 0;

  bool get hasNarrowingFilters =>
      filter.copyWith(platform: 'console').activeCount > 0;

  bool get showingDiscovery =>
      controller.text.trim().isEmpty && !hasNarrowingFilters;

  @override
  void initState() {
    super.initState();
    widget.focusRequests?.addListener(_focusFromShell);
    _initialize();
  }

  @override
  void dispose() {
    widget.focusRequests?.removeListener(_focusFromShell);
    debounce?.cancel();
    controller.dispose();
    searchFocus.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _focusFromShell() {
    if (!mounted) return;
    if (scrollController.hasClients && scrollController.offset > 0) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
    searchFocus.requestFocus();
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  Future<void> _initialize() async {
    AppSettings settings = const AppSettings();
    try {
      settings = await settingsRepository.load();
    } catch (_) {
      // Local settings are optional; console pricing is the documented default.
    }
    if (!mounted) return;
    filter = filter.copyWith(platform: settings.defaultPlatform);
    await Future.wait([_load(), _loadDiscovery(), _loadPriceFreshness()]);
  }

  Future<void> _load() async {
    final id = ++requestId;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await repository.advanced(filter);
      if (!mounted || id != requestId) return;
      setState(() {
        players = result.players;
        facets = result.facets;
      });
    } catch (e) {
      if (!mounted || id != requestId) return;
      setState(() {
        players = const [];
        error = e.toString();
      });
    } finally {
      if (mounted && id == requestId) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _loadPriceFreshness() async {
    DateTime? updatedAt;
    try {
      updatedAt = await LiveFc27Catalog().priceUpdatedAt();
    } catch (_) {
      // Older cached catalogs may not carry a price stamp; keep the fallback.
    }
    if (!mounted || updatedAt == null) return;
    setState(() => priceUpdatedAt = updatedAt);
  }

  /// Persian relative age for the verified price snapshot so the collection
  /// never implies prices are live when the snapshot is hours old.
  String _priceAgeLabel(DateTime at) {
    final elapsed = DateTime.now().difference(at.toLocal());
    if (elapsed.inMinutes < 1) return 'همین حالا';
    if (elapsed.inMinutes < 60) return '${faDigits(elapsed.inMinutes)} دقیقه پیش';
    if (elapsed.inHours < 24) return '${faDigits(elapsed.inHours)} ساعت پیش';
    return '${faDigits(elapsed.inDays)} روز پیش';
  }

  Future<void> _showPriceFreshnessSheet() async {
    final updatedAt = priceUpdatedAt;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final palette = sheetContext.palette;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تازگی قیمت‌ها',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: FcbazSpace.sm),
                Text(
                  updatedAt == null
                      ? 'این نسخه مهر زمانی قیمت ندارد؛ عددهای نمایش‌داده‌شده از کاتالوگ همراه برنامه می‌آیند.'
                      : 'آخرین به‌روزرسانی: ${formatJalaliDateTime(updatedAt)}'
                            ' · ${_priceAgeLabel(updatedAt)}',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: FcbazSpace.md),
                _FreshnessRow(
                  icon: Icons.verified_rounded,
                  label: 'منبع',
                  value: 'کاتالوگ FC27 (قیمت‌های تأییدشده)',
                ),
                _FreshnessRow(
                  icon: Icons.schedule_rounded,
                  label: 'بازه به‌روزرسانی',
                  value: 'هر ۳۰ دقیقه از فید عمومی',
                ),
                _FreshnessRow(
                  icon: Icons.info_outline_rounded,
                  label: 'کارت‌های بدون قیمت',
                  value: 'قیمت صفر نمایش داده نمی‌شود',
                ),
                const SizedBox(height: FcbazSpace.lg),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MarketScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.show_chart_rounded, size: 18),
                        label: const Text('بازار'),
                      ),
                    ),
                    const SizedBox(width: FcbazSpace.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _refresh();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('به‌روزرسانی'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadDiscovery() async {
    final recentFuture = historyRepository.recentSearches();
    final savedFuture = historyRepository.savedFilters();
    final favoriteFuture = historyRepository.favorites();
    List<Player> trend = const [];
    try {
      trend = await repository.getTrendingPlayers();
    } catch (_) {
      trend = const [];
    }
    final recentData = await recentFuture;
    final savedData = await savedFuture;
    final favoriteData = await favoriteFuture;
    if (!mounted) return;
    setState(() {
      trending = trend;
      recent = recentData;
      savedFilters = savedData;
      favorites = favoriteData;
      loadingDiscovery = false;
    });
  }

  void _onQueryChanged(String value) {
    debounce?.cancel();
    final query = value.trim();
    setState(() => filter = filter.copyWith(query: query));
    if (query.isEmpty) {
      _load();
      return;
    }
    debounce = Timer(const Duration(milliseconds: 250), _search);
  }

  Future<void> _search() async {
    debounce?.cancel();
    final query = filter.query.trim();
    if (query.isEmpty) return;
    await _load();
    if (!mounted || filter.query.trim() != query) return;
    await historyRepository.addRecentSearch(query);
    final recentData = await historyRepository.recentSearches();
    if (!mounted) return;
    setState(() => recent = recentData);
  }

  void _clearQuery() {
    debounce?.cancel();
    controller.clear();
    setState(() => filter = filter.copyWith(query: ''));
    _load();
  }

  Future<void> _refresh() async {
    await Future.wait([_load(), _loadDiscovery(), _loadPriceFreshness()]);
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<PlayerFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          AdvancedPlayerFilterSheet(current: filter, facets: facets),
    );
    if (result == null) return;
    setState(() {
      filter = result.copyWith(query: controller.text.trim());
      quickRarity = 'همه';
    });
    await _load();
  }

  Future<void> _applyQuickRarity(String label, String? rarity) async {
    setState(() {
      quickRarity = label;
      filter = filter.copyWith(
        version: rarity,
        clearVersion: rarity == null,
        rarity: rarity,
        clearRarity: rarity == null,
        cardType: rarity,
        clearCardType: rarity == null,
      );
    });
    await _load();
  }

  Future<void> _clearAllFilters() async {
    debounce?.cancel();
    controller.clear();
    final platform = filter.platform;
    setState(() {
      filter = PlayerFilter(platform: platform);
      quickRarity = 'همه';
    });
    await _load();
  }

  Future<void> _saveCurrentView() async {
    if (filter.activeCount == 0 && filter.query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اول یک جستجو یا فیلتر انتخاب کن.')),
      );
      return;
    }
    final nameController = TextEditingController(
      text: filter.query.trim().isEmpty
          ? 'فیلتر FC27'
          : 'جستجوی ${filter.query.trim()}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ذخیره نما'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'نام نما'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name == null || name.isEmpty) return;
    await historyRepository.saveFilter(name, filter);
    final savedData = await historyRepository.savedFilters();
    if (!mounted) return;
    setState(() => savedFilters = savedData);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('نما ذخیره شد.')));
  }

  Future<void> _applySavedView(SavedPlayerFilter saved) async {
    debounce?.cancel();
    controller.text = saved.filter.query;
    setState(() => filter = saved.filter);
    await _load();
  }

  Future<void> _deleteSavedView(SavedPlayerFilter saved) async {
    await historyRepository.deleteSavedFilter(saved.id);
    final savedData = await historyRepository.savedFilters();
    if (!mounted) return;
    setState(() => savedFilters = savedData);
  }

  Future<void> _clearRecent() async {
    await historyRepository.clearRecentSearches();
    if (!mounted) return;
    setState(() => recent = const []);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: scrollController,
        cacheExtent: 1000,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FUT COLLECTION',
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontFamily: 'BarlowCondensed',
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 1.2,
                                color: palette.primary,
                              ),
                            ),
                            Text(
                              'کالکشن کارت‌ها',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      IconButton.outlined(
                        onPressed: _saveCurrentView,
                        icon: const Icon(Icons.bookmark_add_outlined),
                        tooltip: 'ذخیره نما',
                      ),
                    ],
                  ),
                  const SizedBox(height: FcbazSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: searchFocus,
                          onChanged: _onQueryChanged,
                          onSubmitted: (_) => _search(),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'نام بازیکن، باشگاه، لیگ...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: controller.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: _clearQuery,
                                    icon: const Icon(Icons.close_rounded),
                                    tooltip: 'پاک کردن جستجو',
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: FcbazSpace.sm),
                      Badge(
                        isLabelVisible: filter.activeCount > 0,
                        label: Text(filter.activeCount.toString()),
                        child: IconButton.filledTonal(
                          onPressed: _openFilters,
                          icon: const Icon(Icons.tune_rounded),
                          tooltip: 'فیلتر پیشرفته',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FcbazSpace.md),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _RarityChip(
                          label: 'همه',
                          active: quickRarity == 'همه',
                          onTap: () => _applyQuickRarity('همه', null),
                        ),
                        _RarityChip(
                          label: 'Gold',
                          active: quickRarity == 'Gold',
                          onTap: () => _applyQuickRarity('Gold', 'Gold'),
                        ),
                        _RarityChip(
                          label: 'ICON',
                          active: quickRarity == 'ICON',
                          onTap: () => _applyQuickRarity('ICON', 'Base Icon'),
                        ),
                        _RarityChip(
                          label: 'Hero',
                          active: quickRarity == 'Hero',
                          onTap: () => _applyQuickRarity('Hero', 'Base Hero'),
                        ),
                        _RarityChip(
                          label: 'TOTW',
                          active: quickRarity == 'TOTW',
                          onTap: () =>
                              _applyQuickRarity('TOTW', 'Team of the week'),
                        ),
                        _RarityChip(
                          label: 'Hall',
                          active: quickRarity == 'Hall',
                          onTap: () => _applyQuickRarity('Hall', 'Hall of FUT'),
                        ),
                        _RarityChip(
                          label: 'Holo',
                          active: quickRarity == 'Holo',
                          onTap: () => _applyQuickRarity('Holo', 'Holographic'),
                        ),
                        _RarityChip(
                          label: 'Silver',
                          active: quickRarity == 'Silver',
                          onTap: () => _applyQuickRarity('Silver', 'Silver'),
                        ),
                        _RarityChip(
                          label: 'Bronze',
                          active: quickRarity == 'Bronze',
                          onTap: () => _applyQuickRarity('Bronze', 'Bronze'),
                        ),
                      ],
                    ),
                  ),
                  if (filter.activeCount > 0) ...[
                    const SizedBox(height: FcbazSpace.sm),
                    _ActiveFilters(filter: filter, onClear: _clearAllFilters),
                  ],
                  const SizedBox(height: FcbazSpace.md),
                  if (!loading && error == null)
                    Row(
                      children: [
                        Text(
                          players.isEmpty
                              ? 'بدون نتیجه'
                              : '${players.length} کارت',
                          style: TextStyle(
                            color: palette.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        _PriceFreshnessChip(
                          updatedAt: priceUpdatedAt,
                          ageLabel: priceUpdatedAt == null
                              ? null
                              : _priceAgeLabel(priceUpdatedAt!),
                          onTap: _showPriceFreshnessSheet,
                        ),
                      ],
                    ),
                  const SizedBox(height: FcbazSpace.sm),
                ],
              ),
            ),
          ),
          if (showingDiscovery) ..._discoverySlivers(),
          if (loading)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: SliverToBoxAdapter(child: PlayerGridSkeleton()),
            )
          else if (error != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: SliverToBoxAdapter(
                child: AppErrorState(
                  title: 'کاتالوگ در دسترس نیست',
                  message: error!,
                  onRetry: _load,
                ),
              ),
            )
          else if (players.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: SliverToBoxAdapter(
                child: AppEmptyState(
                  icon: Icons.style_rounded,
                  title: 'کارتی پیدا نشد',
                  message: filter.activeCount > 0 || filter.query.isNotEmpty
                      ? 'جستجو یا فیلترها را تغییر بده.'
                      : 'کاتالوگ معتبر فعلاً آیتمی برنگرداند.',
                  actionLabel: filter.activeCount > 0 || filter.query.isNotEmpty
                      ? 'پاک کردن همه'
                      : null,
                  onAction: _clearAllFilters,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 34),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 10,
                  childAspectRatio: .5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PlayerMarketTile(
                    player: players[index],
                    pricePlatform: filter.platform,
                    heroTag: playerHeroTag(players[index].id),
                  ),
                  childCount: players.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _discoverySlivers() {
    if (loadingDiscovery) return const [];
    final hasContent =
        trending.isNotEmpty ||
        recent.isNotEmpty ||
        savedFilters.isNotEmpty ||
        favorites.isNotEmpty;
    if (!hasContent) return const [];

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recent.isNotEmpty) ...[
                SectionHeader(
                  kicker: 'RECENT',
                  title: 'جستجوهای اخیر',
                  actionLabel: 'پاک کردن',
                  onAction: _clearRecent,
                ),
                const SizedBox(height: FcbazSpace.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final item in recent)
                      ActionChip(
                        avatar: const Icon(Icons.history_rounded, size: 16),
                        label: Text(item),
                        onPressed: () {
                          controller.text = item;
                          setState(() => filter = filter.copyWith(query: item));
                          _search();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: FcbazSpace.xl),
              ],
              if (savedFilters.isNotEmpty) ...[
                const SectionHeader(
                  kicker: 'SAVED VIEWS',
                  title: 'نماهای ذخیره‌شده',
                ),
                const SizedBox(height: FcbazSpace.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final saved in savedFilters.take(8))
                      InputChip(
                        avatar: const Icon(Icons.bookmark_rounded, size: 16),
                        label: Text(saved.name),
                        onPressed: () => _applySavedView(saved),
                        onDeleted: () => _deleteSavedView(saved),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      ),
                  ],
                ),
                const SizedBox(height: FcbazSpace.xl),
              ],
              if (trending.isNotEmpty) ...[
                SectionHeader(kicker: 'TRENDING', title: 'کارت‌های داغ'),
                const SizedBox(height: FcbazSpace.sm),
                SizedBox(
                  height: 310,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    cacheExtent: 600,
                    itemCount: math.min(8, trending.length),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) => SizedBox(
                      width: 154,
                      child: PlayerMarketTile(
                        player: trending[index],
                        pricePlatform: filter.platform,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: FcbazSpace.xl),
              ],
              if (favorites.isNotEmpty) ...[
                const SectionHeader(
                  kicker: 'FAVORITES',
                  title: 'علاقه‌مندی‌ها',
                ),
                const SizedBox(height: FcbazSpace.sm),
                SizedBox(
                  height: 310,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    cacheExtent: 600,
                    itemCount: math.min(8, favorites.length),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) => SizedBox(
                      width: 154,
                      child: PlayerMarketTile(
                        player: favorites[index],
                        pricePlatform: filter.platform,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: FcbazSpace.xl),
              ],
              const SectionHeader(kicker: 'CATALOG', title: 'همه کارت‌ها'),
              const SizedBox(height: FcbazSpace.xs),
            ],
          ),
        ),
      ),
    ];
  }
}

class _PriceFreshnessChip extends StatelessWidget {
  const _PriceFreshnessChip({
    required this.updatedAt,
    required this.ageLabel,
    required this.onTap,
  });

  final DateTime? updatedAt;
  final String? ageLabel;
  final VoidCallback onTap;

  /// Green under an hour, amber under six hours, red beyond that; the verified
  /// snapshot age is visible without opening anything.
  Color _dotColor(FcbazPalette palette) {
    final at = updatedAt;
    if (at == null) return palette.lineStrong;
    final age = DateTime.now().difference(at.toLocal());
    if (age.inMinutes < 60) return palette.success;
    if (age.inHours < 6) return palette.warning;
    return palette.danger;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = ageLabel == null ? 'کاتالوگ FC27' : 'قیمت‌ها · $ageLabel';
    return Semantics(
      button: true,
      label: 'تازگی قیمت‌ها: $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FcbazRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: palette.surfaceRaised.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(FcbazRadius.pill),
              border: Border.all(color: palette.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _dotColor(palette),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: palette.textMuted.withValues(alpha: .8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FreshnessRow extends StatelessWidget {
  const _FreshnessRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: palette.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: palette.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RarityChip extends StatelessWidget {
  const _RarityChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, textDirection: TextDirection.ltr),
        selected: active,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: palette.primary,
        labelStyle: TextStyle(
          color: active ? palette.onPrimary : palette.text,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.filter, required this.onClear});

  final PlayerFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (filter.position != null) filter.position!,
      if (filter.version != null) filter.version!,
      if (filter.league != null) filter.league!,
      if (filter.club != null) filter.club!,
      if (filter.nation != null) filter.nation!,
      if (filter.minRating != 40 || filter.maxRating != 99)
        'OVR ${filter.minRating}–${filter.maxRating}',
      if (filter.platform == 'pc') 'PC',
      if (filter.role != null) 'Role ${filter.role!}',
      if (filter.playStyle != null) filter.playStyle!,
      if (filter.playStylePlus != null) '+ ${filter.playStylePlus!}',
    ];

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final label in labels) ...[
            Chip(label: Text(label)),
            const SizedBox(width: 5),
          ],
          ActionChip(
            avatar: const Icon(Icons.close_rounded, size: 15),
            label: const Text('پاک کردن'),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
