import 'package:flutter/material.dart';

import '../../market/presentation/player_market_panel.dart';
import '../data/player_repository.dart';
import '../data/player_review_repository.dart';
import '../domain/chemistry_style_advisor.dart';
import '../domain/player.dart';
import 'player_compare_screen.dart';
import 'player_portrait.dart';

class PlayerDetailsScreen extends StatefulWidget {
  const PlayerDetailsScreen({
    required this.player,
    super.key,
  });

  final Player player;

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  final repository = PlayerRepository();
  final reviewRepository = PlayerReviewRepository();
  final chemistryAdvisor = const ChemistryStyleAdvisor();

  late Player player = widget.player;
  PlayerReview? review;
  List<Player> versions = const [];
  bool loading = true;
  String? detailError;

  @override
  void initState() {
    super.initState();
    _loadFullDetails();
    _loadReview();
  }

  Future<void> _loadReview() async {
    final data = await reviewRepository.get(widget.player.id);
    if (!mounted) return;
    setState(() => review = data);
  }

  Future<void> _editReview() async {
    var rating = review?.rating ?? 5;
    final controller = TextEditingController(text: review?.text ?? '');

    final result = await showDialog<(int, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('نظر من درباره ' + player.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setDialogState(() => rating = i),
                      icon: Icon(
                        i <= rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'یادداشت یا Review شخصی',
                ),
              ),
            ],
          ),
          actions: [
            if (review != null)
              TextButton(
                onPressed: () => Navigator.pop(context, (0, '')),
                child: const Text('حذف'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                (rating, controller.text.trim()),
              ),
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (result == null) return;

    if (result.$1 == 0) {
      await reviewRepository.remove(player.id);
    } else {
      await reviewRepository.save(
        playerId: player.id,
        rating: result.$1,
        text: result.$2,
      );
    }

    await _loadReview();
  }

  Future<void> _loadFullDetails() async {
    setState(() {
      loading = true;
      detailError = null;
    });

    try {
      final results = await Future.wait([
        repository.getPlayer(widget.player.id),
        repository.getVersions(widget.player.id),
      ]);

      if (!mounted) return;

      setState(() {
        player = results[0] as Player;
        versions = (results[1] as List<Player>)
            .where((p) => p.id != player.id)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => detailError = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _openCompare() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerCompareScreen(
          initialPlayers: [player],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final faceStats = [
      ('PAC', player.pace),
      ('SHO', player.shooting),
      ('PAS', player.passing),
      ('DRI', player.dribbling),
      ('DEF', player.defending),
      ('PHY', player.physical),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات بازیکن'),
        actions: [
          IconButton(
            onPressed: _openCompare,
            icon: const Icon(Icons.compare_arrows_rounded),
            tooltip: 'مقایسه',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFullDetails,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _PlayerHero(player: player),
            if (loading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 2),
            ],
            if (detailError != null) ...[
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: const Text('جزئیات کامل در دسترس نیست'),
                  subtitle: Text(detailError!),
                  trailing: IconButton(
                    onPressed: _loadFullDetails,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _SectionHeader(
              title: 'Face Stats',
              trailing: TextButton.icon(
                onPressed: _openCompare,
                icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                label: const Text('مقایسه'),
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faceStats.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (_, i) {
                final stat = faceStats[i];
                return _StatTile(
                  label: stat.$1,
                  value: stat.$2,
                );
              },
            ),
            const SizedBox(height: 14),
            _IdentityCard(player: player),
            if (player.playStylesPlus.isNotEmpty ||
                player.playStyles.isNotEmpty) ...[
              const SizedBox(height: 18),
              const _SectionHeader(title: 'PlayStyles'),
              const SizedBox(height: 10),
              _PlayStylesSection(player: player),
            ],
            if (player.roles.isNotEmpty) ...[
              const SizedBox(height: 18),
              const _SectionHeader(title: 'Roles'),
              const SizedBox(height: 10),
              _ChipSection(
                items: player.roles,
                icon: Icons.schema_rounded,
              ),
            ],
            if (player.inGameStats.isNotEmpty) ...[
              const SizedBox(height: 18),
              const _SectionHeader(title: 'In‑Game Stats'),
              const SizedBox(height: 10),
              _InGameStats(stats: player.inGameStats),
            ],
            const SizedBox(height: 18),
            const _SectionHeader(title: 'Chemistry Style Advisor'),
            const SizedBox(height: 10),
            _ChemistryStyleSection(
              suggestions: chemistryAdvisor.suggest(player),
            ),
            const SizedBox(height: 18),
            _SectionHeader(
              title: 'امتیاز و Review من',
              trailing: TextButton.icon(
                onPressed: _editReview,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(review == null ? 'ثبت نظر' : 'ویرایش'),
              ),
            ),
            const SizedBox(height: 10),
            _ReviewCard(review: review),
            if (versions.isNotEmpty) ...[
              const SizedBox(height: 18),
              const _SectionHeader(title: 'نسخه‌های دیگر'),
              const SizedBox(height: 10),
              _VersionsStrip(
                versions: versions,
                onOpen: (version) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PlayerDetailsScreen(player: version),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 18),
            PlayerMarketPanel(
              playerId: player.id,
              playerName: player.name,
              seedPricePs: player.pricePs,
              seedPricePc: player.pricePc,
            ),
          ],
        ),
      ),
    );
  }
}


class _ChemistryStyleSection extends StatelessWidget {
  const _ChemistryStyleSection({required this.suggestions});

  final List<ChemistryStyleSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'پیشنهاد تحلیلی FCBaz بر اساس Position و Stat واقعی کارت',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < suggestions.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    child: Text((i + 1).toString()),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestions[i].name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(suggestions[i].reason),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 5,
                          children: [
                            for (final stat in suggestions[i].focus)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(stat),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (i != suggestions.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 9),
                  child: Divider(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final PlayerReview? review;

  @override
  Widget build(BuildContext context) {
    if (review == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.rate_review_outlined),
          title: Text('هنوز نظری ثبت نکرده‌ای'),
          subtitle: Text('این امتیاز شخصی است و فقط روی دستگاه خودت ذخیره می‌شود.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= review!.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 22,
                  ),
                const Spacer(),
                Text(
                  review!.rating.toString() + '/5',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            if (review!.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(review!.text),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerHero extends StatelessWidget {
  const _PlayerHero({required this.player});
  final Player player;

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
            scheme.secondary.withValues(alpha: .08),
            scheme.surface,
          ],
        ),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PlayerPortrait(
            player: player,
            width: 118,
            height: 150,
            borderRadius: 20,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.rating.toString(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  player.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  player.position +
                      (player.version.isEmpty ? '' : ' • ' + player.version),
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    player.clubName,
                    player.leagueName,
                    player.nationName,
                  ].where((e) => e.isNotEmpty).join(' • '),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Skill Moves', player.skillMoves > 0 ? player.skillMoves.toString() + '★' : '—'),
      ('Weak Foot', player.weakFoot > 0 ? player.weakFoot.toString() + '★' : '—'),
      if (player.foot.isNotEmpty) ('پا', player.foot),
      if (player.height.isNotEmpty) ('قد', player.height),
      if (player.workRates.isNotEmpty) ('Work Rates', player.workRates),
      if (player.positions.isNotEmpty)
        ('پست‌های جایگزین', player.positions.join('، ')),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].$2,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              if (i != rows.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayStylesSection extends StatelessWidget {
  const _PlayStylesSection({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (player.playStylesPlus.isNotEmpty) ...[
              Text(
                'PlayStyles+',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final item in player.playStylesPlus)
                    Chip(
                      avatar: const Icon(Icons.add_circle_rounded, size: 16),
                      label: Text(item),
                    ),
                ],
              ),
            ],
            if (player.playStyles.isNotEmpty) ...[
              if (player.playStylesPlus.isNotEmpty)
                const SizedBox(height: 14),
              const Text(
                'PlayStyles',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final item in player.playStyles)
                    Chip(
                      avatar: const Icon(Icons.flash_on_rounded, size: 16),
                      label: Text(item),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.items,
    required this.icon,
  });

  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              Chip(
                avatar: Icon(icon, size: 16),
                label: Text(item),
              ),
          ],
        ),
      ),
    );
  }
}

class _InGameStats extends StatelessWidget {
  const _InGameStats({required this.stats});
  final Map<String, int> stats;

  @override
  Widget build(BuildContext context) {
    final entries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              _DetailedStatRow(
                label: _pretty(entries[i].key),
                value: entries[i].value,
              ),
              if (i != entries.length - 1)
                const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  static String _pretty(String value) {
    return value
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => m.group(1)! + ' ' + m.group(2)!,
        );
  }
}

class _DetailedStatRow extends StatelessWidget {
  const _DetailedStatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final progress = (value.clamp(0, 99)) / 99;

    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 30,
          child: Text(
            value.toString(),
            textAlign: TextAlign.left,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _VersionsStrip extends StatelessWidget {
  const _VersionsStrip({
    required this.versions,
    required this.onOpen,
  });

  final List<Player> versions;
  final ValueChanged<Player> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: versions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final p = versions[index];
          return SizedBox(
            width: 132,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onOpen(p),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 31,
                        backgroundImage: p.imageUrl.isEmpty
                            ? null
                            : NetworkImage(p.imageUrl),
                        child: p.imageUrl.isEmpty
                            ? Text(p.rating.toString())
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.rating.toString() + ' • ' + p.position,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p.version.isEmpty ? 'نسخه دیگر' : p.version,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(label),
        ],
      ),
    );
  }
}
