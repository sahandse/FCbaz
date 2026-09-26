import 'package:flutter/material.dart';

import '../club/presentation/my_club_screen.dart';
import '../market/presentation/market_screen.dart';
import '../players/presentation/player_details_screen.dart';
import '../sbc/presentation/sbc_screen.dart';
import '../evolutions/presentation/evolutions_screen.dart';
import 'home_local_dashboard_service.dart';
import 'home_repository.dart';
import 'objectives_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
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
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final feedRepository = HomeRepository();
  final localService = HomeLocalDashboardService();

  HomeFeed? feed;
  HomeLocalDashboard? local;
  bool loading = true;
  String? feedError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      loading = true;
      feedError = null;
    });

    final localFuture = localService.load();
    HomeFeed? liveFeed;
    String? liveError;
    try {
      liveFeed = await feedRepository.getFeed(forceRefresh: forceRefresh);
    } catch (e) {
      liveError = e.toString();
    }
    final localData = await localFuture;

    if (!mounted) return;
    setState(() {
      local = localData;
      feed = liveFeed;
      feedError = liveError;
      loading = false;
    });
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = local;
    final live = feed;

    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _WelcomeCard(
            onSearch: widget.onOpenSearch,
            onPlayers: widget.onOpenPlayers,
          ),
          const SizedBox(height: 18),
          Text('داشبورد من', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'خلاصه کاملاً محلی از داده‌هایی که روی همین دستگاه ذخیره کرده‌ای.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          if (snapshot == null && loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (snapshot != null) ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _MetricCard(
                  title: 'باشگاه من',
                  value: snapshot.clubCount.toString(),
                  subtitle: '${snapshot.tradeableCount} کارت قابل فروش',
                  icon: Icons.inventory_2_rounded,
                  onTap: () => _open(const MyClubScreen()),
                ),
                _MetricCard(
                  title: 'فهرست پیگیری',
                  value: snapshot.watchlistCount.toString(),
                  subtitle: snapshot.reachedTargets == 0
                      ? 'هدف قیمتی فعال نشده'
                      : '${snapshot.reachedTargets} هدف رسیده',
                  icon: Icons.visibility_rounded,
                  onTap: () => _open(const MarketScreen()),
                ),
                _MetricCard(
                  title: 'ترکیب‌ها',
                  value: snapshot.savedSquads.toString(),
                  subtitle: 'ذخیره‌شده روی دستگاه',
                  icon: Icons.stadium_rounded,
                  onTap: widget.onOpenSquad,
                ),
                _MetricCard(
                  title: 'پیشرفت هدف‌ها',
                  value: snapshot.objectiveTasks == 0
                      ? '—'
                      : '${(snapshot.objectiveProgress * 100).round()}٪',
                  subtitle: snapshot.objectiveTasks == 0
                      ? 'هنوز پیشرفتی ثبت نشده'
                      : '${snapshot.completedObjectiveTasks}/${snapshot.objectiveTasks} تسک کامل',
                  icon: Icons.flag_rounded,
                  onTap: () => _open(const ObjectivesScreen()),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Text('دسترسی سریع', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _QuickAction(
                title: 'جستجوی بازیکن',
                icon: Icons.search_rounded,
                onTap: widget.onOpenSearch,
              ),
              _QuickAction(
                title: 'ساخت ترکیب',
                icon: Icons.stadium_rounded,
                onTap: widget.onOpenSquad,
              ),
              _QuickAction(
                title: 'بازار',
                icon: Icons.query_stats_rounded,
                onTap: () => _open(const MarketScreen()),
              ),
              _QuickAction(
                title: 'همه ابزارها',
                icon: Icons.dashboard_customize_rounded,
                onTap: widget.onOpenMore,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'داده زنده FC27',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'فقط داده‌ای که منبع واقعی برگرداند نمایش داده می‌شود.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          if (feedError != null) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off_rounded),
                title: const Text('فید زنده فعلاً در دسترس نیست'),
                subtitle: Text(feedError!),
              ),
            ),
          ],
          if (live != null) ...[
            if (live.trendingPlayers.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _SectionHeader(title: 'بازیکنان محبوب'),
              const SizedBox(height: 8),
              SizedBox(
                height: 142,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: live.trendingPlayers.take(8).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final player = live.trendingPlayers[index];
                    return SizedBox(
                      width: 122,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _open(PlayerDetailsScreen(player: player)),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 29,
                                  backgroundImage: player.imageUrl.isEmpty
                                      ? null
                                      : NetworkImage(player.imageUrl),
                                  child: player.imageUrl.isEmpty
                                      ? Text(player.rating.toString())
                                      : null,
                                ),
                                const SizedBox(height: 7),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    player.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                Text('${player.rating} • ${player.position}'),
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
            if (live.sbcs.isNotEmpty) ...[
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'چالش‌های فعال',
                action: () => _open(const SbcScreen()),
              ),
              const SizedBox(height: 8),
              for (final sbc in live.sbcs.take(2))
                Card(
                  child: ListTile(
                    onTap: () => _open(SbcDetailScreen(sbc: sbc)),
                    leading: const Icon(Icons.extension_rounded),
                    title: Text(sbc.title),
                    subtitle: Text(sbc.reward.isEmpty ? sbc.category : sbc.reward),
                    trailing: const Icon(Icons.chevron_left_rounded),
                  ),
                ),
            ],
            if (live.evolutions.isNotEmpty) ...[
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'تکامل‌های فعال',
                action: () => _open(const EvolutionsScreen()),
              ),
              const SizedBox(height: 8),
              for (final evo in live.evolutions.take(2))
                Card(
                  child: ListTile(
                    onTap: () => _open(const EvolutionsScreen()),
                    leading: const Icon(Icons.auto_awesome_rounded),
                    title: Text(evo.title),
                    subtitle: Text(evo.cost == 0 ? 'رایگان' : '${evo.cost} سکه'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onSearch, required this.onPlayers});

  final VoidCallback onSearch;
  final VoidCallback onPlayers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            scheme.primary.withValues(alpha: .18),
            scheme.secondary.withValues(alpha: .07),
            scheme.surface,
          ],
        ),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FCBaz',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'داشبورد شخصی FC27؛ بدون ثبت‌نام، با داده محلی خودت و اطلاعات زنده واقعی.',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('جستجو'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onPlayers,
                  icon: const Icon(Icons.groups_2_rounded),
                  label: const Text('بازیکنان'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: scheme.primary, size: 20),
                  const Spacer(),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21)),
                ],
              ),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 9),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        if (action != null)
          TextButton(onPressed: action, child: const Text('همه')),
      ],
    );
  }
}
