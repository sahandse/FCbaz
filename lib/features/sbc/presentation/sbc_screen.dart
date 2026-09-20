import 'package:flutter/material.dart';

import '../data/sbc_repository.dart';
import '../domain/sbc.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SBC')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'چالش‌های ساخت ترکیب',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'SBCهای فعال FC27 با هزینه، پاداش و راه‌حل واقعی',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
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
                subtitle: 'وقتی Backend داده واقعی FC27 داشته باشد اینجا نمایش داده می‌شود.',
              )
            else
              for (final item in items) ...[
                _SbcCard(item: item),
                const SizedBox(height: 10),
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
    if (value == null) return 'نامشخص';
    if (value >= 1000000) return (value / 1000000).toStringAsFixed(1) + 'M';
    if (value >= 1000) return (value / 1000).toStringAsFixed(0) + 'K';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SbcDetailScreen(sbc: item)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  if (item.repeatable)
                    const Chip(label: Text('تکرارپذیر')),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.category,
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800),
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _MiniStat(label: 'هزینه', value: _cost(item.estimatedCost) + ' C')),
                  const SizedBox(width: 8),
                  Expanded(child: _MiniStat(label: 'پاداش', value: item.reward.isEmpty ? '—' : item.reward)),
                ],
              ),
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
  SbcSolution? solution;
  bool solving = false;
  String? solveError;

  Future<void> _solve() async {
    setState(() {
      solving = true;
      solveError = null;
    });
    try {
      final data = await repository.getCheapestSolution(widget.sbc.id);
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
    return Scaffold(
      appBar: AppBar(title: Text(sbc.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sbc.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(sbc.description.isEmpty ? 'بدون توضیح' : sbc.description),
                  const SizedBox(height: 14),
                  Text('پاداش: ' + (sbc.reward.isEmpty ? '—' : sbc.reward)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('شرایط', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (sbc.requirements.isEmpty)
            const Card(child: ListTile(title: Text('شرایطی ثبت نشده است')))
          else
            for (final req in sbc.requirements)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.checklist_rounded),
                  title: Text(req),
                ),
              ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: solving ? null : _solve,
            icon: solving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high_rounded),
            label: const Text('حل ارزان SBC'),
          ),
          if (solveError != null) ...[
            const SizedBox(height: 10),
            Text(solveError!, textAlign: TextAlign.center),
          ],
          if (solution != null) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('راه‌حل پیشنهادی', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('هزینه کل: ' + solution!.totalCost.toString() + ' Coins'),
                    const SizedBox(height: 8),
                    Text('بازیکنان: ' + solution!.playerIds.length.toString()),
                    if (solution!.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      for (final note in solution!.notes) Text('• ' + note),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
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
