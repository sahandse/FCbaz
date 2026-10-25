import 'package:flutter/material.dart';

import '../../src/theme/fcbaz_theme.dart';
import '../../src/ui/deadline_chip.dart';
import '../../src/ui/price_delta.dart';
import '../../src/ui/progress_ring.dart';
import '../../src/ui/section_header.dart';
import '../../src/ui/source_badge.dart';
import '../../src/ui/stadium_hero.dart';
import '../../src/utils/persian_formatters.dart';
import '../evolutions/presentation/evolutions_screen.dart';
import '../market/presentation/market_screen.dart';
import '../players/data/player_repository.dart';
import '../players/presentation/player_card.dart';
import '../players/presentation/player_details_screen.dart';
import '../sbc/presentation/sbc_screen.dart';
import '../settings/local_profile_repository.dart';
import 'home_local_dashboard_service.dart';
import 'home_repository.dart';
import 'objective_progress_repository.dart';
import 'objectives_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    required this.onOpenPlayers,
    required this.onOpenClub,
    super.key,
  });

  final VoidCallback onOpenPlayers;
  final VoidCallback onOpenClub;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final feedRepository = HomeRepository();
  final localService = HomeLocalDashboardService();
  final objectiveProgressRepository = ObjectiveProgressRepository();
  final profileRepository = LocalProfileRepository();
  final playerRepository = PlayerRepository();

  HomeFeed? feed;
  HomeLocalDashboard? local;
  Map<String, ObjectiveProgressEntry> objectiveProgress = const {};
  String displayName = '';
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
    final progressFuture = objectiveProgressRepository.getAll();
    final profileFuture = profileRepository.load();

    HomeFeed? live;
    String? liveError;
    try {
      live = await feedRepository.getFeed(forceRefresh: forceRefresh);
    } catch (e) {
      liveError = e.toString();
    }

    HomeLocalDashboard? localData;
    Map<String, ObjectiveProgressEntry> progressData = const {};
    var name = displayName;
    try {
      localData = await localFuture;
    } catch (_) {}
    try {
      progressData = await progressFuture;
    } catch (_) {}
    try {
      name = (await profileFuture).displayName;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      feed = live ?? feed;
      local = localData ?? local;
      objectiveProgress = progressData.isNotEmpty
          ? progressData
          : objectiveProgress;
      displayName = name;
      error = liveError;
      loading = false;
    });
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openMover(_Mover mover) async {
    if (mover.playerId.isNotEmpty) {
      try {
        final player = await playerRepository.getPlayer(mover.playerId);
        if (!mounted) return;
        _open(PlayerDetailsScreen(player: player));
        return;
      } catch (_) {}
    }
    if (!mounted) return;
    _open(const MarketScreen());
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    final base = hour < 12
        ? 'صبح بخیر'
        : hour < 17
        ? 'ظهر بخیر'
        : hour < 20
        ? 'عصر بخیر'
        : 'شب بخیر';
    final name = displayName.trim();
    return name.isEmpty ? base : '$base، $name';
  }

  List<_Deadline> _buildDeadlines(DateTime now) {
    final source = feed;
    if (source == null) return const [];
    final items = <_Deadline>[];

    for (final sbc in source.sbcs) {
      final expires = sbc.expiresAt?.toLocal();
      if (expires == null || !expires.isAfter(now)) continue;
      final reward = sbc.reward.trim();
      items.add(
        _Deadline(
          type: 'SBC',
          title: sbc.primaryTitle,
          expiresAt: expires,
          caption: reward.isEmpty ? 'جایزه نامشخص' : reward,
          icon: Icons.extension_rounded,
          onTap: () => _open(const SbcScreen()),
        ),
      );
    }

    for (final evolution in source.evolutions) {
      final expires = evolution.expiresAt?.toLocal();
      if (expires == null || !expires.isAfter(now)) continue;
      items.add(
        _Deadline(
          type: 'EVOLUTION',
          title: evolution.title,
          expiresAt: expires,
          caption: evolution.cost > 0
              ? '${compactCoinsFa(evolution.cost)} سکه'
              : 'رایگان',
          icon: Icons.auto_awesome_rounded,
          onTap: () => _open(const EvolutionsScreen()),
        ),
      );
    }

    for (final objective in source.objectives) {
      final expires = objective.expiresAt?.toLocal();
      if (expires == null || !expires.isAfter(now)) continue;
      final tasks = objective.tasks;
      final total = tasks.isEmpty ? objective.taskCount : tasks.length;
      final completed = tasks.isEmpty
          ? objectiveProgress.values
                .where(
                  (entry) =>
                      entry.objectiveId == objective.id && entry.completed,
                )
                .length
          : tasks
                .where(
                  (task) =>
                      objectiveProgress['${objective.id}::${task.id}']
                          ?.completed ==
                      true,
                )
                .length;
      final safeTotal = total <= 0 ? 0 : total;
      final safeCompleted = completed.clamp(0, safeTotal);
      items.add(
        _Deadline(
          type: 'OBJECTIVE',
          title: objective.title,
          expiresAt: expires,
          caption: safeTotal > 0
              ? '${faDigits(safeCompleted)} از ${faDigits(safeTotal)} وظیفه'
              : 'هدف فعال',
          icon: Icons.flag_rounded,
          progress: safeTotal > 0 ? safeCompleted / safeTotal : null,
          onTap: () => _open(const ObjectivesScreen()),
        ),
      );
    }

    items.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    return items.take(6).toList();
  }

  List<_Mover> get _movers {
    final source = feed;
    if (source == null) return const [];
    return source.marketMovers
        .map(_Mover.fromJson)
        .whereType<_Mover>()
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final now = DateTime.now();
    final snapshot = local;
    final live = feed;
    final clubCount = snapshot?.clubCount ?? 0;
    final emptyClub = snapshot == null || clubCount == 0;
    final deadlines = _buildDeadlines(now);
    final movers = _movers;
    final trending = live?.trendingPlayers.take(10).toList() ?? const [];
    final objectiveTasks = snapshot?.objectiveTasks ?? 0;
    final objectiveProgressValue = snapshot?.objectiveProgress ?? 0;

    return RefreshIndicator(
      onRefresh: () => _load(forceRefresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatJalaliDate(now),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.surfaceRaised.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: palette.line),
                ),
                child: Text(
                  'FC27',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1,
                    color: palette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FcbazSpace.md),
          StadiumHero(
            eyebrow: 'FC27 • Ultimate Team',
            title: emptyClub ? 'باشگاهت را بساز.' : 'باشگاهت، زنده.',
            subtitle: snapshot == null
                ? 'در حال خواندن باشگاه محلی…'
                : emptyClub
                ? 'اولین کارتت را اضافه کن تا ارزش، پیشرفت اهداف و تیم‌ها یک‌جا دیده شود.'
                : '${faDigits(snapshot.tradeableCount)} کارت قابل معامله • '
                      '${faDigits(snapshot.savedSquads)} تیم ذخیره‌شده',
            metric: snapshot == null ? '—' : faDigits(clubCount),
            metricLabel: 'کارت در باشگاه',
            metricNote: snapshot == null
                ? 'در حال همگام‌سازی'
                : snapshot.watchlistCount > 0
                ? '${faDigits(snapshot.watchlistCount)} کارت در واچ‌لیست'
                : 'واچ‌لیست خالی است',
            trailing: objectiveTasks > 0
                ? ProgressRing(
                    value: objectiveProgressValue,
                    label:
                        '${faDigits((objectiveProgressValue * 100).round())}٪',
                    semanticsLabel: 'پیشرفت اهداف',
                  )
                : null,
            primaryAction: FilledButton.icon(
              onPressed: widget.onOpenPlayers,
              icon: const Icon(Icons.style_rounded, size: 18),
              label: Text(emptyClub ? 'افزودن کارت' : 'کارت‌ها'),
            ),
            secondaryAction: OutlinedButton.icon(
              onPressed: widget.onOpenClub,
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: const Text('باشگاه'),
            ),
          ),
          if (loading && live != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(minHeight: 2),
            ),
          ],
          const SizedBox(height: FcbazSpace.xl),
          const SectionHeader(kicker: 'DEADLINES', title: 'امروز'),
          const SizedBox(height: 10),
          if (loading && live == null)
            const _RailSkeleton(height: 128, itemWidth: 236, count: 3)
          else if (deadlines.isEmpty)
            _InlineNotice(
              icon: Icons.event_available_rounded,
              title: 'مهلت فعالی ثبت نشده',
              message:
                  'فقط SBC، Evolution و اهدافی که منبع زنده برایشان زمان پایان اعلام کرده نمایش داده می‌شوند.',
              actionLabel: 'چالش‌ها',
              onAction: () => _open(const SbcScreen()),
            )
          else
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: deadlines.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) =>
                    _DeadlineCard(item: deadlines[index], now: now),
              ),
            ),
          const SizedBox(height: FcbazSpace.xl),
          SectionHeader(
            kicker: 'MARKET',
            title: 'حرکت‌های بازار',
            onAction: () => _open(const MarketScreen()),
          ),
          const SizedBox(height: 10),
          if (loading && live == null)
            const _ListSkeleton(count: 3)
          else if (movers.isEmpty)
            _InlineNotice(
              icon: Icons.query_stats_rounded,
              title: 'حرکت بازار در دسترس نیست',
              message:
                  'فقط حرکت‌هایی با منبع عمومی، قیمت و درصد تغییر واقعی نمایش داده می‌شوند.',
              actionLabel: 'بازار',
              onAction: () => _open(const MarketScreen()),
            )
          else
            for (var i = 0; i < movers.length; i++) ...[
              _MoverRow(mover: movers[i], onTap: () => _openMover(movers[i])),
              if (i != movers.length - 1) const SizedBox(height: 6),
            ],
          const SizedBox(height: FcbazSpace.xl),
          SectionHeader(
            kicker: 'TRENDING',
            title: 'کارت‌های داغ',
            onAction: widget.onOpenPlayers,
          ),
          const SizedBox(height: 10),
          if (loading && live == null)
            const _RailSkeleton(height: 222, itemWidth: 160, count: 3)
          else if (trending.isEmpty)
            _InlineNotice(
              icon: Icons.style_outlined,
              title: 'کارت داغی در دسترس نیست',
              message:
                  'فهرست محبوب‌ها فقط از منبع عمومی FC27 خوانده می‌شود و جایگزین جعلی ندارد.',
              actionLabel: 'کاتالوگ',
              onAction: widget.onOpenPlayers,
            )
          else
            SizedBox(
              height: 222,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: trending.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => SizedBox(
                  width: 160,
                  child: PlayerCard(player: trending[index]),
                ),
              ),
            ),
          const SizedBox(height: FcbazSpace.xl),
          const SectionHeader(kicker: 'SHORTCUTS', title: 'دسترسی سریع'),
          const SizedBox(height: 10),
          _QuickActionRow(
            first: _QuickAction(
              kicker: 'SBC',
              label: 'چالش‌ها',
              icon: Icons.extension_rounded,
              count: live?.sbcs.length,
              onTap: () => _open(const SbcScreen()),
            ),
            second: _QuickAction(
              kicker: 'EVOLUTION',
              label: 'ایوولوشن',
              icon: Icons.auto_awesome_rounded,
              count: live?.evolutions.length,
              onTap: () => _open(const EvolutionsScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _QuickActionRow(
            first: _QuickAction(
              kicker: 'OBJECTIVES',
              label: 'اهداف',
              icon: Icons.flag_rounded,
              count: live?.objectives.length,
              onTap: () => _open(const ObjectivesScreen()),
            ),
            second: _QuickAction(
              kicker: 'MARKET',
              label: 'بازار',
              icon: Icons.query_stats_rounded,
              count: live?.marketMovers.length,
              onTap: () => _open(const MarketScreen()),
            ),
          ),
          const SizedBox(height: FcbazSpace.xl),
          SourceBadge(
            source: 'FC27 Hub',
            updatedAt: live?.liveGeneratedAt,
            note: error == null
                ? 'باشگاه، اهداف و واچ‌لیست از حافظه این دستگاه خوانده می‌شوند.'
                : 'منبع زنده پاسخ نداد؛ فقط داده معتبر موجود نمایش داده شده است.',
            onRetry: error == null ? null : () => _load(forceRefresh: true),
          ),
        ],
      ),
    );
  }
}

class _Deadline {
  const _Deadline({
    required this.type,
    required this.title,
    required this.expiresAt,
    required this.caption,
    required this.icon,
    required this.onTap,
    this.progress,
  });

  final String type;
  final String title;
  final DateTime expiresAt;
  final String caption;
  final IconData icon;
  final VoidCallback onTap;
  final double? progress;
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({required this.item, required this.now});

  final _Deadline item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 236,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.md),
        border: Border.all(color: palette.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(FcbazRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TypeChip(type: item.type),
                    const Spacer(),
                    DeadlineChip(
                      expiresAt: item.expiresAt,
                      now: now,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (item.progress != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Row(
                  children: [
                    if (item.progress == null) ...[
                      Icon(item.icon, size: 13, color: palette.textMuted),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        item.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 16,
                      color: palette.textMuted,
                    ),
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontFamily: 'BarlowCondensed',
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
          letterSpacing: .8,
          color: palette.primary,
        ),
      ),
    );
  }
}

class _Mover {
  const _Mover({
    required this.playerId,
    required this.name,
    required this.rating,
    required this.price,
    required this.change,
  });

  final String playerId;
  final String name;
  final int rating;
  final int price;
  final double? change;

  static _Mover? fromJson(Map<String, dynamic> json) {
    final name = _stringValue(json, const [
      'name',
      'player_name',
      'title',
      'playerName',
    ]);
    final price = _asInt(
      json['price'] ??
          json['current'] ??
          json['current_price'] ??
          json['price_ps'] ??
          json['pricePs'],
    );
    if (name.isEmpty || price <= 0) return null;
    final change = _asDouble(
      json['change_percent'] ??
          json['change_24h_percent'] ??
          json['changePercent'] ??
          json['change'],
    );
    return _Mover(
      playerId: _stringValue(json, const ['player_id', 'playerId', 'id']),
      name: name,
      rating: _asInt(json['rating'] ?? json['overall']),
      price: price,
      change: change,
    );
  }
}

class _MoverRow extends StatelessWidget {
  const _MoverRow({required this.mover, required this.onTap});

  final _Mover mover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.md),
        border: Border.all(color: palette.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FcbazRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: palette.surfaceRaised,
                    borderRadius: BorderRadius.circular(FcbazRadius.sm),
                    border: Border.all(color: palette.line),
                  ),
                  child: Icon(
                    Icons.swap_vert_rounded,
                    size: 20,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mover.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mover.rating > 0
                            ? '${faDigits(mover.rating)} ریتینگ'
                            : 'حرکت تأییدشده',
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          compactCoinsFa(mover.price),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Coins',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    PriceDelta(percent: mover.change),
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

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 8),
        Expanded(child: second),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.kicker,
    required this.label,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  final String kicker;
  final String label;
  final IconData icon;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.md),
        border: Border.all(color: palette.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FcbazRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(FcbazRadius.sm),
                  ),
                  child: Icon(icon, size: 18, color: palette.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kicker,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontFamily: 'BarlowCondensed',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          height: 1.1,
                          letterSpacing: .8,
                          color: palette.primary,
                        ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (count != null)
                  Text(
                    faDigits(count!),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: palette.textMuted,
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

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.md),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              borderRadius: BorderRadius.circular(FcbazRadius.sm),
            ),
            child: Icon(icon, size: 19, color: palette.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: palette.textMuted,
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    child: Text(actionLabel!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailSkeleton extends StatelessWidget {
  const _RailSkeleton({
    required this.height,
    required this.itemWidth,
    required this.count,
  });

  final double height;
  final double itemWidth;
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => Container(
          width: itemWidth,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(FcbazRadius.md),
            border: Border.all(color: palette.line),
          ),
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          Container(
            height: 62,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(FcbazRadius.md),
              border: Border.all(color: palette.line),
            ),
          ),
          if (i != count - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

String _stringValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is Map) {
    for (final key in const [
      'ps',
      'console',
      'pc',
      'value',
      'amount',
      'current',
    ]) {
      if (value[key] != null) return _asInt(value[key]);
    }
    return 0;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
