import 'package:flutter/material.dart';

import 'data/player_repository.dart';
import 'domain/player.dart';
import 'presentation/player_card.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final repository = PlayerRepository();
  List<Player> allPlayers = const [];
  PlayerFilter filter = const PlayerFilter();
  bool loading = true;
  String? error;

  List<Player> get visiblePlayers => repository.applyFilter(allPlayers, filter);

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
      final players = await repository.getPlayers();
      if (!mounted) return;
      setState(() => allPlayers = players);
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
      builder: (_) => _FilterSheet(current: filter),
    );
    if (result != null) {
      setState(() => filter = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = visiblePlayers;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'بازیکنان FC27',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Badge(
                isLabelVisible: filter.position != null || filter.minRating != 40 || filter.maxRating != 99,
                child: IconButton.filledTonal(
                  onPressed: _openFilters,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'فیلتر بر اساس پست، ریتینگ و آمار؛ بدون داده ساختگی.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
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
            const _StateCard(
              icon: Icons.person_search_rounded,
              title: 'بازیکنی پیدا نشد',
              subtitle: 'فیلترها را تغییر بده یا بعداً دوباره بررسی کن.',
            )
          else ...[
            Row(
              children: [
                Text(
                  players.length.toString() + ' بازیکن',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  'داده واقعی FC27',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final player in players) ...[
              PlayerCard(player: player),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current});
  final PlayerFilter current;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? position = widget.current.position;
  late RangeValues rating = RangeValues(
    widget.current.minRating.toDouble(),
    widget.current.maxRating.toDouble(),
  );
  late PlayerSort sort = widget.current.sort;

  static const positions = [
    'GK', 'CB', 'LB', 'RB', 'CDM', 'CM', 'CAM', 'LM', 'RM', 'LW', 'RW', 'CF', 'ST'
  ];

  String sortTitle(PlayerSort value) {
    switch (value) {
      case PlayerSort.ratingDesc: return 'بیشترین ریتینگ';
      case PlayerSort.ratingAsc: return 'کمترین ریتینگ';
      case PlayerSort.pace: return 'بیشترین سرعت';
      case PlayerSort.shooting: return 'بهترین شوت';
      case PlayerSort.passing: return 'بهترین پاس';
      case PlayerSort.dribbling: return 'بهترین دریبل';
      case PlayerSort.defending: return 'بهترین دفاع';
      case PlayerSort.physical: return 'بهترین فیزیک';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'فیلتر بازیکنان',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            const Text('پست', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('همه'),
                  selected: position == null,
                  onSelected: (_) => setState(() => position = null),
                ),
                for (final item in positions)
                  ChoiceChip(
                    label: Text(item),
                    selected: position == item,
                    onSelected: (_) => setState(() => position = item),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'ریتینگ: ' + rating.start.round().toString() + ' تا ' + rating.end.round().toString(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            RangeSlider(
              min: 40,
              max: 99,
              divisions: 59,
              values: rating,
              labels: RangeLabels(
                rating.start.round().toString(),
                rating.end.round().toString(),
              ),
              onChanged: (value) => setState(() => rating = value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PlayerSort>(
              value: sort,
              decoration: const InputDecoration(labelText: 'مرتب‌سازی'),
              items: [
                for (final value in PlayerSort.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(sortTitle(value)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => sort = value);
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, const PlayerFilter()),
                    child: const Text('پاک کردن'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      PlayerFilter(
                        position: position,
                        minRating: rating.start.round(),
                        maxRating: rating.end.round(),
                        sort: sort,
                      ),
                    ),
                    child: const Text('اعمال فیلتر'),
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
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
