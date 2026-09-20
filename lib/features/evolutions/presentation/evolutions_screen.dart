import 'package:flutter/material.dart';

import '../data/evolution_repository.dart';
import '../domain/evolution.dart';

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
      appBar: AppBar(title: const Text('Evolutions')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Evo Lab', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'مسیرهای ارتقا، شرایط و بازیکنان واجد شرایط',
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
                  title: const Text('Evolutions در دسترس نیست'),
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
                _EvolutionCard(item: item, repository: repository),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _EvolutionCard extends StatefulWidget {
  const _EvolutionCard({required this.item, required this.repository});

  final Evolution item;
  final EvolutionRepository repository;

  @override
  State<_EvolutionCard> createState() => _EvolutionCardState();
}

class _EvolutionCardState extends State<_EvolutionCard> {
  bool loadingEligible = false;
  List<Map<String, dynamic>> eligible = const [];

  Future<void> _loadEligible() async {
    setState(() => loadingEligible = true);
    try {
      final data = await widget.repository.eligiblePlayers(widget.item.id);
      if (!mounted) return;
      setState(() => eligible = data);
    } finally {
      if (mounted) setState(() => loadingEligible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(item.cost == 0 ? 'رایگان' : item.cost.toString() + ' Coins'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (item.description.isNotEmpty)
            Align(alignment: Alignment.centerRight, child: Text(item.description)),
          if (item.requirements.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('شرایط', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 6),
            for (final req in item.requirements)
              Align(alignment: Alignment.centerRight, child: Text('• ' + req)),
          ],
          if (item.upgrades.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('ارتقاها', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 6),
            for (final upgrade in item.upgrades)
              Align(alignment: Alignment.centerRight, child: Text('• ' + upgrade)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: loadingEligible ? null : _loadEligible,
              icon: loadingEligible
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.person_search_rounded),
              label: const Text('بازیکنان مناسب'),
            ),
          ),
          if (eligible.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final player in eligible.take(8))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.person_rounded),
                title: Text((player['name'] ?? 'بازیکن').toString()),
                subtitle: Text((player['rating'] ?? '').toString()),
              ),
          ],
        ],
      ),
    );
  }
}
