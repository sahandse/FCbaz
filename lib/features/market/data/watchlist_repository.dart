import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WatchlistItem {
  const WatchlistItem({
    required this.playerId,
    required this.playerName,
    this.targetPrice,
  });

  final String playerId;
  final String playerName;
  final int? targetPrice;

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'player_name': playerName,
        'target_price': targetPrice,
      };

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    final rawTarget = json['target_price'];
    return WatchlistItem(
      playerId: (json['player_id'] ?? '').toString(),
      playerName: (json['player_name'] ?? '').toString(),
      targetPrice: rawTarget is int ? rawTarget : int.tryParse(rawTarget?.toString() ?? ''),
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
    final prefs = await SharedPreferences.getInstance();
    final items = [...await getAll()];
    final index = items.indexWhere((e) => e.playerId == item.playerId);
    if (index >= 0) {
      items.removeAt(index);
    } else {
      items.add(item);
    }
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> setTargetPrice(String playerId, int? targetPrice) async {
    final prefs = await SharedPreferences.getInstance();
    final items = [...await getAll()];
    final index = items.indexWhere((e) => e.playerId == playerId);
    if (index < 0) return;
    items[index] = WatchlistItem(
      playerId: items[index].playerId,
      playerName: items[index].playerName,
      targetPrice: targetPrice,
    );
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}
