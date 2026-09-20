import 'dart:async';

import 'package:flutter/material.dart';

import '../players/data/player_repository.dart';
import '../players/domain/player.dart';
import '../players/presentation/advanced_player_filter_sheet.dart';
import '../players/presentation/player_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final repository = PlayerRepository();
  final controller = TextEditingController();

  Timer? debounce;
  List<Player> results = const [];
  PlayerFilter filter = const PlayerFilter();
  PlayerFacets facets = const PlayerFacets();

  bool loading = false;
  String? error;

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
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

      setState(() {
        results = data.players;
        facets = data.facets;
      });
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

  @override
  Widget build(BuildContext context) {
    final query = controller.text.trim();

    return ListView(
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
        if (query.length < 2)
          const _SearchMessage(
            icon: Icons.manage_search_rounded,
            title: 'جستجوی پیشرفته FC27',
            subtitle:
                'حداقل دو حرف وارد کن؛ بعد می‌توانی Version، لیگ، باشگاه، ملیت، ریتینگ و قیمت را فیلتر کنی.',
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
                filter.platform == 'pc' ? 'PC Price' : 'Console Price',
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
