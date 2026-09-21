import 'package:flutter/material.dart';

import 'home_repository.dart';

class ObjectivesScreen extends StatefulWidget {
  const ObjectivesScreen({super.key});

  @override
  State<ObjectivesScreen> createState() => _ObjectivesScreenState();
}

class _ObjectivesScreenState extends State<ObjectivesScreen> {
  final repository = HomeRepository();
  bool loading = true;
  String? error;
  List<HomeObjective> items = const [];

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
    try {
      final data = await repository.getObjectives(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() => items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _expiry(DateTime? value) {
    if (value == null) return 'بدون زمان پایان مشخص';
    final local = value.toLocal();
    return local.year.toString() + '/' +
        local.month.toString().padLeft(2, '0') + '/' +
        local.day.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Objectives')),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Objectives زنده FC27', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'هدف‌ها، پاداش‌ها و زمان پایان از منبع واقعی خوانده می‌شوند.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 70),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: const Text('Objectives در دسترس نیست'),
                  subtitle: Text(error!),
                  trailing: IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
                ),
              )
            else if (items.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.flag_outlined),
                  title: Text('Objective فعالی پیدا نشد'),
                  subtitle: Text(
                    'وقتی منبع زنده Objectives در دسترس باشد، هدف‌ها و پاداش‌ها اینجا می‌آیند. داده ساختگی نمایش داده نمی‌شود.',
                  ),
                ),
              )
            else
              for (final item in items) ...[
                Card(
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
                            if (item.taskCount > 0)
                              Chip(label: Text(item.taskCount.toString() + ' Task')),
                          ],
                        ),
                        if (item.description.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          Text(item.description),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.card_giftcard_rounded, size: 17),
                            const SizedBox(width: 6),
                            Expanded(child: Text(item.reward.isEmpty ? 'پاداش نامشخص' : item.reward)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 17),
                            const SizedBox(width: 6),
                            Text(_expiry(item.expiresAt)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 9),
              ],
          ],
        ),
      ),
    );
  }
}