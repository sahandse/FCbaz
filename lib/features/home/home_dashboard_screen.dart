import 'package:flutter/material.dart';

import '../club/presentation/my_club_screen.dart';
import '../evolutions/presentation/evolutions_screen.dart';
import '../market/presentation/market_screen.dart';
import '../players/presentation/player_details_screen.dart';
import '../sbc/presentation/sbc_screen.dart';
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
    } catch (error) {
      liveError = error.toString();
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

  String _coins(int value) {
    if (value <= 0) return '—';
    if (value >= 1000000) {
      final n = value / 1000000;
      return '${n.toStringAsFixed(n >= 10 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final n = value / 1000;
      return '${n.toStringAsFixed(n >= 100 ? 0 : 1)}K';
    }
    return value.toString();
  }

  String _syncLabel(DateTime? date) {
    if (date == null) return 'منبع عمومی زنده';
    final localDate = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'آخرین همگام‌سازی ${two(localDate.hour)}:${two(localDate.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = local;
    final live = feed;
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          _Hero(
            loading: loading,
            syncLabel: _syncLabel(live?.liveGeneratedAt),
            onSearch: widget.onOpenSearch,
            onPlayers: widget.onOpenPlayers,
          ),
          const SizedBox(height: 14),
          if (snapshot == null && loading)
            const _LoadingStrip()
          else if (snapshot != null)
            _LocalStrip(
              club: snapshot.clubCount,
              watchlist: snapshot.watchlistCount,
              squads: snapshot.savedSquads,
              objectives: snapshot.objectiveTasks == 0
                  ? '—'
                  : '${(snapshot.objectiveProgress * 100).round()}٪',
              onClub: () => _open(const MyClubScreen()),
              onMarket: () => _open(const MarketScreen()),
              onSquad: widget.onOpenSquad,
              onObjectives: () => _open(const ObjectivesScreen()),
            ),
          const SizedBox(height: 22),
          _SectionTitle(
            title: 'بازیکنان داغ بازار',
            subtitle: 'بازیکنان واقعی FC27 از منبع عمومی بازار',
            trailing: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          if (live?.trendingPlayers.isNotEmpty == true)
            SizedBox(
              height: 188,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: live!.trendingPlayers.take(10).length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final player = live.trendingPlayers[index];
                  final price = player.pricePs > 0 ? player.pricePs : player.pricePc;
                  return _TrendingPlayerCard(
                    name: player.name,
                    imageUrl: player.imageUrl,
                    rating: player.rating,
                    position: player.position,
                    version: player.version,
                    price: _coins(price),
                    onTap: () => _open(PlayerDetailsScreen(player: player)),
                  );
                },
              ),
            )
          else if (!loading)
            _EmptyState(
              icon: Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
              title: 'بازیکن زنده دریافت نشد',
              subtitle: 'با رفرش دوباره منبع قیمت عمومی بررسی می‌شود.',
              onTap: () => _load(forceRefresh: true),
            ),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Live Hub',
            subtitle: 'SBC، Evolution و Objectiveهای واقعی؛ بدون داده ساختگی',
          ),
          const SizedBox(height: 10),
          if (live != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _LiveHubCard(
                      width: width,
                      icon: Icons.extension_rounded,
                      title: 'SBC',
                      count: live.sbcs.length,
                      sample: live.sbcs.isEmpty ? '' : live.sbcs.first.primaryTitle,
                      accent: scheme.primary,
                      onTap: () => _open(const SbcScreen()),
                    ),
                    _LiveHubCard(
                      width: width,
                      icon: Icons.auto_awesome_rounded,
                      title: 'Evolutions',
                      count: live.evolutions.length,
                      sample: live.evolutions.isEmpty ? '' : live.evolutions.first.title,
                      accent: scheme.secondary,
                      onTap: () => _open(const EvolutionsScreen()),
                    ),
                    _LiveHubCard(
                      width: constraints.maxWidth,
                      icon: Icons.flag_rounded,
                      title: 'Objectives',
                      count: live.objectives.length,
                      sample: live.objectives.isEmpty ? '' : live.objectives.first.title,
                      accent: const Color(0xFFFFC857),
                      onTap: () => _open(const ObjectivesScreen()),
                    ),
                  ],
                );
              },
            )
          else if (!loading)
            _EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Live Hub در دسترس نیست',
              subtitle: 'آخرین snapshot واقعی حفظ می‌شود؛ داده فیک جایگزین نمی‌شود.',
              onTap: () => _load(forceRefresh: true),
            ),
          if (feedError != null) ...[
            const SizedBox(height: 10),
            _InfoBanner(text: 'بخشی از منابع آنلاین پاسخ نداد؛ اطلاعات معتبر موجود نمایش داده شده است.'),
          ],
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'ابزارهای سریع',
            subtitle: 'دسترسی مستقیم، بدون منوهای شلوغ',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickButton(
                  icon: Icons.search_rounded,
                  label: 'جستجو',
                  onTap: widget.onOpenSearch,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickButton(
                  icon: Icons.stadium_rounded,
                  label: 'تیم‌ساز',
                  onTap: widget.onOpenSquad,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickButton(
                  icon: Icons.query_stats_rounded,
                  label: 'بازار',
                  onTap: () => _open(const MarketScreen()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickButton(
                  icon: Icons.grid_view_rounded,
                  label: 'بیشتر',
                  onTap: widget.onOpenMore,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.loading,
    required this.syncLabel,
    required this.onSearch,
    required this.onPlayers,
  });

  final bool loading;
  final String syncLabel;
  final VoidCallback onSearch;
  final VoidCallback onPlayers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            scheme.primary.withValues(alpha: .22),
            scheme.secondary.withValues(alpha: .10),
            scheme.surface,
          ],
        ),
        border: Border.all(color: scheme.outline.withValues(alpha: .65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary,
                ),
                alignment: Alignment.center,
                child: Text(
                  'FC',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FCBaz',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.8,
                          ),
                    ),
                    Text(
                      'Ultimate Team companion • FC27',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: .68),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: loading ? const Color(0xFFFFC857) : scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      loading ? 'در حال بروزرسانی' : 'LIVE',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'دیتای واقعی، ابزارهای سریع، بدون ثبت‌نام.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            syncLabel,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search_rounded, size: 19),
                  label: const Text('جستجوی بازیکن'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onPlayers,
                icon: const Icon(Icons.groups_2_rounded),
                tooltip: 'همه بازیکنان',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocalStrip extends StatelessWidget {
  const _LocalStrip({
    required this.club,
    required this.watchlist,
    required this.squads,
    required this.objectives,
    required this.onClub,
    required this.onMarket,
    required this.onSquad,
    required this.onObjectives,
  });

  final int club;
  final int watchlist;
  final int squads;
  final String objectives;
  final VoidCallback onClub;
  final VoidCallback onMarket;
  final VoidCallback onSquad;
  final VoidCallback onObjectives;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniMetric(value: '$club', label: 'باشگاه', icon: Icons.inventory_2_rounded, onTap: onClub)),
        const SizedBox(width: 7),
        Expanded(child: _MiniMetric(value: '$watchlist', label: 'پیگیری', icon: Icons.visibility_rounded, onTap: onMarket)),
        const SizedBox(width: 7),
        Expanded(child: _MiniMetric(value: '$squads', label: 'ترکیب', icon: Icons.stadium_rounded, onTap: onSquad)),
        const SizedBox(width: 7),
        Expanded(child: _MiniMetric(value: objectives, label: 'اهداف', icon: Icons.flag_rounded, onTap: onObjectives)),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.value, required this.label, required this.icon, required this.onTap});

  final String value;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingPlayerCard extends StatelessWidget {
  const _TrendingPlayerCard({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.position,
    required this.version,
    required this.price,
    required this.onTap,
  });

  final String name;
  final String imageUrl;
  final int rating;
  final String position;
  final String version;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 142,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                scheme.primary.withValues(alpha: .18),
                                scheme.surfaceContainerHighest.withValues(alpha: .5),
                              ],
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: imageUrl.isEmpty
                              ? Icon(Icons.person_rounded, size: 52, color: scheme.primary)
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: 52, color: scheme.primary),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: .88),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$rating', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        [position, version].where((e) => e.isNotEmpty).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 9),
                      ),
                    ),
                    Text(price, textDirection: TextDirection.ltr, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveHubCard extends StatelessWidget {
  const _LiveHubCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.count,
    required this.sample,
    required this.accent,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final int count;
  final String sample;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [accent.withValues(alpha: .13), Colors.transparent],
              ),
              border: Border.all(color: scheme.outline.withValues(alpha: .55)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
                          Text('$count', style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 17)),
                        ],
                      ),
                      if (sample.isNotEmpty)
                        Text(
                          sample,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10),
                        )
                      else
                        Text('داده معتبر فعلاً موجود نیست', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle, this.trailing});

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary, size: 21),
              const SizedBox(height: 5),
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withValues(alpha: .55)),
        ),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.refresh_rounded),
          ],
        ),
      ),
    );
  }
}

class _LoadingStrip extends StatelessWidget {
  const _LoadingStrip();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 76,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
