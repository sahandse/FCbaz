import 'package:flutter/material.dart';

import 'home_repository.dart';
import 'objective_progress_repository.dart';

class ObjectivesScreen extends StatefulWidget {
  const ObjectivesScreen({super.key});

  @override
  State<ObjectivesScreen> createState() => _ObjectivesScreenState();
}

class _ObjectivesScreenState extends State<ObjectivesScreen> {
  final repository = HomeRepository();
  final progressRepository = ObjectiveProgressRepository();

  bool loading = true;
  String? error;
  List<HomeObjective> items = const [];
  Map<String, ObjectiveProgressEntry> progress = const {};
  String category = 'همه';

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
      final result = await Future.wait([
        repository.getObjectives(forceRefresh: forceRefresh),
        progressRepository.getAll(),
      ]);
      if (!mounted) return;
      setState(() {
        items = result[0] as List<HomeObjective>;
        progress = result[1] as Map<String, ObjectiveProgressEntry>;
      });
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
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }

  List<String> get _categories {
    final values = items
        .map((e) => e.category.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['همه', ...values];
  }

  List<HomeObjective> get _visibleItems {
    if (category == 'همه') return items;
    return items.where((e) => e.category == category).toList();
  }

  ObjectiveProgressEntry? _entry(HomeObjective objective, HomeObjectiveTask task) {
    return progress['${objective.id}::${task.id}'];
  }

  double _objectiveProgress(HomeObjective objective) {
    if (objective.tasks.isEmpty) return 0;
    var done = 0;
    for (final task in objective.tasks) {
      final entry = _entry(objective, task);
      if (entry?.completed == true) done++;
    }
    return done / objective.tasks.length;
  }

  Future<void> _editTask(HomeObjective objective, HomeObjectiveTask task) async {
    final current = _entry(objective, task)?.progress ?? 0;
    final controller = TextEditingController(text: current.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: task.target > 0 ? 'پیشرفت از ${task.target}' : 'پیشرفت',
            helperText: 'این مقدار فقط روی دستگاه شما ذخیره می‌شود.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              int.tryParse(controller.text.trim()),
            ),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await progressRepository.setProgress(
      objectiveId: objective.id,
      taskId: task.id,
      progress: value,
      target: task.target,
    );
    final updated = await progressRepository.getAll();
    if (!mounted) return;
    setState(() => progress = updated);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final visible = _visibleItems;
    return Scaffold(
      appBar: AppBar(title: const Text('هدف‌ها')),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('هدف‌های زنده FC27', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'هدف‌ها و پاداش‌ها از منبع واقعی؛ پیشرفت شما فقط روی همین دستگاه ذخیره می‌شود.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            if (!loading && items.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final item in categories) ...[
                      ChoiceChip(
                        label: Text(item),
                        selected: category == item,
                        onSelected: (_) => setState(() => category = item),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
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
                  title: const Text('هدف‌ها در دسترس نیست'),
                  subtitle: Text(error!),
                  trailing: IconButton(
                    onPressed: () => _load(),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              )
            else if (visible.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.flag_outlined),
                  title: Text('هدف فعالی پیدا نشد'),
                ),
              )
            else
              for (final item in visible) ...[
                _ObjectiveCard(
                  item: item,
                  expiry: _expiry(item.expiresAt),
                  progress: _objectiveProgress(item),
                  progressForTask: (task) => _entry(item, task),
                  onEditTask: (task) => _editTask(item, task),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({
    required this.item,
    required this.expiry,
    required this.progress,
    required this.progressForTask,
    required this.onEditTask,
  });

  final HomeObjective item;
  final String expiry;
  final double progress;
  final ObjectiveProgressEntry? Function(HomeObjectiveTask task) progressForTask;
  final void Function(HomeObjectiveTask task) onEditTask;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          child: Text(item.tasks.isEmpty ? '🎯' : '$percent%'),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.category.isNotEmpty) Text(item.category),
            const SizedBox(height: 5),
            LinearProgressIndicator(value: item.tasks.isEmpty ? null : progress),
          ],
        ),
        children: [
          if (item.description.isNotEmpty)
            Align(alignment: Alignment.centerRight, child: Text(item.description)),
          const SizedBox(height: 12),
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
              Text(expiry),
            ],
          ),
          if (item.tasks.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'وظایف (${item.tasks.length})',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 8),
            for (final task in item.tasks) ...[
              Builder(builder: (context) {
                final entry = progressForTask(task);
                final current = entry?.progress ?? 0;
                final completed = entry?.completed == true;
                final value = task.target > 0
                    ? (current / task.target).clamp(0.0, 1.0)
                    : null;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: completed ? Theme.of(context).colorScheme.primary : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          IconButton(
                            tooltip: 'ثبت پیشرفت',
                            onPressed: () => onEditTask(task),
                            icon: const Icon(Icons.edit_rounded),
                          ),
                        ],
                      ),
                      if (task.description.isNotEmpty) Text(task.description),
                      if (task.target > 0) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: value),
                        const SizedBox(height: 4),
                        Text('$current / ${task.target}'),
                      ] else if (current > 0) ...[
                        const SizedBox(height: 6),
                        Text('پیشرفت ثبت‌شده: $current'),
                      ],
                      if (task.reward.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('پاداش: ${task.reward}'),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ] else if (item.taskCount > 0) ...[
            const SizedBox(height: 12),
            Text(
              '${item.taskCount} وظیفه در منبع اعلام شده، اما جزئیات Taskها دریافت نشده؛ FCBaz پیشرفت ساختگی ایجاد نمی‌کند.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
