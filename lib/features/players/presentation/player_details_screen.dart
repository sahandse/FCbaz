import 'package:flutter/material.dart';

import '../../market/presentation/player_market_panel.dart';
import '../data/player_repository.dart';
import '../data/player_review_repository.dart';
import '../domain/chemistry_style_advisor.dart';
import '../domain/player.dart';
import 'player_compare_screen.dart';
import 'player_item_visual.dart';

class PlayerDetailsScreen extends StatefulWidget {
  const PlayerDetailsScreen({required this.player, super.key});
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
    _load();
    _loadReview();
  }

  Future<void> _loadReview() async {
    final data = await reviewRepository.get(widget.player.id);
    if (mounted) setState(() => review = data);
  }

  Future<void> _load() async {
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
      final loaded = results[0] as Player;
      setState(() {
        player = loaded;
        versions = (results[1] as List<Player>).where((p) => p.id != loaded.id).toList();
      });
    } catch (e) {
      if (mounted) setState(() => detailError = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _compare() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerCompareScreen(initialPlayers: [player]),
    ));
  }

  Future<void> _editReview() async {
    var rating = review?.rating ?? 5;
    final controller = TextEditingController(text: review?.text ?? '');
    final result = await showDialog<(int, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(player.name),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setDialogState(() => rating = i),
                    icon: Icon(i <= rating ? Icons.star_rounded : Icons.star_border_rounded),
                  ),
              ],
            ),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'یادداشت شخصی'),
            ),
          ]),
          actions: [
            if (review != null)
              TextButton(onPressed: () => Navigator.pop(context, (0, '')), child: const Text('حذف')),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(context, (rating, controller.text.trim())), child: const Text('ذخیره')),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result == null) return;
    if (result.$1 == 0) {
      await reviewRepository.remove(player.id);
    } else {
      await reviewRepository.save(playerId: player.id, rating: result.$1, text: result.$2);
    }
    await _loadReview();
  }

  String _value(String value) => value.trim().isEmpty ? '—' : value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = <(String, int)>[
      ('PAC', player.pace),
      ('SHO', player.shooting),
      ('PAS', player.passing),
      ('DRI', player.dribbling),
      ('DEF', player.defending),
      ('PHY', player.physical),
    ];
    final chem = chemistryAdvisor.suggest(player);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PLAYER ITEM'),
        actions: [
          IconButton(onPressed: _compare, icon: const Icon(Icons.compare_arrows_rounded), tooltip: 'مقایسه'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary.withValues(alpha: .28)),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [scheme.primary.withValues(alpha: .10), scheme.surface, scheme.secondary.withValues(alpha: .04)],
                ),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 176, child: PlayerItemVisual(player: player, showPrices: true)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(7)),
                      child: const Text('FC27 ITEM', textDirection: TextDirection.ltr, style: TextStyle(color: Color(0xFF10140C), fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 10),
                    Text(player.name, textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 5),
                    Text('${player.rating} • ${_value(player.position)}', textDirection: TextDirection.ltr, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text([player.clubName, player.leagueName, player.nationName].where((e) => e.isNotEmpty).join(' • '), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(onPressed: _compare, icon: const Icon(Icons.compare_arrows_rounded, size: 17), label: const Text('مقایسه')),
                  ]),
                ),
              ]),
            ),
            if (loading) ...[const SizedBox(height: 8), const LinearProgressIndicator(minHeight: 2)],
            if (detailError != null) ...[
              const SizedBox(height: 8),
              _InfoCard(icon: Icons.cloud_off_rounded, title: 'جزئیات کامل در دسترس نیست', subtitle: detailError!),
            ],
            const SizedBox(height: 18),
            const _SectionLabel('FACE STATS'),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 7, crossAxisSpacing: 7, childAspectRatio: 1.45),
              itemBuilder: (_, i) => _StatTile(label: stats[i].$1, value: stats[i].$2),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('ITEM INFO'),
            const SizedBox(height: 8),
            _InfoGrid(player: player),
            if (player.playStylesPlus.isNotEmpty || player.playStyles.isNotEmpty) ...[
              const SizedBox(height: 16),
              const _SectionLabel('PLAYSTYLES'),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final item in player.playStylesPlus) Chip(avatar: const Icon(Icons.stars_rounded, size: 15), label: Text('$item +')),
                for (final item in player.playStyles) Chip(label: Text(item)),
              ]),
            ],
            if (player.roles.isNotEmpty) ...[
              const SizedBox(height: 16),
              const _SectionLabel('ROLES'),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final role in player.roles) Chip(label: Text(role))]),
            ],
            if (chem.isNotEmpty) ...[
              const SizedBox(height: 16),
              const _SectionLabel('CHEMISTRY STYLE'),
              const SizedBox(height: 8),
              for (var i = 0; i < chem.length && i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: _InfoCard(icon: Icons.bolt_rounded, title: chem[i].name, subtitle: chem[i].reason),
                ),
            ],
            const SizedBox(height: 16),
            Row(children: [
              const Expanded(child: _SectionLabel('MY REVIEW')),
              TextButton.icon(onPressed: _editReview, icon: const Icon(Icons.edit_note_rounded, size: 18), label: Text(review == null ? 'ثبت نظر' : 'ویرایش')),
            ]),
            _ReviewCard(review: review),
            if (versions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const _SectionLabel('OTHER VERSIONS'),
              const SizedBox(height: 8),
              SizedBox(
                height: 230,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: versions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: versions[i]))),
                    child: SizedBox(width: 145, child: PlayerItemVisual(player: versions[i], compact: true, showPrices: true)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const _SectionLabel('MARKET'),
            const SizedBox(height: 8),
            PlayerMarketPanel(playerId: player.id, playerName: player.name),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, textDirection: TextDirection.ltr, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: .7));
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: scheme.outline.withValues(alpha: .65))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value > 0 ? '$value' : '—', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900, fontSize: 19)),
        Text(label, textDirection: TextDirection.ltr, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 8, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.player});
  final Player player;
  @override
  Widget build(BuildContext context) {
    final data = <(String, String)>[
      ('CLUB', player.clubName),
      ('LEAGUE', player.leagueName),
      ('NATION', player.nationName),
      ('VERSION', player.version.isNotEmpty ? player.version : player.rarity),
      ('SKILLS', player.skillMoves > 0 ? '${player.skillMoves}★' : '—'),
      ('WEAK FOOT', player.weakFoot > 0 ? '${player.weakFoot}★' : '—'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      childAspectRatio: 2.2,
      children: [for (final item in data) _MiniInfo(label: item.$1, value: item.$2.isEmpty ? '—' : item.$2)],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: .58), borderRadius: BorderRadius.circular(9), border: Border.all(color: scheme.outline.withValues(alpha: .55))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, textDirection: TextDirection.ltr, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 8, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: scheme.outline.withValues(alpha: .6))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
        ])),
      ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final PlayerReview? review;
  @override
  Widget build(BuildContext context) {
    if (review == null) {
      return const _InfoCard(icon: Icons.rate_review_outlined, title: 'هنوز نظری ثبت نشده', subtitle: 'نظر شخصی فقط روی دستگاه ذخیره می‌شود.');
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: scheme.outline.withValues(alpha: .6))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [for (var i = 1; i <= 5; i++) Icon(i <= review!.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 19, color: scheme.primary)]),
        if (review!.text.isNotEmpty) ...[const SizedBox(height: 8), Text(review!.text)],
      ]),
    );
  }
}
