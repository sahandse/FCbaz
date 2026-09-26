import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BackgroundSyncStatus {
  const BackgroundSyncStatus({
    this.lastRunAt,
    this.lastSuccessAt,
    this.lastChecked = 0,
    this.lastTriggered = 0,
    this.lastError,
  });

  final DateTime? lastRunAt;
  final DateTime? lastSuccessAt;
  final int lastChecked;
  final int lastTriggered;
  final String? lastError;

  bool get hasRun => lastRunAt != null;
  bool get lastRunSucceeded => lastSuccessAt != null && lastSuccessAt == lastRunAt;

  Map<String, dynamic> toJson() => {
        'last_run_at': lastRunAt?.toIso8601String(),
        'last_success_at': lastSuccessAt?.toIso8601String(),
        'last_checked': lastChecked,
        'last_triggered': lastTriggered,
        'last_error': lastError,
      };

  factory BackgroundSyncStatus.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
    return BackgroundSyncStatus(
      lastRunAt: DateTime.tryParse((json['last_run_at'] ?? '').toString()),
      lastSuccessAt: DateTime.tryParse((json['last_success_at'] ?? '').toString()),
      lastChecked: asInt(json['last_checked']),
      lastTriggered: asInt(json['last_triggered']),
      lastError: (json['last_error'] ?? '').toString().trim().isEmpty
          ? null
          : json['last_error'].toString(),
    );
  }
}

class BackgroundSyncStatusRepository {
  static const _key = 'fcbaz_background_sync_status';

  Future<BackgroundSyncStatus> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const BackgroundSyncStatus();
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return const BackgroundSyncStatus();
      return BackgroundSyncStatus.fromJson(Map<String, dynamic>.from(json));
    } catch (_) {
      return const BackgroundSyncStatus();
    }
  }

  Future<void> recordSuccess({
    required int checked,
    required int triggered,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    await _save(
      BackgroundSyncStatus(
        lastRunAt: now,
        lastSuccessAt: now,
        lastChecked: checked,
        lastTriggered: triggered,
      ),
    );
  }

  Future<void> recordFailure(String error, {DateTime? at}) async {
    final previous = await load();
    await _save(
      BackgroundSyncStatus(
        lastRunAt: at ?? DateTime.now(),
        lastSuccessAt: previous.lastSuccessAt,
        lastChecked: previous.lastChecked,
        lastTriggered: previous.lastTriggered,
        lastError: error,
      ),
    );
  }

  Future<void> _save(BackgroundSyncStatus value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(value.toJson()));
  }
}
