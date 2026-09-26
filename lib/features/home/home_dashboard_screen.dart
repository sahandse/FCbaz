import 'package:flutter/material.dart';

import '../club/presentation/my_club_screen.dart';
import '../evolutions/presentation/evolutions_screen.dart';
import '../market/presentation/market_screen.dart';
import '../players/presentation/player_card.dart';
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
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      loading = true;
      error = null;
    });
    final localFuture = localService.load();
    HomeFeed? live;
    try {
      live = await feedRepository.getFeed(forceRefresh: forceRefresh);
    } catch (e) {
      error = e.toString();
    }
    final localData = await localFuture;
    if (!mounted) return;
    setState(() {
      feed = live;
      local = localData;
      loading = false;
    });
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  String _sync(DateTime? at) {
    if (at == null) return 'LIVE CATALOG';
    final v = at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'SYNC ${two(v.hour)}:${two(v.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final live = feed;
    final snapshot = local;

    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(17, 17, 17, 15),
            decoration: BoxDecoration(
              color: const Color(0xFF080D09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.primary.withValues(alpha: .28)),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  scheme.primary.withValues(alpha: .14),
                  const Color(0xFF080D09),
                  scheme.secondary.withValues(alpha: .05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        'FC27',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: Color(0xFF10140C), fontWeight: FontWeight.w900, fontSize: 10),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      loading ? 'SYNCING…' : _sync(live?.liveGeneratedAt),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 9.5, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'YOUR CLUB.\nYOUR MARKET.',
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, height: .95, letterSpacing: -1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  'بازیکنان، بازار، SBC، Evolution و تیم‌ساز در یک هاب مینیمال.',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5, height: 1.5),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.onOpenPlayers,
                        icon: const Icon(Icons.style_rounded, size: 18),
                        label: const Text('بازیکنان'),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onOpenSearch,
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('جستجو'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (snapshot != null)
            Row(
              children: [
                Expanded(child: _Metric(value: '${snapshot.clubCount}', label: 'CLUB', onTap: () => _open(const MyClubScreen()))),
                const SizedBox(width: 6),
                Expanded(child: _Metric(value: '${snapshot.watchlistCount}', label: 'WATCH', onTap: () => _open(const MarketScreen()))),
                const SizedBox(width: 6),
                Expanded(child: _Metric(value: '${snapshot.savedSquads}', label: 'SQUADS', onTap: widget.onOpenSquad)),
                const SizedBox(width: 6),
                Expanded(child: _Metric(value: snapshot.objectiveTasks == 0 ? '—' : '${(snapshot.objectiveProgress * 100).round()}%', label: 'OBJ', onTap: () => _open(const ObjectivesScreen()))),
              ],
            ),
          const SizedBox(height: 20),
          _Header(title: 'HOT ITEMS', subtitle: 'بازیکنان داغ FC27', trailing: widget.onOpenPlayers),
          const SizedBox(height: 9),
          if (live?.trendingPlayers.isNotEmpty == true)
            SizedBox(
              height: 254,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: live!.trendingPlayers.take(8).length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, index) => SizedBox(width: 168, child: PlayerCard(player: live!.trendingPlayers[index])),
              ),
            )
          else if (!loading)
            _Empty(
              title: 'Popular data unavailable',
              subtitle: 'اگر منبع Popular واقعی پاسخ ندهد چیزی جایگزین و جعل نمی‌شود.',
              onTap: () => _load(forceRefresh: true),
            ),
          const SizedBox(height: 20),
          const _Header(title: 'LIVE HUB', subtitle: 'محتوای زنده FC27'),
          const SizedBox(height: 9),
          if (live != null)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
              childAspectRatio: 1.55,
              children: [
                _Hub(label: 'SBC', count: live.sbcs.length, icon: Icons.extension_rounded, onTap: () => _open(const SbcScreen())),
                _Hub(label: 'EVOLUTIONS', count: live.evolutions.length, icon: Icons.auto_awesome_rounded, onTap: () => _open(const EvolutionsScreen())),
                _Hub(label: 'OBJECTIVES', count: live.objectives.length, icon: Icons.flag_rounded, onTap: () => _open(const ObjectivesScreen())),
                _Hub(label: 'MARKET', count: live.marketMovers.length, icon: Icons.query_stats_rounded, onTap: () => _open(const MarketScreen())),
              ],
            ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              'بخشی از منابع آنلاین پاسخ نداد؛ فقط داده معتبر موجود نمایش داده شده است.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.onTap});
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Column(
            children: [
              Text(value, textDirection: TextDirection.ltr, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 2),
              Text(label, textDirection: TextDirection.ltr, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 8, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, this.trailing});
  final String title;
  final String subtitle;
  final VoidCallback? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -.4)),
              Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10.5)),
            ],
          ),
        ),
        if (trailing != null) IconButton(onPressed: trailing, icon: const Icon(Icons.arrow_back_rounded), tooltip: 'نمایش همه'),
      ],
    );
  }
}

class _Hub extends StatelessWidget {
  const _Hub({required this.label, required this.count, required this.icon, required this.onTap});
  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                    Text('$count LIVE', textDirection: TextDirection.ltr, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.cloud_off_rounded),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: IconButton(onPressed: onTap, icon: const Icon(Icons.refresh_rounded)),
      ),
    );
  }
}
