import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/live_fc27_catalog.dart';
import '../../src/app_dependencies.dart';
import '../../src/navigation/app_navigator.dart';
import '../../src/theme/fcbaz_theme.dart';
import '../../src/ui/deadline_chip.dart';
import '../../src/ui/section_header.dart';
import '../../src/utils/persian_formatters.dart';
import '../evolutions/data/evolution_repository.dart';
import '../evolutions/domain/evolution.dart';
import '../sbc/data/sbc_repository.dart';
import '../sbc/domain/sbc.dart';
import 'home_repository.dart';

/// Aggregates every live FC27 content type in one place and shows a real
/// countdown only for items whose source supplies an end date.
class ContentHubScreen extends StatefulWidget {
  const ContentHubScreen({
    this.sbcRepository,
    this.evolutionRepository,
    this.homeRepository,
    this.liveCatalog,
    this.now,
    super.key,
  });

  final SbcRepository? sbcRepository;
  final EvolutionRepository? evolutionRepository;
  final HomeRepository? homeRepository;
  final LiveFc27Catalog? liveCatalog;
  final DateTime Function()? now;

  @override
  State<ContentHubScreen> createState() => _ContentHubScreenState();
}

class _ContentHubScreenState extends State<ContentHubScreen> {
  late final sbcRepository =
      widget.sbcRepository ?? AppDependencies.instance.sbc;
  late final evolutionRepository =
      widget.evolutionRepository ?? AppDependencies.instance.evolutions;
  late final homeRepository =
      widget.homeRepository ?? AppDependencies.instance.home;
  late final liveCatalog = widget.liveCatalog ?? LiveFc27Catalog();

  List<SbcChallenge> sbcs = const [];
  List<Evolution> evolutions = const [];
  List<HomeObjective> objectives = const [];
  bool loading = true;
  String? sbcError;
  String? evolutionError;
  String? objectiveError;
  DateTime? sourceUpdatedAt;
  Timer? ticker;

  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _load();
    // Countdown chips read the clock on every build; a minute tick keeps them
    // truthful without any fake progress animation.
    ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!loading && mounted) setState(() => loading = true);
    await Future.wait([
      _loadSbcs(forceRefresh),
      _loadEvolutions(forceRefresh),
      _loadObjectives(forceRefresh),
      _loadSourceStamp(),
    ]);
    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadSbcs(bool forceRefresh) async {
    try {
      final items = await sbcRepository.getActive(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        sbcs = items;
        sbcError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => sbcError = e.toString());
    }
  }

  Future<void> _loadEvolutions(bool forceRefresh) async {
    try {
      final items = await evolutionRepository.getActive(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        evolutions = items;
        evolutionError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => evolutionError = e.toString());
    }
  }

  Future<void> _loadObjectives(bool forceRefresh) async {
    try {
      final items = await homeRepository.getObjectives(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        objectives = items;
        objectiveError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => objectiveError = e.toString());
    }
  }

  Future<void> _loadSourceStamp() async {
    try {
      final value = await liveCatalog.generatedAt();
      if (mounted) setState(() => sourceUpdatedAt = value);
    } catch (_) {
      // A missing source stamp must not hide content that loaded fine.
    }
  }

  int _deadlineOrder(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  List<SbcChallenge> get _sortedSbcs =>
      [...sbcs]..sort((a, b) => _deadlineOrder(a.expiresAt, b.expiresAt));

  List<Evolution> get _sortedEvolutions =>
      [...evolutions]..sort((a, b) => _deadlineOrder(a.expiresAt, b.expiresAt));

  List<HomeObjective> get _sortedObjectives =>
      [...objectives]..sort((a, b) => _deadlineOrder(a.expiresAt, b.expiresAt));

  List<_DeadlineEntry> _endingSoon() {
    final now = _now;
    final entries = <_DeadlineEntry>[
      for (final item in sbcs)
        if (item.expiresAt != null && item.expiresAt!.isAfter(now))
          _DeadlineEntry(
            kind: 'SBC',
            title: item.title,
            expiresAt: item.expiresAt!,
            open: () => AppNavigator.sbc(context),
          ),
      for (final item in evolutions)
        if (item.expiresAt != null && item.expiresAt!.isAfter(now))
          _DeadlineEntry(
            kind: 'Evolution',
            title: item.title,
            expiresAt: item.expiresAt!,
            open: () => AppNavigator.evolutions(context),
          ),
      for (final item in objectives)
        if (item.expiresAt != null && item.expiresAt!.isAfter(now))
          _DeadlineEntry(
            kind: 'Objective',
            title: item.title,
            expiresAt: item.expiresAt!,
            open: () => AppNavigator.objectives(context),
          ),
    ]..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    return entries.take(5).toList();
  }

  String _withDeadline(String base, DateTime? expiresAt) {
    if (expiresAt == null) {
      return base.isEmpty
          ? 'زمان پایان اعلام نشده'
          : '$base • زمان پایان اعلام نشده';
    }
    final line = 'پایان: ${formatJalaliDateTime(expiresAt)}';
    return base.isEmpty ? line : '$base • $line';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final endingSoon = _endingSoon();
    final anythingLoaded =
        sbcs.isNotEmpty || evolutions.isNotEmpty || objectives.isNotEmpty;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: const Text('مرکز محتوا'),
        actions: [
          IconButton(
            onPressed: loading ? null : () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'بروزرسانی محتوا',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: loading && !anythingLoaded
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 140),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _Hero(
                    nearest: endingSoon.isEmpty ? null : endingSoon.first,
                    now: _now,
                  ),
                  if (endingSoon.isNotEmpty) ...[
                    const SizedBox(height: FcbazSpace.xl),
                    const SectionHeader(
                      kicker: 'ENDING SOON',
                      title: 'پایان نزدیک',
                    ),
                    const SizedBox(height: 8),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < endingSoon.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _DeadlineRow(entry: endingSoon[i], now: _now),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: FcbazSpace.xl),
                  _ContentSection(
                    kicker: 'SBC',
                    title: 'SBCهای فعال (${faDigits(sbcs.length)})',
                    error: sbcError,
                    emptyText: 'SBC فعالی از منبع دریافت نشد.',
                    onRetry: () => _load(forceRefresh: true),
                    onOpenAll: () => AppNavigator.sbc(context),
                    rows: [
                      for (final item in _sortedSbcs.take(6))
                        _ContentRow(
                          icon: Icons.extension_rounded,
                          title: item.title,
                          subtitle: _withDeadline(
                            item.reward.isNotEmpty
                                ? 'پاداش: ${item.reward}'
                                : '',
                            item.expiresAt,
                          ),
                          expiresAt: item.expiresAt,
                          now: _now,
                          onTap: () => AppNavigator.sbc(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: FcbazSpace.xl),
                  _ContentSection(
                    kicker: 'EVOLUTIONS',
                    title: 'Evolutionهای فعال (${faDigits(evolutions.length)})',
                    error: evolutionError,
                    emptyText: 'Evolution فعالی از منبع دریافت نشد.',
                    onRetry: () => _load(forceRefresh: true),
                    onOpenAll: () => AppNavigator.evolutions(context),
                    rows: [
                      for (final item in _sortedEvolutions.take(6))
                        _ContentRow(
                          icon: Icons.auto_awesome_rounded,
                          title: item.title,
                          subtitle: _withDeadline(
                            item.cost > 0
                                ? 'هزینه: ${formatCoinsFa(item.cost)} سکه'
                                : '',
                            item.expiresAt,
                          ),
                          expiresAt: item.expiresAt,
                          now: _now,
                          onTap: () => AppNavigator.evolutions(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: FcbazSpace.xl),
                  _ContentSection(
                    kicker: 'OBJECTIVES',
                    title: 'Objectiveهای فعال (${faDigits(objectives.length)})',
                    error: objectiveError,
                    emptyText: 'Objective فعالی از منبع دریافت نشد.',
                    onRetry: () => _load(forceRefresh: true),
                    onOpenAll: () => AppNavigator.objectives(context),
                    rows: [
                      for (final item in _sortedObjectives.take(6))
                        _ContentRow(
                          icon: Icons.flag_rounded,
                          title: item.title,
                          subtitle: _withDeadline(
                            item.taskCount > 0
                                ? '${faDigits(item.taskCount)} تسک'
                                : '',
                            item.expiresAt,
                          ),
                          expiresAt: item.expiresAt,
                          now: _now,
                          onTap: () => AppNavigator.objectives(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: FcbazSpace.xl),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: .07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: palette.primary.withValues(alpha: .18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          color: palette.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'شمارش معکوس فقط برای محتوایی نمایش داده می‌شود که منبع، زمان پایان واقعی داشته باشد؛ '
                            'FCBaz برای بقیه زمان ساختگی نمی‌سازد.'
                            '${sourceUpdatedAt == null ? '' : ' آخرین به‌روزرسانی منبع: ${relativeTimeFa(sourceUpdatedAt!, now: _now)}.'}',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.6,
                              color: palette.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DeadlineEntry {
  const _DeadlineEntry({
    required this.kind,
    required this.title,
    required this.expiresAt,
    required this.open,
  });

  final String kind;
  final String title;
  final DateTime expiresAt;
  final VoidCallback open;
}

class _Hero extends StatelessWidget {
  const _Hero({required this.nearest, required this.now});

  final _DeadlineEntry? nearest;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final entry = nearest;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            palette.primary.withValues(alpha: .18),
            palette.surfaceRaised,
            palette.surface,
          ],
        ),
        border: Border.all(color: palette.primary.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT DEADLINE',
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
          const SizedBox(height: 6),
          if (entry == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هیچ زمان پایانی در داده فعلی ثبت نشده است.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'به‌محض رسیدن زمان پایان واقعی از منبع، شمارش معکوس همین‌جا نمایش داده می‌شود.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.6,
                    color: palette.textMuted,
                  ),
                ),
              ],
            )
          else ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    entry.kind,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: palette.primary,
                    ),
                  ),
                ),
                Text(
                  relativeDeadlineFa(entry.expiresAt, now: now),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: palette.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              entry.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              formatJalaliDateTime(entry.expiresAt),
              style: TextStyle(fontSize: 11, color: palette.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({required this.entry, required this.now});

  final _DeadlineEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      onTap: entry.open,
      dense: true,
      leading: Icon(Icons.timer_outlined, color: palette.warning),
      title: Text(
        entry.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
      ),
      subtitle: Text(
        entry.kind,
        textDirection: TextDirection.ltr,
        style: TextStyle(fontSize: 10.5, color: palette.textMuted),
      ),
      trailing: DeadlineChip(
        expiresAt: entry.expiresAt,
        now: now,
        compact: true,
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({
    required this.kicker,
    required this.title,
    required this.error,
    required this.emptyText,
    required this.onRetry,
    required this.onOpenAll,
    required this.rows,
  });

  final String kicker;
  final String title;
  final String? error;
  final String emptyText;
  final VoidCallback onRetry;
  final VoidCallback onOpenAll;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          kicker: kicker,
          title: title,
          actionLabel: 'همه',
          onAction: onOpenAll,
        ),
        const SizedBox(height: 8),
        if (error != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    color: palette.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'دریافت این بخش ممکن نشد.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: palette.textMuted,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('تلاش دوباره'),
                  ),
                ],
              ),
            ),
          )
        else if (rows.isEmpty)
          Text(
            emptyText,
            style: TextStyle(fontSize: 11.5, color: palette.textMuted),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  rows[i],
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ContentRow extends StatelessWidget {
  const _ContentRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expiresAt,
    required this.now,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime? expiresAt;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: palette.primary, size: 20),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10.5, height: 1.5, color: palette.textMuted),
      ),
      trailing: DeadlineChip(expiresAt: expiresAt, now: now, compact: true),
    );
  }
}
