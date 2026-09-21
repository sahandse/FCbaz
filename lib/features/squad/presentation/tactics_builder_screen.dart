import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/squad_models.dart';

/// Local tactics notebook — stores real user codes/plans, never invents meta.
class TacticsBuilderScreen extends StatefulWidget {
  const TacticsBuilderScreen({super.key});

  @override
  State<TacticsBuilderScreen> createState() => _TacticsBuilderScreenState();
}

class _TacticsBuilderScreenState extends State<TacticsBuilderScreen> {
  static const _key = 'fcbaz_tactics_presets_v1';

  List<TacticProfile> presets = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    var items = <TacticProfile>[];
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        items = decoded
            .whereType<Map>()
            .map((e) => TacticProfile.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    if (!mounted) return;
    setState(() {
      presets = items;
      loading = false;
    });
  }

  Future<void> _persist(List<TacticProfile> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
    if (!mounted) return;
    setState(() => presets = items);
  }

  Future<void> _edit([TacticProfile? existing, int? index]) async {
    final name = TextEditingController(text: existing?.name ?? 'پلن جدید');
    final code = TextEditingController(text: existing?.code ?? '');
    final defensive =
        TextEditingController(text: existing?.defensivePlan ?? '');
    final buildUp = TextEditingController(text: existing?.buildUpPlan ?? '');
    final attacking =
        TextEditingController(text: existing?.attackingPlan ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'تاکتیک جدید' : 'ویرایش تاکتیک'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'نام پلن'),
              ),
              TextField(
                controller: code,
                decoration: const InputDecoration(labelText: 'Tactics Code'),
              ),
              TextField(
                controller: defensive,
                decoration: const InputDecoration(labelText: 'Defensive'),
              ),
              TextField(
                controller: buildUp,
                decoration: const InputDecoration(labelText: 'Build-Up'),
              ),
              TextField(
                controller: attacking,
                decoration: const InputDecoration(labelText: 'Attacking'),
              ),
              TextField(
                controller: notes,
                maxLines: 3,
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
    );

    if (saved != true) return;

    final next = TacticProfile(
      name: name.text.trim().isEmpty ? 'پلن' : name.text.trim(),
      code: code.text.trim(),
      defensivePlan: defensive.text.trim(),
      buildUpPlan: buildUp.text.trim(),
      attackingPlan: attacking.text.trim(),
      notes: notes.text.trim(),
    );

    final list = List<TacticProfile>.from(presets);
    if (index != null) {
      list[index] = next;
    } else {
      list.insert(0, next);
    }
    await _persist(list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tactics Builder')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              children: [
                Text(
                  'کد تاکتیک و پلن‌های واقعی خودتان را ذخیره کنید. FCBaz تاکتیک ساختگی پیشنهاد نمی‌دهد.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                if (presets.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('هنوز پلنی ذخیره نشده'),
                      subtitle: Text('با + کد تاکتیک بازی خودتان را ثبت کنید.'),
                    ),
                  ),
                for (var i = 0; i < presets.length; i++)
                  Card(
                    child: ListTile(
                      title: Text(
                        presets[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        [
                          if (presets[i].code.isNotEmpty)
                            'Code ${presets[i].code}',
                          if (presets[i].defensivePlan.isNotEmpty)
                            presets[i].defensivePlan,
                          if (presets[i].buildUpPlan.isNotEmpty)
                            presets[i].buildUpPlan,
                          if (presets[i].attackingPlan.isNotEmpty)
                            presets[i].attackingPlan,
                          if (presets[i].notes.isNotEmpty) presets[i].notes,
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final list = List<TacticProfile>.from(presets)
                            ..removeAt(i);
                          await _persist(list);
                        },
                      ),
                      onTap: () => _edit(presets[i], i),
                    ),
                  ),
              ],
            ),
    );
  }
}
