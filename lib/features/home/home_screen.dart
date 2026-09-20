import 'package:flutter/material.dart';

import '../evolutions/presentation/evolutions_screen.dart';
import '../players/presentation/player_details_screen.dart';
import '../sbc/presentation/sbc_screen.dart';
import 'home_repository.dart';
import 'objectives_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onOpenPlayers,
    required this.onOpenSearch,
    required this.onOpenSquad,
    required this.onOpenMore,
    super.key,
  });

  final VoidCallback onOpenPlayers;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenSquad;
  final VoidCallback onOpenMore;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repository = HomeRepository();

  HomeFeed? feed;
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
      final data = await repository.getFeed();
      if (!mounted) return;
      setState(() => feed = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _text(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final data = feed;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _HeroCard(
            onPlayers: widget.onOpenPlayers,
            onSearch: widget.onOpenSearch,
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.65,
            children: [
              _QuickAction(
                title: 'بازیکنان',
                subtitle: 'دیتابیس و فیلترها',
                icon: Icons.groups_2_rounded,
                onTap: widget.onOpenPlayers,
              ),
              _QuickAction(
                title: 'تیم‌ساز',
                subtitle: 'Squad + Chemistry',
                icon: Icons.stadium_rounded,
                onTap: widget.onOpenSquad,
              ),
              _QuickAction(
                title: 'جستجو',
                subtitle: 'بازیکن و کارت',
                icon: Icons.search_rounded,
                onTap: widget.onOpenSearch,
              ),
              _QuickAction(
                title: 'ابزارها',
                subtitle: 'SBC، Evo و بازار',
                icon: Icons.dashboard_customize_rounded,
                onTap: widget.onOpenMore,
              ),
            ],
          ),
          if (loading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ] else if (error != null) ...[
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off_rounded),
                title: const Text('Home Feed در دسترس نیست'),
                subtitle: Text(error!),
                trailing: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
            ),
          ] else if (data != null) ...[
            if (data.trendingPlayers.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionTitle(
                title: 'Trending Players',
                subtitle: 'بر اساس داده زنده بازار FC27',
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 154,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.trendingPlayers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 9),
                  itemBuilder: (_, index) {
                    final player = data.trendingPlayers[index];
                    return SizedBox(
                      width: 128,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlayerDetailsScreen(player: player),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundImage: player.imageUrl.isEmpty
                                      ? null
                                      : NetworkImage(player.imageUrl),
                                  child: player.imageUrl.isEmpty
                                      ? Text(player.rating.toString())
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  player.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  player.rating.toString() +
                                      ' • ' +
                                      player.position,
                                  style:
                                      Theme.of(context).textTheme.labelSmall,
                                ),
                                if (player.version.isNotEmpty)
                                  Text(
                                    player.version,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
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
            ],
            if (data.marketMovers.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionTitle(
                title: 'Market Movers',
                subtitle: 'حرکت‌های مهم بازار از منبع زنده',
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.marketMovers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final item = data.marketMovers[index];
                    return Container(
                      width: 178,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(item, ['name', 'player_name']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _text(item, [
                              'change_percent',
                              'change',
                              'trend',
                            ]),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _text(item, ['price', 'current']),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            if (data.sbcs.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'SBCهای جدید',
                subtitle: 'چالش‌های فعال FC27',
                trailing: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SbcScreen()),
                  ),
                  child: const Text('همه'),
                ),
              ),
              const SizedBox(height: 8),
              for (final item in data.sbcs.take(3)) ...[
                Card(
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SbcDetailScreen(sbc: item),
                      ),
                    ),
                    leading: const Icon(Icons.extension_rounded),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      item.reward.isEmpty ? item.category : item.reward,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded),
                  ),
                ),
                const SizedBox(height: 7),
              ],
            ],
            if (data.evolutions.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionTitle(
                title: 'Evolutions',
                subtitle: 'Evoهای فعال و جدید',
                trailing: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EvolutionsScreen(),
                    ),
                  ),
                  child: const Text('همه'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.evolutions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final evo = data.evolutions[index];
                    return SizedBox(
                      width: 210,
                      child: Card(
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EvolutionsScreen(),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  evo.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  evo.cost == 0
                                      ? 'رایگان'
                                      : evo.cost.toString() + ' Coins',
                                  style:
                                      Theme.of(context).textTheme.labelSmall,
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
            ],
            if (data.objectives.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'Objectives',
                subtitle: 'هدف‌ها و پاداش‌های زنده',
                trailing: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ObjectivesScreen(),
                    ),
                  ),
                  child: const Text('همه'),
                ),
              ),
              const SizedBox(height: 8),
              for (final item in data.objectives.take(3)) ...[
                Card(
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ObjectivesScreen(),
                      ),
                    ),
                    leading: const Icon(Icons.flag_rounded),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      item.reward.isEmpty ? item.description : item.reward,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
              ],
            ],
          ],
          const SizedBox(height: 22),
          _DataStatusCard(hasFeed: data != null && error == null),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.onPlayers,
    required this.onSearch,
  });

  final VoidCallback onPlayers;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            scheme.primary.withValues(alpha: .19),
            scheme.secondary.withValues(alpha: .08),
            scheme.surface,
          ],
        ),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'FC27 • Ultimate Team',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'FCBaz',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'ترند بازار، بازیکنان، SBC، Evo، Objectives و ابزارهای Squad در یک داشبورد فارسی.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPlayers,
                  icon: const Icon(Icons.groups_2_rounded),
                  label: const Text('بازیکنان'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded),
                tooltip: 'جستجو',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataStatusCard extends StatelessWidget {
  const _DataStatusCard({required this.hasFeed});
  final bool hasFeed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.primary.withValues(alpha: .22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              hasFeed
                  ? Icons.verified_rounded
                  : Icons.info_outline_rounded,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasFeed
                  ? 'Home Feed از داده واقعی FC27 دریافت شده است.'
                  : 'اگر منبع واقعی در دسترس نباشد، FCBaz داده ساختگی جایگزین نمی‌کند.',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 9),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
