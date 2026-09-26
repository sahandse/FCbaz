import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WatchlistItem {
  const WatchlistItem({
    required this.playerId,
    required this.playerName,
    this.targetPrice,
    this.lastPrice,
    this.previousPrice,
    this.lastCheckedAt,
    this.platform,
  });

  final String playerId;
  final String playerName;
  final int? targetPrice;
  final int? lastPrice;
  final int? previousPrice;
  final DateTime? lastCheckedAt;
  final String? platform;

  int? get absoluteChange {
    if (lastPrice == null || previousPrice == null) return null;
    return lastPrice! - previousPrice!;
  }

  double? get percentChange {
    if (lastPrice == null || previousPrice == null || previousPrice == 0) {
      return null;
    }
    return ((lastPrice! - previousPrice!) / previousPrice!) * 100;
  }

  bool get targetReached =>
      targetPrice != null &&
      targetPrice! > 0 &&
      lastPrice != null &&
      lastPrice! > 0 &&
      lastPrice! <= targetPrice!;

  WatchlistItem copyWith({
    int? targetPrice,
    bool clearTargetPrice = false,
    int? lastPrice,
    int? previousPrice,
    DateTime? lastCheckedAt,
    String? platform,
  }) {
    return WatchlistItem(
      playerId: playerId,
      playerName: playerName,
      targetPrice: clearTargetPrice ? null : (targetPrice ?? this.targetPrice),
      lastPrice: lastPrice ?? this.lastPrice,
      previousPrice: previousPrice ?? this.previousPrice,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      platform: platform ?? this.platform,
    );
  }

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'player_name': playerName,
        'target_price': targetPrice,
        'last_price': lastPrice,
        'previous_price': previousPrice,
        'last_checked_at': lastCheckedAt?.toIso8601String(),
        'platform': platform,
      };

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    int? asNullableInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    }

    return WatchlistItem(
      playerId: (json['player_id'] ?? '').toString(),
      playerName: (json['player_name'] ?? '').toString(),
      targetPrice: asNullableInt(json['target_price']),
      lastPrice: asNullableInt(json['last_price']),
      previousPrice: asNullableInt(json['previous_price']),
      lastCheckedAt: DateTime.tryParse(
        (json['last_checked_at'] ?? '').toString(),
      ),
      platform: (json['platform'] ?? '').toString().isEmpty
          ? null
          : json['platform'].toString(),
    );
  }
}

class WatchlistRepository {
  static const _key = 'fcbaz_market_watchlist';

  Future<List<WatchlistItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((e) => WatchlistItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.playerId.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> contains(String playerId) async {
    final items = await getAll();
    return items.any((e) => e.playerId == playerId);
  }

  Future<void> toggle(WatchlistItem item) async {
    final items = [...await getAll()];
    final index = items.indexWhere((e) => e.playerId == item.playerId);
    if (index >= 0) {
      items.removeAt(index);
    } else {
      items.add(item);
    }
    await _save(items);
  }

  Future<void> setTargetPrice(String playerId, int? targetPrice) async {
    final items = [...await getAll()];
    final index = items.indexWhere((e) => e.playerId == playerId);
    if (index < 0) return;
    items[index] = items[index].copyWith(
      targetPrice: targetPrice,
      clearTargetPrice: targetPrice == null,
    );
    await _save(items);
  }

  Future<void> recordPrice(
    String playerId, {
    required int price,
    required String platform,
    DateTime? checkedAt,
  }) async {
    if (price <= 0) return;

    final items = [...await getAll()];
    final index = items.indexWhere((e) => e.playerId == playerId);
    if (index < 0) return;

    final current = items[index];
    final previous = current.lastPrice != null && current.lastPrice! > 0
        ? current.lastPrice
        : current.previousPrice;

    items[index] = current.copyWith(
      previousPrice: previous,
      lastPrice: price,
      lastCheckedAt: checkedAt ?? DateTime.now(),
      platform: platform,
    );
    await _save(items);
  }

  Future<void> _save(List<WatchlistItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}
