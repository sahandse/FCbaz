import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ObjectiveProgressEntry {
  const ObjectiveProgressEntry({
    required this.objectiveId,
    required this.taskId,
    required this.progress,
    required this.completed,
    required this.updatedAt,
  });

  final String objectiveId;
  final String taskId;
  final int progress;
  final bool completed;
  final DateTime updatedAt;

  String get key => '$objectiveId::$taskId';

  Map<String, dynamic> toJson() => {
        'objective_id': objectiveId,
        'task_id': taskId,
        'progress': progress,
        'completed': completed,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ObjectiveProgressEntry.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is int ? value : int.tryParse((value ?? '0').toString()) ?? 0;

    return ObjectiveProgressEntry(
      objectiveId: (json['objective_id'] ?? '').toString(),
      taskId: (json['task_id'] ?? '').toString(),
      progress: asInt(json['progress']),
      completed: json['completed'] == true,
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ObjectiveProgressRepository {
  static const _key = 'fcbaz_objective_progress_v1';

  Future<Map<String, ObjectiveProgressEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const {};
      final result = <String, ObjectiveProgressEntry>{};
      for (final item in decoded.whereType<Map>()) {
        final entry = ObjectiveProgressEntry.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (entry.objectiveId.isEmpty || entry.taskId.isEmpty) continue;
        result[entry.key] = entry;
      }
      return result;
    } catch (_) {
      return const {};
    }
  }

  Future<void> setProgress({
    required String objectiveId,
    required String taskId,
    required int progress,
    required int target,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final all = {...await getAll()};
    final safeProgress = progress < 0 ? 0 : progress;
    final completed = target > 0 && safeProgress >= target;
    final entry = ObjectiveProgressEntry(
      objectiveId: objectiveId,
      taskId: taskId,
      progress: safeProgress,
      completed: completed,
      updatedAt: DateTime.now(),
    );
    all[entry.key] = entry;
    await prefs.setString(
      _key,
      jsonEncode(all.values.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clearObjective(String objectiveId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = {...await getAll()}
      ..removeWhere((_, value) => value.objectiveId == objectiveId);
    await prefs.setString(
      _key,
      jsonEncode(all.values.map((e) => e.toJson()).toList()),
    );
  }
}
