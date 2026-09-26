import 'package:flutter/material.dart';

import '../../club/data/my_club_repository.dart';
import '../data/evolution_repository.dart';
import '../domain/evolution.dart';
import '../domain/evolution_eligibility_engine.dart';
import '../domain/evolution_projection.dart';

class EvolutionsScreen extends StatefulWidget {
  const EvolutionsScreen({super.key});

  @override
  State<EvolutionsScreen> createState() => _EvolutionsScreenState();
}

class _EvolutionsScreenState extends State<EvolutionsScreen> {
  final repository = EvolutionRepository();
  bool loading = true;
  String? error;
  List<Evolution> items = const [];

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
      final data = await repository.getActive();
      if (!mounted) return;
      setState(() => items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('EVOLUTIONS')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.secondary.withValues(alpha: .28)),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    scheme.secondary.withValues(alpha: .12),
                    scheme.surface,
                    scheme.primary.withValues(alpha: .05),
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
                          color: scheme.secondary,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          'FC27 • LIVE LAB',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: Color(0xFF071014),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        loading ? 'SYNCING…' : '${items.length} ACTIVE',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'EVOLUTION\nLAB',
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          height: .94,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.1,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'شرایط واقعی، مسیر ارتقا و بررسی کارت‌های باشگاه فقط از داده FC27 معتبر.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 72),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              _StateCard(
                icon: Icons.cloud_off_rounded,
                title: 'Evolutionها در دسترس نیستند',
                subtitle: error!,
                onTap: _load,
              )
            else if (items.isEmpty)
              const _StateCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Evolution فعالی پیدا نشد',
                subtitle: 'داده نمونه نمایش داده نمی‌شود؛ فقط دیتای واقعی FC27.',
              )
            else
              for (final item in items) ...[
                _EvolutionCard(item: item),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _EvolutionCard extends StatefulWidget {
  const _EvolutionCard({required this.item});
  final Evolution item;

  @override
  State<_EvolutionCard> createState() => _EvolutionCardState();
}

class _EvolutionCardState extends State<_EvolutionCard> {
  final clubRepository = MyClubRepository();
  final eligibilityEngine = const EvolutionEligibilityEngine();
  final projectionEngine = const EvolutionProjectionEngine();

  bool loadingEligible = false;
  bool checkedClub = false;
  List<MyClubItem> eligible = const [];
  List<MyClubItem> needsReview = const [];
  List<MyClubItem> ineligible = const [];

  Future<void> _loadEligible() async {
    setState(() => loadingEligible = true);
    try {
      final club = await clubRepository.getAll();
      final ok = <MyClubItem>[];
      final review = <MyClubItem>[];
      final no = <MyClubItem>[];
      for (final player in club) {
        final result = eligibilityEngine.evaluate(player, widget.item);
        switch (result.status) {
          case EvoEligibilityStatus.eligible:
            ok.add(player);
          case EvoEligibilityStatus.needsReview:
            review.add(player);
          case EvoEligibilityStatus.ineligible:
            no.add(player);
        }
      }
      int byRating(MyClubItem a, MyClubItem b) => b.rating.compareTo(a.rating);
      ok.sort(byRating);
      review.sort(byRating);
      no.sort(byRating);
      if (!mounted) return;
      setState(() {
        eligible = ok;
        needsReview = review;
        ineligible = no;
        checkedClub = true;
      });
    } finally {
      if (mounted) setState(() => loadingEligible = false);
    }
  }

  String _expiry(Evolution item) {
    final value = item.expiresAt;
    if (value == null) return '—';
    final local = value.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }

  String _cost(int value) {
    if (value <= 0) return 'FREE';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return '$value';
  }

  void _showProjection(MyClubItem player) {
    final projection = projectionEngine.project(player, widget.item);
    if (projection == null) return;
    const labels = <String, String>{
      'rating': 'ریتینگ',
      'pace': 'سرعت',
      'shooting': 'شوت',
      'passing': 'پاس',
      'dribbling': 'دریبل',
      'defending': 'دفاع',
      'physical': 'فیزیک',
      'skill_moves': 'مهارت',
      'weak_foot': 'پای ضعیف',
    };
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(player.playerName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(widget.item.title, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 16),
              for (final key in projection.before.keys)
                if ((projection.changes[key] ?? 0) != 0)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(labels[key] ?? key),
                    subtitle: Text('${projection.before[key]}  ←  ${projection.after[key]}'),
                    trailing: Chip(label: Text('+${projection.changes[key]}')),
                  ),
              const SizedBox(height: 8),
              Text(
                'این مقایسه فقط از Upgradeهای عددی و ساختاریافته منبع ساخته شده است.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(13, 0, 13, 14),
        leading: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.secondary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: scheme.secondary.withValues(alpha: .25)),
          ),
          child: Icon(Icons.auto_awesome_rounded, color: scheme.secondary),
        ),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _Tag(label: 'COST', value: _cost(item.cost)),
              const SizedBox(width: 6),
              _Tag(label: 'EXPIRES', value: _expiry(item)),
            ],
          ),
        ),
        children: [
          if (item.description.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Text(item.description, style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
          if (item.requirements.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SectionLabel('REQUIREMENTS'),
            const SizedBox(height: 7),
            for (final req in item.requirements) _Line(icon: Icons.check_rounded, text: req),
          ],
          if (item.steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SectionLabel('EVOLUTION PATH'),
            const SizedBox(height: 7),
            for (var i = 0; i < item.steps.length; i++) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: .66),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outline.withValues(alpha: .55)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${item.steps[i].title.isEmpty ? 'مرحله ${i + 1}' : item.steps[i].title}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (item.steps[i].requirements.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final req in item.steps[i].requirements) Text('• $req'),
                    ],
                    if (item.steps[i].upgrades.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final up in item.steps[i].upgrades) Text('+ $up'),
                    ],
                  ],
                ),
              ),
              if (i != item.steps.length - 1) const SizedBox(height: 7),
            ],
          ],
          if (item.upgrades.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SectionLabel('UPGRADES'),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final upgrade in item.upgrades) Chip(label: Text(upgrade))],
            ),
          ],
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: loadingEligible ? null : _loadEligible,
              icon: loadingEligible
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.inventory_2_outlined),
              label: const Text('CHECK MY CLUB'),
            ),
          ),
          if (checkedClub) ...[
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(child: _Count(label: 'ELIGIBLE', value: eligible.length, color: scheme.primary)),
                const SizedBox(width: 6),
                Expanded(child: _Count(label: 'REVIEW', value: needsReview.length, color: scheme.secondary)),
                const SizedBox(width: 6),
                Expanded(child: _Count(label: 'NO', value: ineligible.length, color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
          if (eligible.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final player in eligible.take(10))
              Builder(builder: (context) {
                final projection = projectionEngine.project(player, item);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(Icons.check_circle_rounded, color: scheme.primary),
                  title: Text(player.playerName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${player.rating} • ${player.position}'),
                  trailing: projection == null
                      ? null
                      : TextButton(
                          onPressed: () => _showProjection(player),
                          child: const Text('BEFORE / AFTER'),
                        ),
                );
              }),
          ],
          if (needsReview.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final player in needsReview.take(5))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.help_outline_rounded),
                title: Text(player.playerName),
                subtitle: const Text('حداقل یک شرط ساختاریافته قابل تشخیص نیست.'),
              ),
          ],
          if (checkedClub && eligible.isEmpty && needsReview.isEmpty) ...[
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('کارت واجد شرایطی در باشگاه من پیدا نشد.'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .68),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$label  $value',
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
      );
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 7),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _Count extends StatelessWidget {
  const _Count({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .18)),
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
            Text(label, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center),
              if (onTap != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onTap, child: const Text('تلاش دوباره')),
              ],
            ],
          ),
        ),
      );
}
