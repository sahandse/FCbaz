import 'package:flutter/material.dart';

import '../../club/data/my_club_repository.dart';
import '../data/sbc_repository.dart';
import '../domain/sbc.dart';
import 'sbc_tools_screen.dart';

class SbcScreen extends StatefulWidget {
  const SbcScreen({super.key});

  @override
  State<SbcScreen> createState() => _SbcScreenState();
}

class _SbcScreenState extends State<SbcScreen> {
  final repository = SbcRepository();
  bool loading = true;
  String? error;
  List<SbcChallenge> items = const [];

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

  void _openTools() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SbcToolsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SBC HUB'),
        actions: [
          IconButton(
            onPressed: _openTools,
            tooltip: 'ابزارهای SBC',
            icon: const Icon(Icons.calculate_rounded),
          ),
        ],
      ),
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
                border: Border.all(color: scheme.primary.withValues(alpha: .28)),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    scheme.primary.withValues(alpha: .12),
                    scheme.surface,
                    scheme.secondary.withValues(alpha: .04),
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
                          'FC27 • LIVE',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: Color(0xFF10140C),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        loading ? 'SYNCING…' : '${items.length} CHALLENGES',
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
                    'SQUAD BUILDING\nCHALLENGES',
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: .95,
                          letterSpacing: -1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'فقط چالش، هزینه، پاداش و Requirementهایی که منبع واقعی FC27 برگرداند نمایش داده می‌شوند.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openTools,
                      icon: const Icon(Icons.calculate_outlined, size: 18),
                      label: const Text('ابزارهای Rating و Cheapest'),
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
                title: 'SBC در دسترس نیست',
                subtitle: error!,
                action: _load,
              )
            else if (items.isEmpty)
              const _StateCard(
                icon: Icons.extension_off_rounded,
                title: 'SBC فعالی پیدا نشد',
                subtitle: 'داده نمونه نمایش داده نمی‌شود. با در دسترس شدن منبع واقعی، چالش‌ها اینجا ظاهر می‌شوند.',
              )
            else
              for (final item in items) ...[
                _SbcCard(item: item),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _SbcCard extends StatelessWidget {
  const _SbcCard({required this.item});
  final SbcChallenge item;

  String _cost(int? value) {
    if (value == null || value <= 0) return '—';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SbcDetailScreen(sbc: item)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outline.withValues(alpha: .7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: scheme.primary.withValues(alpha: .25)),
                    ),
                    child: Icon(Icons.extension_rounded, color: scheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        if (item.category.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.category.toUpperCase(),
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (item.repeatable)
                    const Chip(label: Text('REPEATABLE', textDirection: TextDirection.ltr)),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'COST',
                      value: '${_cost(item.estimatedCost)} C',
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _MiniStat(
                      label: 'REWARD',
                      value: item.reward.isEmpty ? '—' : item.reward,
                    ),
                  ),
                ],
              ),
              if (item.itemScore != null) ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(Icons.stars_rounded, color: scheme.primary, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      'ITEM SCORE ${item.itemScore}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_back_rounded, color: scheme.onSurfaceVariant, size: 18),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SbcDetailScreen extends StatefulWidget {
  const SbcDetailScreen({required this.sbc, super.key});
  final SbcChallenge sbc;

  @override
  State<SbcDetailScreen> createState() => _SbcDetailScreenState();
}

class _SbcDetailScreenState extends State<SbcDetailScreen> {
  final repository = SbcRepository();
  final clubRepository = MyClubRepository();
  SbcSolution? solution;
  bool solving = false;
  String? solveError;

  Future<void> _solve() async {
    setState(() {
      solving = true;
      solveError = null;
      solution = null;
    });
    try {
      final ownedIds = await clubRepository.getPlayerIds();
      final data = await repository.getCheapestSolution(
        widget.sbc.id,
        ownedPlayerIds: ownedIds,
      );
      if (!mounted) return;
      setState(() => solution = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => solveError = e.toString());
    } finally {
      if (mounted) setState(() => solving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sbc = widget.sbc;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('SBC DETAILS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.primary.withValues(alpha: .28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sbc.title, style: Theme.of(context).textTheme.titleLarge),
                if (sbc.category.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sbc.category.toUpperCase(),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: scheme.primary, fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ],
                if (sbc.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(sbc.description, style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 12),
                _MiniStat(label: 'REWARD', value: sbc.reward.isEmpty ? '—' : sbc.reward),
                if (sbc.itemScore != null) ...[
                  const SizedBox(height: 8),
                  _MiniStat(label: 'ITEM SCORE', value: '${sbc.itemScore}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'REQUIREMENTS', subtitle: 'شرایط واقعی ثبت‌شده برای این چالش'),
          const SizedBox(height: 8),
          if (sbc.requirements.isEmpty)
            const _StateCard(
              icon: Icons.rule_rounded,
              title: 'Requirement ثبت نشده',
              subtitle: 'منبع فعلی شرط ساختاری بیشتری برنگردانده است.',
            )
          else
            for (final req in sbc.requirements) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outline.withValues(alpha: .7)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded, size: 17, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(req)),
                  ],
                ),
              ),
            ],
          if (sbc.guideFa.isNotEmpty) ...[
            const SizedBox(height: 14),
            const _SectionTitle(title: 'GUIDE', subtitle: 'راهنمای فارسی موجود در داده واقعی'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    for (var i = 0; i < sbc.guideFa.length; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Color(0xFF10140C),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(sbc.guideFa[i])),
                        ],
                      ),
                      if (i != sbc.guideFa.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (sbc.itemScore != null) ...[
            const _StateCard(
              icon: Icons.stars_rounded,
              title: 'SBC مبتنی بر Item Score',
              subtitle: 'برای این نوع چالش، راهنما بر اساس Item Score و Requirementهای واقعی منبع عمومی ساخته می‌شود.',
            ),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            onPressed: solving ? null : _solve,
            icon: solving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high_rounded),
            label: const Text('نمایش راه‌حل و راهنمای عمومی'),
          ),
          if (solveError != null) ...[
            const SizedBox(height: 10),
            _StateCard(
              icon: Icons.info_outline_rounded,
              title: 'راه‌حل واقعی در دسترس نیست',
              subtitle: solveError!,
            ),
          ],
          if (solution != null) ...[
            const SizedBox(height: 14),
            _SolutionCard(solution: solution!),
          ],
        ],
      ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  const _SolutionCard({required this.solution});
  final SbcSolution solution;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(solution.players.isEmpty ? 'PUBLIC GUIDE' : 'SOLUTION', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _MiniStat(label: 'TOTAL COST', value: solution.totalCost > 0 ? '${solution.totalCost} C' : '—')),
                const SizedBox(width: 7),
                Expanded(child: _MiniStat(label: 'REMAINING', value: solution.remainingCost > 0 ? '${solution.remainingCost} C' : '—')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'از باشگاه من: ${solution.ownedPlayerIds.length} کارت',
              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900),
            ),
            if (solution.itemScore != null) ...[
              const SizedBox(height: 6),
              Text('Item Score راه‌حل: ${solution.itemScore}'),
            ],
            if (solution.players.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final player in solution.players)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    solution.ownedPlayerIds.contains(player.playerId)
                        ? Icons.inventory_2_rounded
                        : Icons.shopping_cart_outlined,
                    color: solution.ownedPlayerIds.contains(player.playerId)
                        ? scheme.primary
                        : null,
                  ),
                  title: Text(player.name.isEmpty ? player.playerId : player.name),
                  subtitle: Text('${player.rating} • ${player.price} C'),
                  trailing: solution.ownedPlayerIds.contains(player.playerId)
                      ? const Chip(label: Text('OWNED'))
                      : null,
                ),
            ],
            if (solution.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final note in solution.notes) Text('• $note'),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: scheme.outline.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 8, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10.5)),
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 9),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(subtitle, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: action, child: const Text('تلاش دوباره')),
            ],
          ],
        ),
      ),
    );
  }
}
