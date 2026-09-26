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
    return Scaffold(
      appBar: AppBar(title: const Text('ارتقا بازیکنان')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('آزمایشگاه Evolution', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'شرایط واقعی، کارت‌های واجد شرایط و مقایسه قبل/بعد فقط با داده منبع',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 72),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: const Text('Evolutionها در دسترس نیستند'),
                  subtitle: Text(error!),
                  trailing: IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
                ),
              )
            else if (items.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.auto_awesome_rounded),
                  title: Text('Evolution فعالی پیدا نشد'),
                  subtitle: Text('این بخش فقط از داده واقعی FC27 استفاده می‌کند.'),
                ),
              )
            else
              for (final item in items) ...[
                _EvolutionCard(item: item),
                const SizedBox(height: 10),
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

      for (final item in club) {
        final result = eligibilityEngine.evaluate(item, widget.item);
        switch (result.status) {
          case EvoEligibilityStatus.eligible:
            ok.add(item);
          case EvoEligibilityStatus.needsReview:
            review.add(item);
          case EvoEligibilityStatus.ineligible:
            no.add(item);
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
    if (value == null) return 'زمان پایان نامشخص';
    final local = value.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
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
                'این مقایسه فقط از Upgradeهای عددی و ساختاریافته دریافت‌شده از منبع ساخته شده است.',
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
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${item.cost == 0 ? 'رایگان' : '${item.cost} Coins'} • ${_expiry(item)}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (item.description.isNotEmpty)
            Align(alignment: Alignment.centerRight, child: Text(item.description)),
          if (item.requirements.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerRight, child: Text('شرایط', style: TextStyle(fontWeight: FontWeight.w900))),
            const SizedBox(height: 6),
            for (final req in item.requirements)
              Align(alignment: Alignment.centerRight, child: Text('• $req')),
          ],
          if (item.steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerRight, child: Text('مسیر Evolution', style: TextStyle(fontWeight: FontWeight.w900))),
            const SizedBox(height: 8),
            for (var i = 0; i < item.steps.length; i++) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}. ${item.steps[i].title.isEmpty ? 'مرحله ${i + 1}' : item.steps[i].title}', style: const TextStyle(fontWeight: FontWeight.w900)),
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
              if (i != item.steps.length - 1) const SizedBox(height: 8),
            ],
          ],
          if (item.upgrades.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerRight, child: Text('ارتقاها', style: TextStyle(fontWeight: FontWeight.w900))),
            const SizedBox(height: 6),
            for (final upgrade in item.upgrades)
              Align(alignment: Alignment.centerRight, child: Text('• $upgrade')),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: loadingEligible ? null : _loadEligible,
              icon: loadingEligible
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.person_search_rounded),
              label: const Text('بررسی کارت‌های باشگاه من'),
            ),
          ),
          if (checkedClub) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('واجد شرایط: ${eligible.length}')),
                Chip(label: Text('نیاز به بررسی: ${needsReview.length}')),
                Chip(label: Text('نامعتبر: ${ineligible.length}')),
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
                  leading: Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary),
                  title: Text(player.playerName),
                  subtitle: Text('${player.rating} • ${player.position}'),
                  trailing: projection == null
                      ? null
                      : TextButton.icon(
                          onPressed: () => _showProjection(player),
                          icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                          label: const Text('قبل/بعد'),
                        ),
                );
              }),
          ],
          if (needsReview.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final player in needsReview.take(5))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.help_outline_rounded),
                title: Text(player.playerName),
                subtitle: const Text('حداقل یک شرط ساختاریافته قابل تشخیص نیست؛ تأیید قطعی انجام نمی‌شود.'),
              ),
          ],
          if (checkedClub && eligible.isEmpty && needsReview.isEmpty) ...[
            const SizedBox(height: 10),
            const Align(alignment: Alignment.centerRight, child: Text('کارت واجد شرایطی در باشگاه من پیدا نشد.')),
          ],
        ],
      ),
    );
  }
}
