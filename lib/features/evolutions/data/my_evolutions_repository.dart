import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MyEvolutionEntry {
  const MyEvolutionEntry({
    required this.id,
    required this.playerName,
    required this.playerId,
    required this.evolutionTitle,
    required this.currentStep,
    required this.totalSteps,
    required this.note,
    required this.updatedAt,
  });

  final String id;
  final String playerName;
  final String playerId;
  final String evolutionTitle;
  final int currentStep;
  final int totalSteps;
  final String note;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'player_name': playerName,
        'player_id': playerId,
        'evolution_title': evolutionTitle,
        'current_step': currentStep,
        'total_steps': totalSteps,
        'note': note,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory MyEvolutionEntry.fromJson(Map<String, dynamic> json) =>
      MyEvolutionEntry(
        id: (json['id'] ?? '').toString(),
        playerName: (json['player_name'] ?? '').toString(),
        playerId: (json['player_id'] ?? '').toString(),
        evolutionTitle: (json['evolution_title'] ?? '').toString(),
        currentStep: int.tryParse('${json['current_step']}') ?? 0,
        totalSteps: int.tryParse('${json['total_steps']}') ?? 1,
        note: (json['note'] ?? '').toString(),
        updatedAt: DateTime.tryParse('${json['updated_at']}') ?? DateTime.now(),
      );
}

class MyEvolutionsRepository {
  static const _key = 'fcbaz_my_evolutions_v1';

  Future<List<MyEvolutionEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => MyEvolutionEntry.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> save(MyEvolutionEntry entry) async {
    final items = await getAll();
    final next = [
      entry,
      ...items.where((e) => e.id != entry.id),
    ];
    await _persist(next);
  }

  Future<void> remove(String id) async {
    final items = await getAll();
    await _persist(items.where((e) => e.id != id).toList());
  }

  Future<void> _persist(List<MyEvolutionEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
