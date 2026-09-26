import 'dart:async';

import 'package:flutter/material.dart';

import '../players/data/player_repository.dart';
import '../players/domain/player.dart';
import '../players/presentation/advanced_player_filter_sheet.dart';
import '../players/presentation/player_card.dart';
import 'search_history_repository.dart';
import '../settings/app_settings_repository.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final repository = PlayerRepository();
  final historyRepository = SearchHistoryRepository();
  final settingsRepository = AppSettingsRepository();
  final controller = TextEditingController();

  Timer? debounce;
  List<Player> results = const [];
  List<Player> trending = const [];
  List<Player> favorites = const [];
  List<String> recent = const [];
  List<SavedPlayerFilter> savedFilters = const [];

  PlayerFilter filter = const PlayerFilter();
  PlayerFacets facets = const PlayerFacets();

  bool loading = false;
  bool loadingDiscovery = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final settings = await settingsRepository.load();
    if (!mounted) return;
    setState(() {
      filter = filter.copyWith(platform: settings.defaultPlatform);
    });
    await _loadDiscovery();
  }

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadDiscovery() async {
    setState(() => loadingDiscovery = true);

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

  void _onChanged(String value) {
    debounce?.cancel();
    final query = value.trim();

    setState(() {
      filter = filter.copyWith(query: query);
    });

    if (query.length < 2) {
      setState(() {
        results = const [];
        error = null;
        loading = false;
      });
      return;
    }

    debounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(),
    );
  }

  Future<void> _search() async {
    final queryAtStart = filter.query.trim();
    if (queryAtStart.length < 2) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await repository.advanced(filter);
      if (!mounted || filter.query.trim() != queryAtStart) return;

      await historyRepository.addRecentSearch(queryAtStart);

      setState(() {
        results = data.players;
        facets = data.facets;
      });

      recent = await historyRepository.recentSearches();
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        results = const [];
        error = e.toString();
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<PlayerFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AdvancedPlayerFilterSheet(
        current: filter,
        facets: facets,
      ),
    );

    if (result == null) return;

    setState(() {
      filter = result.copyWith(query: controller.text.trim());
    });

    if (controller.text.trim().length >= 2) {
      await _search();
    }
  }

  Future<void> _saveCurrentFilter() async {
    if (filter.activeCount == 0 && filter.query.trim().isEmpty) return;

    final nameController = TextEditingController(
      text: filter.query.trim().isEmpty
          ? 'فیلتر FC27'
          : 'جستجوی ' + filter.query.trim(),
    );

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ذخیره فیلتر'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'نام فیلتر'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              nameController.text.trim(),
            ),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    nameController.dispose();
    if (name == null || name.isEmpty) return;

    await historyRepository.saveFilter(name, filter);
    savedFilters = await historyRepository.savedFilters();
    if (mounted) setState(() {});
  }

  Future<void> _applySavedFilter(SavedPlayerFilter saved) async {
    final savedQuery = saved.filter.query.trim();
    controller.text = savedQuery;
    setState(() => filter = saved.filter);

    if (savedQuery.length >= 2) {
      await _search();
    } else {
      final data = await repository.advanced(saved.filter);
      if (!mounted) return;
      setState(() {
        results = data.players;
        facets = data.facets;
      });
    }
  }

  void _searchText(String value) {
    controller.text = value;
    filter = filter.copyWith(query: value);
    setState(() {});
    _search();
  }

  void _clear() {
    debounce?.cancel();
    controller.clear();
    setState(() {
      filter = const PlayerFilter();
      results = const [];
      error = null;
      loading = false;
    });
  }

  Future<void> _clearRecent() async {
    await historyRepository.clearRecentSearches();
    if (!mounted) return;
    setState(() => recent = const []);
  }

  @override
  Widget build(BuildContext context) {
    final query = controller.text.trim();
    final showingDiscovery = query.length < 2 && results.isEmpty;

    return RefreshIndicator(
      onRefresh: _loadDiscovery,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'جستجوی بازیکن',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton.filledTonal(
                onPressed: _saveCurrentFilter,
                icon: const Icon(Icons.bookmark_add_outlined),
                tooltip: 'ذخیره جستجو/فیلتر',
              ),
              const SizedBox(width: 6),
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
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'نام بازیکن...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          if (filter.activeCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              filter.activeCount.toString() + ' فیلتر فعال',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (showingDiscovery)
            _DiscoveryContent(
              loading: loadingDiscovery,
              trending: trending,
              favorites: favorites,
              recent: recent,
              savedFilters: savedFilters,
              onSearchText: _searchText,
              onApplySaved: _applySavedFilter,
              onDeleteSaved: (id) async {
                await historyRepository.deleteSavedFilter(id);
                savedFilters = await historyRepository.savedFilters();
                if (mounted) setState(() {});
              },
              onClearRecent: _clearRecent,
              onRefreshFavorites: () async {
                favorites = await historyRepository.favorites();
                if (mounted) setState(() {});
              },
            )
          else if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            _SearchMessage(
              icon: Icons.cloud_off_rounded,
              title: 'جستجو در دسترس نیست',
              subtitle: error!,
            )
          else if (results.isEmpty)
            const _SearchMessage(
              icon: Icons.search_off_rounded,
              title: 'نتیجه‌ای پیدا نشد',
              subtitle: 'نام یا فیلترها را تغییر بده.',
            )
          else ...[
            Row(
              children: [
                Text(
                  results.length.toString() + ' نتیجه',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Text(
                  filter.platform == 'pc' ? 'قیمت رایانه' : 'قیمت کنسول',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final player in results) ...[
              PlayerCard(
                player: player,
                pricePlatform: filter.platform,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _DiscoveryContent extends StatelessWidget {
  const _DiscoveryContent({
    required this.loading,
    required this.trending,
    required this.favorites,
    required this.recent,
    required this.savedFilters,
    required this.onSearchText,
    required this.onApplySaved,
    required this.onDeleteSaved,
    required this.onClearRecent,
    required this.onRefreshFavorites,
  });

  final bool loading;
  final List<Player> trending;
  final List<Player> favorites;
  final List<String> recent;
  final List<SavedPlayerFilter> savedFilters;
  final ValueChanged<String> onSearchText;
  final ValueChanged<SavedPlayerFilter> onApplySaved;
  final ValueChanged<String> onDeleteSaved;
  final VoidCallback onClearRecent;
  final VoidCallback onRefreshFavorites;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 56),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trending.isNotEmpty) ...[
          const _Header(
            title: 'بازیکنان ترند',
            subtitle: 'بر اساس داده زنده بازار',
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: trending.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final p = trending[index];
                return SizedBox(
                  width: 116,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onSearchText(p.name),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundImage: p.imageUrl.isEmpty
                                  ? null
                                  : NetworkImage(p.imageUrl),
                              child: p.imageUrl.isEmpty
                                  ? Text(p.rating.toString())
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              p.rating.toString() + ' • ' + p.position,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const _Header(
            title: 'جستجوهای محبوب',
            subtitle: 'نام‌های پرتکرار در ترند زنده بازار',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final p in trending.take(8))
                ActionChip(
                  avatar: const Icon(Icons.trending_up_rounded, size: 16),
                  label: Text(p.name),
                  onPressed: () => onSearchText(p.name),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              const Expanded(
                child: _Header(
                  title: 'جستجوهای اخیر',
                  subtitle: 'فقط روی همین گوشی',
                ),
              ),
              TextButton(
                onPressed: onClearRecent,
                child: const Text('پاک کردن'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final item in recent)
                ActionChip(
                  avatar: const Icon(Icons.history_rounded, size: 16),
                  label: Text(item),
                  onPressed: () => onSearchText(item),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (savedFilters.isNotEmpty) ...[
          const _Header(
            title: 'فیلترهای ذخیره‌شده',
            subtitle: 'با یک لمس دوباره اجرا کن',
          ),
          const SizedBox(height: 8),
          for (final saved in savedFilters.take(8)) ...[
            Card(
              child: ListTile(
                onTap: () => onApplySaved(saved),
                leading: const Icon(Icons.bookmark_rounded),
                title: Text(
                  saved.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  saved.filter.activeCount.toString() + ' فیلتر فعال',
                ),
                trailing: IconButton(
                  onPressed: () => onDeleteSaved(saved.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
            ),
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 14),
        ],
        if (favorites.isNotEmpty) ...[
          Row(
            children: [
              const Expanded(
                child: _Header(
                  title: 'علاقه‌مندی‌ها',
                  subtitle: 'کارت‌های ذخیره‌شده روی دستگاه',
                ),
              ),
              IconButton(
                onPressed: onRefreshFavorites,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final player in favorites.take(8)) ...[
            PlayerCard(player: player),
            const SizedBox(height: 8),
          ],
        ],
        if (trending.isEmpty &&
            recent.isEmpty &&
            savedFilters.isEmpty &&
            favorites.isEmpty)
          const _SearchMessage(
            icon: Icons.manage_search_rounded,
            title: 'جستجوی پیشرفته FC27',
            subtitle:
                'حداقل دو حرف وارد کن یا از فیلترهای PlayStyles، Roles، حرکات مهارتی، پای ضعیف و بازه آمار استفاده کن.',
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              icon,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
