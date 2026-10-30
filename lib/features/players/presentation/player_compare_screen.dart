import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/player.dart';
import '../domain/player_value_analysis.dart';
import '../../market/domain/purchase_value.dart';
import 'package:fcbaz/src/app_dependencies.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/ui/stat_radar.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';

class PlayerCompareScreen extends StatefulWidget {
  const PlayerCompareScreen({this.initialPlayers = const [], super.key});

  final List<Player> initialPlayers;

  @override
  State<PlayerCompareScreen> createState() => _PlayerCompareScreenState();
}

class _PlayerCompareScreenState extends State<PlayerCompareScreen> {
  final repository = AppDependencies.instance.players;
  final analyzer = const PlayerValueAnalyzer();
  final purchaseAnalyzer = const PurchaseValueAnalyzer();

  late List<Player> selected = widget.initialPlayers
      .take(4)
      .toList(growable: true);
  List<Player> allPlayers = const [];
  bool loading = false;
  bool loadingVersions = false;
  String? error;
  PlayerMarketPlatform platform = PlayerMarketPlatform.console;

  @override
  void initState() {
    super.initState();
    _hydrateInitialPlayers();
    _loadPlayers();
  }

  Future<void> _hydrateInitialPlayers() async {
    if (selected.isEmpty) return;
    final hydrated = <Player>[];
    for (final item in selected) {
      try {
        hydrated.add(await repository.getPlayer(item.id));
      } catch (_) {
        hydrated.add(item);
      }
    }
    if (!mounted) return;
    setState(() => selected = hydrated.take(4).toList(growable: true));
  }

  Future<void> _loadPlayers() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await repository.getPlayers();
      if (!mounted) return;
      setState(() => allPlayers = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addPlayer() async {
    if (selected.length >= 4 || allPlayers.isEmpty) return;
    final player = await showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ComparePicker(
        players: allPlayers
            .where((p) => !selected.any((s) => s.id == p.id))
            .toList(),
      ),
    );
    if (player == null) return;
    HapticFeedback.selectionClick();
    try {
      final full = await repository.getPlayer(player.id);
      if (!mounted) return;
      setState(() => selected.add(full));
    } catch (_) {
      if (!mounted) return;
      setState(() => selected.add(player));
    }
  }

  Future<void> _compareVersions() async {
    if (selected.isEmpty) return;
    setState(() => loadingVersions = true);
    try {
      final versions = await repository.getVersions(selected.first.id);
      if (!mounted) return;
      final unique = <String, Player>{};
      for (final item in [selected.first, ...versions]) {
        unique[item.id] = item;
      }
      final values = unique.values.toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
      setState(() => selected = values.take(4).toList(growable: true));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => loadingVersions = false);
    }
  }

  String _coins(int value) {
    if (value <= 0) return 'ناموجود';
    if (value >= 1000000) {
      final n = value / 1000000;
      return faDigits('${n.toStringAsFixed(n >= 10 ? 0 : 1)}M');
    }
    if (value >= 1000) {
      final n = value / 1000;
      return faDigits('${n.toStringAsFixed(n >= 100 ? 0 : 1)}K');
    }
    return faDigits(value);
  }

  @override
  Widget build(BuildContext context) {
    final analyses = selected
        .map((p) => analyzer.analyze(p, platform: platform))
        .toList(growable: false);
    final values = selected
        .map((p) => purchaseAnalyzer.analyze(p, platform: platform))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مقایسه بازیکنان'),
        actions: [
          IconButton(
            onPressed: selected.length < 4 && !loading ? _addPlayer : null,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'افزودن کارت',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          Text(
            'مقایسه حرفه‌ای کارت‌ها',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'آمار، PlayStyles، Roles و قیمت فقط از داده واقعی کارت‌ها خوانده می‌شود. شاخص ارزش، معیار محلی FCBaz برای مقایسه است.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SegmentedButton<PlayerMarketPlatform>(
                segments: const [
                  ButtonSegment(
                    value: PlayerMarketPlatform.console,
                    label: Text('کنسول'),
                  ),
                  ButtonSegment(
                    value: PlayerMarketPlatform.pc,
                    label: Text('رایانه (PC)'),
                  ),
                ],
                selected: {platform},
                onSelectionChanged: (value) =>
                    setState(() => platform = value.first),
              ),
              OutlinedButton.icon(
                onPressed: selected.isEmpty || loadingVersions
                    ? null
                    : _compareVersions,
                icon: loadingVersions
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.layers_rounded),
                label: const Text('نسخه‌های همین بازیکن'),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off_rounded),
                title: const Text('لیست کامل بازیکنان در دسترس نیست'),
                subtitle: Text(error!),
                trailing: TextButton(
                  onPressed: loading ? null : _loadPlayers,
                  child: const Text('تلاش دوباره'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (loading && selected.isEmpty)
            const _CompareSkeleton()
          else if (selected.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.compare_arrows_rounded, size: 44),
                    const SizedBox(height: 10),
                    const Text(
                      'بازیکنی برای مقایسه انتخاب نشده',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: loading ? null : _addPlayer,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('افزودن بازیکن'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 212,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selected.length + (selected.length < 4 ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  if (index == selected.length) {
                    return SizedBox(
                      width: 142,
                      child: Card(
                        child: InkWell(
                          onTap: loading ? null : _addPlayer,
                          borderRadius: BorderRadius.circular(22),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 36),
                              SizedBox(height: 8),
                              Text('افزودن'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final p = selected[index];
                  final analysis = analyses[index];
                  final image = p.cardImageUrl.isNotEmpty
                      ? p.cardImageUrl
                      : p.imageUrl;
                  return SizedBox(
                    width: 142,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 74,
                              child: image.isEmpty
                                  ? CircleAvatar(
                                      radius: 34,
                                      child: Text(faDigits(p.rating)),
                                    )
                                  : Image.network(
                                      image,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          CircleAvatar(
                                            radius: 34,
                                            child: Text(faDigits(p.rating)),
                                          ),
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text('${faDigits(p.rating)} • ${p.position}'),
                            Text(
                              p.version.isEmpty ? '—' : p.version,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${_coins(analysis.price)} سکه',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => selected.removeAt(index));
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _RadarSection(players: selected),
            const SizedBox(height: 14),
            _StatsCompareTable(players: selected),
            const SizedBox(height: 14),
            _ValueSection(analyses: analyses, values: values, coins: _coins),
            const SizedBox(height: 14),
            if (selected.any((p) => p.playStylesPlus.isNotEmpty))
              _TextCompareSection(
                title: 'PlayStyles+',
                players: selected,
                getter: (p) => p.playStylesPlus,
              ),
            if (selected.any((p) => p.playStyles.isNotEmpty))
              _TextCompareSection(
                title: 'PlayStyles',
                players: selected,
                getter: (p) => p.playStyles,
              ),
            if (selected.any((p) => p.roles.isNotEmpty))
              _TextCompareSection(
                title: 'نقش‌ها (Roles)',
                players: selected,
                getter: (p) => p.roles,
              ),
          ],
        ],
      ),
    );
  }
}

class _CompareSkeleton extends StatelessWidget {
  const _CompareSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: 'در حال بارگذاری کارت‌ها برای مقایسه',
      child: SizedBox(
        height: 212,
        child: Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        palette.surface,
                        palette.surfaceRaised,
                        palette.surface,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(FcbazRadius.lg),
                    border: Border.all(color: palette.line),
                  ),
                ),
              ),
              if (i == 0) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _RadarSection extends StatelessWidget {
  const _RadarSection({required this.players});

  final List<Player> players;

  static const labels = ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY'];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colors = [
      palette.primary,
      palette.secondary,
      palette.warning,
      palette.danger,
    ];
    final series = <StatRadarSeries>[
      for (var i = 0; i < players.length; i++)
        StatRadarSeries(
          label: players[i].name,
          color: colors[i % colors.length],
          values: [
            players[i].pace.toDouble(),
            players[i].shooting.toDouble(),
            players[i].passing.toDouble(),
            players[i].dribbling.toDouble(),
            players[i].defending.toDouble(),
            players[i].physical.toDouble(),
          ],
        ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'نمودار آمار شش‌گانه',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'محورها همان آمار چهره کارت روی مقیاس ۰ تا ۱۰۰ هستند.',
                style: TextStyle(color: palette.textMuted, fontSize: 11),
              ),
            ),
            const SizedBox(height: 10),
            StatRadarChart(labels: labels, series: series),
          ],
        ),
      ),
    );
  }
}

class _StatLine {
  const _StatLine(this.label, this.getter, {this.max = 99, this.suffix = ''});

  final String label;
  final int Function(Player player) getter;
  final int max;
  final String suffix;
}

class _StatsCompareTable extends StatelessWidget {
  const _StatsCompareTable({required this.players});

  final List<Player> players;

  static const _headerHeight = 44.0;
  static const _rowHeight = 58.0;
  static const _cellWidth = 92.0;
  static const _labelWidth = 62.0;

  static final _lines = <_StatLine>[
    _StatLine('ریتینگ', (p) => p.rating),
    _StatLine('سرعت', (p) => p.pace),
    _StatLine('شوت', (p) => p.shooting),
    _StatLine('پاس', (p) => p.passing),
    _StatLine('دریبل', (p) => p.dribbling),
    _StatLine('دفاع', (p) => p.defending),
    _StatLine('فیزیک', (p) => p.physical),
    _StatLine('مهارت', (p) => p.skillMoves, max: 5, suffix: '★'),
    _StatLine('پای ضعیف', (p) => p.weakFoot, max: 5, suffix: '★'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مقایسه آمار',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    players.length > 2
                        ? 'برنده هر ردیف با جام مشخص شده؛ جدول را افقی بکشید تا بقیه کارت‌ها را ببینید.'
                        : 'برنده هر ردیف با جام و رنگ اصلی مشخص شده است.',
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Column(
                    children: [
                      const SizedBox(height: _headerHeight),
                      for (final line in _lines)
                        SizedBox(
                          height: _rowHeight,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              line.label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: [
                        SizedBox(
                          height: _headerHeight,
                          child: Row(
                            children: [
                              for (final player in players)
                                SizedBox(
                                  width: _cellWidth,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          player.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        for (final line in _lines)
                          SizedBox(
                            height: _rowHeight,
                            child: Row(
                              children: [
                                for (final player in players)
                                  _StatCell(
                                    width: _cellWidth,
                                    value: line.getter(player),
                                    max: line.max,
                                    suffix: line.suffix,
                                    winner:
                                        line.getter(player) > 0 &&
                                        line.getter(player) ==
                                            players
                                                .map(line.getter)
                                                .reduce(
                                                  (a, b) => a > b ? a : b,
                                                ),
                                    semanticLabel:
                                        '${player.name}، ${line.label}',
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
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

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.width,
    required this.value,
    required this.max,
    required this.suffix,
    required this.winner,
    required this.semanticLabel,
  });

  final double width;
  final int value;
  final int max;
  final String suffix;
  final bool winner;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fraction = value <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    final color = value <= 0
        ? palette.textMuted
        : winner
        ? palette.primary
        : palette.text;
    return Semantics(
      label:
          '$semanticLabel، ${value <= 0 ? 'بدون داده' : faDigits(value)}'
          '${winner ? '، بیشترین مقدار' : ''}',
      excludeSemantics: true,
      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: winner ? palette.primary.withValues(alpha: .1) : null,
          borderRadius: BorderRadius.circular(10),
          border: winner
              ? Border.all(color: palette.primary.withValues(alpha: .28))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (winner) ...[
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 12,
                    color: palette.primary,
                  ),
                  const SizedBox(width: 2),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value <= 0 ? '—' : faDigits('$value$suffix'),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: winner ? 1 : .5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueSection extends StatelessWidget {
  const _ValueSection({
    required this.analyses,
    required this.values,
    required this.coins,
  });

  final List<PlayerValueAnalysis> analyses;
  final List<PurchaseValue> values;
  final String Function(int value) coins;

  String _perRating(double value) => formatCoinsFa(value.round());

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تحلیل قیمت و ارزش',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'سکه به‌ازای رنکینگ از قیمت واقعی پلتفرم تقسیم بر ریتینگ می‌آید. ردیف «با مالیات ۵٪» قیمت سربه‌سر فروش است تا پول خرید کامل برگردد. هیچ‌کدام پیش‌بینی بازار نیست.',
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 11,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < analyses.length; i++) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.surfaceRaised.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              analyses[i].player.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${coins(values[i].price)} سکه',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MiniStat(
                          icon: Icons.calculate_rounded,
                          label: values[i].coinsPerRating == null
                              ? 'سکه/رنکینگ: —'
                              : 'سکه/رنکینگ: ${_perRating(values[i].coinsPerRating!)}',
                        ),
                        _MiniStat(
                          icon: Icons.receipt_long_rounded,
                          label: values[i].taxAdjustedCoinsPerRating == null
                              ? 'با مالیات ۵٪: —'
                              : 'با مالیات ۵٪: ${_perRating(values[i].taxAdjustedCoinsPerRating!)}',
                        ),
                        _MiniStat(
                          icon: Icons.insights_rounded,
                          color: palette.primary,
                          label: analyses[i].valueIndex == null
                              ? 'شاخص FCBaz: —'
                              : 'شاخص FCBaz: ${faDigits(analyses[i].valueIndex!.toStringAsFixed(1))}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < analyses.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final resolved = color ?? palette.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: resolved.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: resolved),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: resolved,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextCompareSection extends StatelessWidget {
  const _TextCompareSection({
    required this.title,
    required this.players,
    required this.getter,
  });
  final String title;
  final List<Player> players;
  final List<String> Function(Player p) getter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            for (final player in players) ...[
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  player.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(getter(player).isEmpty ? '—' : getter(player).join(' • ')),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComparePicker extends StatefulWidget {
  const _ComparePicker({required this.players});
  final List<Player> players;

  @override
  State<_ComparePicker> createState() => _ComparePickerState();
}

class _ComparePickerState extends State<_ComparePicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final data = widget.players.where((p) {
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.clubName.toLowerCase().contains(q) ||
          p.position.toLowerCase().contains(q);
    }).toList()..sort((a, b) => b.rating.compareTo(a.rating));

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  hintText: 'جستجوی کارت...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final p = data[index];
                    return Card(
                      child: ListTile(
                        onTap: () => Navigator.pop(context, p),
                        leading: CircleAvatar(
                          backgroundImage: p.imageUrl.isEmpty
                              ? null
                              : NetworkImage(p.imageUrl),
                          child: p.imageUrl.isEmpty
                              ? Text(faDigits(p.rating))
                              : null,
                        ),
                        title: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(p.name),
                        ),
                        subtitle: Text(
                          '${faDigits(p.rating)} • ${p.position} • ${p.version}',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
