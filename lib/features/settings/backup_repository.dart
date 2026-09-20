import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BackupRepository {
  static const formatVersion = 1;

  Future<Map<String, dynamic>> exportData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('fcbaz_')) continue;
      final value = prefs.get(key);
      if (value is String ||
          value is int ||
          value is double ||
          value is bool ||
          value is List<String>) {
        data[key] = value;
      }
    }

    return {
      'format_version': formatVersion,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'data': data,
    };
  }

  Future<String> exportJson() async =>
      const JsonEncoder.withIndent('  ').convert(await exportData());

  Future<int> restoreJson(
    String raw, {
    bool replaceExisting = true,
  }) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('فایل بکاپ معتبر نیست.');
    }

    final version = int.tryParse(
          (decoded['format_version'] ?? '').toString(),
        ) ??
        0;
    if (version != formatVersion) {
      throw const FormatException('نسخه بکاپ پشتیبانی نمی‌شود.');
    }

    final values = decoded['data'];
    if (values is! Map) {
      throw const FormatException('داده بکاپ ناقص است.');
    }

    final prefs = await SharedPreferences.getInstance();
    if (replaceExisting) {
      for (final key in prefs.getKeys().where((e) => e.startsWith('fcbaz_'))) {
        await prefs.remove(key);
      }
    }

    var restored = 0;
    for (final entry in values.entries) {
      final key = entry.key.toString();
      if (!key.startsWith('fcbaz_')) continue;

      final value = entry.value;
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is List && value.every((e) => e is String)) {
        await prefs.setStringList(key, value.cast<String>());
      } else {
        continue;
      }
      restored++;
    }

    return restored;
  }
}
