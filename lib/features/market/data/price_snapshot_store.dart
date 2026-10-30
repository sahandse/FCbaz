import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/player_price.dart';

/// Records only prices the app actually observed, so a local chart never
/// contains invented points.
class PriceSnapshotStore {
  PriceSnapshotStore({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const _prefix = 'fcbaz_price_snapshots_v1';
  static const maxSamplesPerPlayer = 200;
  static const retention = Duration(days: 60);
  static const minGapForUnchangedPrice = Duration(hours: 6);

  String _key(String playerId, String platform) =>
      '${_prefix}_${Uri.encodeComponent(playerId)}_'
      '${Uri.encodeComponent(platform)}';

  Future<List<PricePoint>> getHistory(
    String playerId, {
    String platform = 'console',
  }) async {
    if (playerId.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    return _parse(prefs.getString(_key(playerId, platform)));
  }

  /// Every locally observed stream for [platform], keyed by player id. Used by
  /// the compact market table so each row can show its own real sparkline.
  Future<Map<String, List<PricePoint>>> getAllHistories({
    String platform = 'console',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${_prefix}_';
    final suffix = '_${Uri.encodeComponent(platform)}';
    final result = <String, List<PricePoint>>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(prefix) || !key.endsWith(suffix)) continue;
      final encodedId = key.substring(
        prefix.length,
        key.length - suffix.length,
      );
      if (encodedId.isEmpty) continue;
      final points = _parse(prefs.getString(key));
      if (points.isEmpty) continue;
      result[Uri.decodeComponent(encodedId)] = points;
    }
    return result;
  }

  List<PricePoint> _parse(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final points = decoded
          .whereType<Map>()
          .map((e) => PricePoint.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.price > 0 && p.time.millisecondsSinceEpoch > 0)
          .toList();
      points.sort((a, b) => a.time.compareTo(b.time));
      return points;
    } catch (_) {
      return const [];
    }
  }

  Future<List<PricePoint>> record(
    String playerId, {
    required int price,
    String platform = 'console',
    DateTime? observedAt,
  }) async {
    final history = [...await getHistory(playerId, platform: platform)];
    if (playerId.isEmpty || price <= 0) return history;

    final at = observedAt ?? _now();
    final last = history.isEmpty ? null : history.last;
    if (last != null && !at.isAfter(last.time)) return history;
    if (last != null &&
        last.price == price &&
        at.difference(last.time) < minGapForUnchangedPrice) {
      return history;
    }

    history.add(PricePoint(time: at, price: price));

    final cutoff = at.subtract(retention);
    final retained = history.where((p) => !p.time.isBefore(cutoff)).toList();
    final bounded = retained.length > maxSamplesPerPlayer
        ? retained.sublist(retained.length - maxSamplesPerPlayer)
        : retained;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(playerId, platform),
      jsonEncode(
        bounded
            .map((p) => {'time': p.time.toIso8601String(), 'price': p.price})
            .toList(),
      ),
    );
    return bounded;
  }

  Future<void> clear(String playerId, {String platform = 'console'}) async {
    if (playerId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(playerId, platform));
  }
}
