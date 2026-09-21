import 'package:flutter/material.dart';

import '../data/my_evolutions_repository.dart';
import 'evolutions_screen.dart';

class EvolutionsHubScreen extends StatefulWidget {
  const EvolutionsHubScreen({super.key});

  @override
  State<EvolutionsHubScreen> createState() => _EvolutionsHubScreenState();
}

class _EvolutionsHubScreenState extends State<EvolutionsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolutions Hub'),
        bottom: TabBar(
          controller: tabs,
          tabs: const [
            Tab(text: 'فعال'),
            Tab(text: 'My Evo'),
            Tab(text: 'برنامه‌ریز'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabs,
        children: const [
          EvolutionsScreen(embedded: true),
          _MyEvolutionsTab(),
          _EvoPlannerTab(),
        ],
      ),
    );
  }
}

class _MyEvolutionsTab extends StatefulWidget {
  const _MyEvolutionsTab();

  @override
  State<_MyEvolutionsTab> createState() => _MyEvolutionsTabState();
}

class _MyEvolutionsTabState extends State<_MyEvolutionsTab> {
  final repository = MyEvolutionsRepository();
  List<MyEvolutionEntry> items = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await repository.getAll();
    if (!mounted) return;
    setState(() {
      items = data;
      loading = false;
    });
  }

  Future<void> _addOrEdit([MyEvolutionEntry? existing]) async {
    final name = TextEditingController(text: existing?.playerName ?? '');
    final evo = TextEditingController(text: existing?.evolutionTitle ?? '');
    final note = TextEditingController(text: existing?.note ?? '');
    var step = existing?.currentStep ?? 1;
    var total = existing?.totalSteps ?? 3;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Evo جدید' : 'ویرایش Evo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'نام بازیکن'),
                ),
                TextField(
                  controller: evo,
                  decoration: const InputDecoration(labelText: 'عنوان Evolution'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text('مرحله $step / $total'),
                    ),
                    IconButton(
                      onPressed: () => setDialog(() {
                        if (step > 0) step--;
                      }),
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      onPressed: () => setDialog(() {
                        if (step < total) step++;
                      }),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'یادداشت'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    if (name.text.trim().isEmpty || evo.text.trim().isEmpty) return;

    await repository.save(
      MyEvolutionEntry(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        playerName: name.text.trim(),
        playerId: existing?.playerId ?? '',
        evolutionTitle: evo.text.trim(),
        currentStep: step,
        totalSteps: total,
        note: note.text.trim(),
        updatedAt: DateTime.now(),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addOrEdit,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Text(
            'پیگیری Evolutionهای خودتان روی دستگاه — بدون حساب ابری.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Card(
              child: ListTile(
                title: Text('هنوز Evoای ذخیره نشده'),
                subtitle: Text('با + یک Evolution در حال انجام اضافه کنید.'),
              ),
            ),
          for (final item in items)
            Card(
              child: ListTile(
                title: Text(item.playerName),
                subtitle: Text(
                  '${item.evolutionTitle}\nمرحله ${item.currentStep}/${item.totalSteps}'
                  '${item.note.isEmpty ? '' : '\n${item.note}'}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await repository.remove(item.id);
                    await _load();
                  },
                ),
                onTap: () => _addOrEdit(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _EvoPlannerTab extends StatelessWidget {
  const _EvoPlannerTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _PlanCard(
          title: '۱. بازیکن پایه را انتخاب کنید',
          body: 'از باشگاه من یا دیتابیس، کارتی با پوزیشن و ریتینگ مناسب بردارید.',
        ),
        _PlanCard(
          title: '۲. مسیر Evolution را مشخص کنید',
          body:
              'عنوان Evo، تعداد مراحل و پاداش نهایی را در My Evo ثبت کنید تا فراموش نشود.',
        ),
        _PlanCard(
          title: '۳. Deadline را جدی بگیرید',
          body:
              'Evoهای زمان‌دار را زودتر شروع کنید. اگر لیست فعال خالی است، منبع زنده هنوز در دسترس نیست.',
        ),
        _PlanCard(
          title: '۴. Popular paths',
          body:
              'معمولاً مسیرهای Pace/Shooting برای ST و Defending برای CB محبوب‌ترند.',
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(body),
        ),
      ),
    );
  }
}
