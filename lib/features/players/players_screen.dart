import 'package:flutter/material.dart';

import 'data/player_repository.dart';
import 'domain/player.dart';
import 'presentation/advanced_player_filter_sheet.dart';
import 'presentation/player_card.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final repository = PlayerRepository();

  List<Player> players = const [];
  PlayerFilter filter = const PlayerFilter();
  PlayerFacets facets = const PlayerFacets();

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
      final result = await repository.advanced(filter);
      if (!mounted) return;
      setState(() {
        players = result.players;
        facets = result.facets;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
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

    setState(() => filter = result);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بازیکنان FC27',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'فیلتر حرفه‌ای روی دیتای واقعی',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
          if (filter.activeCount > 0) ...[
            const SizedBox(height: 12),
            _ActiveFilters(
              filter: filter,
              onClear: () {
                setState(() => filter = const PlayerFilter());
                _load();
              },
            ),
          ],
          const SizedBox(height: 16),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 72),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            _StateCard(
              icon: Icons.cloud_off_rounded,
              title: 'داده بازیکنان در دسترس نیست',
              subtitle: error!,
              actionLabel: 'تلاش دوباره',
              onAction: _load,
            )
          else if (players.isEmpty)
            _StateCard(
              icon: Icons.person_search_rounded,
              title: 'بازیکنی پیدا نشد',
              subtitle: filter.activeCount > 0
                  ? 'فیلترها را تغییر بده.'
                  : 'منبع واقعی در حال حاضر نتیجه‌ای برنگرداند.',
              actionLabel: filter.activeCount > 0 ? 'پاک کردن فیلترها' : null,
              onAction: filter.activeCount > 0
                  ? () {
                      setState(() => filter = const PlayerFilter());
                      _load();
                    }
                  : null,
            )
          else ...[
            Row(
              children: [
                Text(
                  players.length.toString() + ' نتیجه',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Icon(
                  Icons.verified_rounded,
                  size: 17,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'FC27 واقعی',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final player in players) ...[
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

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.filter,
    required this.onClear,
  });

  final PlayerFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (filter.position != null) filter.position!,
      if (filter.version != null) filter.version!,
      if (filter.rarity != null) filter.rarity!,
      if (filter.cardType != null) filter.cardType!,
      if (filter.league != null) filter.league!,
      if (filter.club != null) filter.club!,
      if (filter.nation != null) filter.nation!,
      if (filter.minRating != 40 || filter.maxRating != 99)
        'OVR ' +
            filter.minRating.toString() +
            '–' +
            filter.maxRating.toString(),
      if (filter.minPrice != null || filter.maxPrice != null)
        'Price ' +
            (filter.minPrice?.toString() ?? '0') +
            '–' +
            (filter.maxPrice?.toString() ?? '∞'),
      if (filter.platform == 'pc') 'PC',
    ];

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final label in labels) ...[
            Chip(label: Text(label)),
            const SizedBox(width: 6),
          ],
          ActionChip(
            avatar: const Icon(Icons.close_rounded, size: 16),
            label: const Text('پاک کردن'),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
