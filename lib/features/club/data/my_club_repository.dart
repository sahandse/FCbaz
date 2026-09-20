import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MyClubItem {
  const MyClubItem({
    required this.playerId,
    required this.playerName,
    required this.rating,
    required this.position,
    required this.acquisitionPrice,
  });

  final String playerId;
  final String playerName;
  final int rating;
  final String position;
  final int acquisitionPrice;

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'player_name': playerName,
        'rating': rating,
        'position': position,
        'acquisition_price': acquisitionPrice,
      };

  factory MyClubItem.fromJson(Map<String, dynamic> json) => MyClubItem(
        playerId: (json['player_id'] ?? '').toString(),
        playerName: (json['player_name'] ?? '').toString(),
        rating: json['rating'] is int
            ? json['rating'] as int
            : int.tryParse((json['rating'] ?? '0').toString()) ?? 0,
        position: (json['position'] ?? '').toString(),
        acquisitionPrice: json['acquisition_price'] is int
            ? json['acquisition_price'] as int
            : int.tryParse((json['acquisition_price'] ?? '0').toString()) ?? 0,
      );
}

class MyClubRepository {
  static const _key = 'fcbaz_my_club';

  Future<List<MyClubItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => MyClubItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.playerId.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> upsert(MyClubItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = [...await getAll()];
    final index = items.indexWhere((e) => e.playerId == item.playerId);

    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }

    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> remove(String playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = [...await getAll()]..removeWhere((e) => e.playerId == playerId);
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
