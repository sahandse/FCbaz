import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../players/data/player_repository.dart';
import '../../players/domain/player.dart';

class SavedPlayerFilter {
  const SavedPlayerFilter({
    required this.id,
    required this.name,
    required this.filter,
    required this.createdAt,
  });

  final String id;
  final String name;
  final PlayerFilter filter;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'filter': filter.toJson(),
      };

  factory SavedPlayerFilter.fromJson(Map<String, dynamic> json) =>
      SavedPlayerFilter(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        filter: PlayerFilter.fromJson(
          json['filter'] is Map
              ? Map<String, dynamic>.from(json['filter'] as Map)
              : const {},
        ),
      );
}

class SearchHistoryRepository {
  static const _recentKey = 'fcbaz_recent_searches';
  static const _savedKey = 'fcbaz_saved_filters';
  static const _favoriteKey = 'fcbaz_favorite_players';

  Future<List<String>> recentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? const [];
  }

  Future<void> addRecentSearch(String query) async {
    final q = query.trim();
    if (q.length < 2) return;
    final prefs = await SharedPreferences.getInstance();
    final items = [...(prefs.getStringList(_recentKey) ?? const <String>[])]
      ..removeWhere((e) => e.toLowerCase() == q.toLowerCase())
      ..insert(0, q);
    await prefs.setStringList(_recentKey, items.take(12).toList());
  }

  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
  }

  Future<List<SavedPlayerFilter>> savedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => SavedPlayerFilter.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveFilter(String name, PlayerFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    final items = [...await savedFilters()];
    final item = SavedPlayerFilter(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      filter: filter,
      createdAt: DateTime.now(),
    );
    items.insert(0, item);
    await prefs.setString(
      _savedKey,
      jsonEncode(items.take(20).map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteSavedFilter(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = [...await savedFilters()]..removeWhere((e) => e.id == id);
    await prefs.setString(
      _savedKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<Player>> favorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoriteKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> isFavorite(String playerId) async =>
      (await favorites()).any((p) => p.id == playerId);

  Future<void> toggleFavorite(Player player) async {
    final prefs = await SharedPreferences.getInstance();
    final items = [...await favorites()];
    final index = items.indexWhere((p) => p.id == player.id);
    if (index >= 0) {
      items.removeAt(index);
    } else {
      items.insert(0, player);
    }
    await prefs.setString(
      _favoriteKey,
      jsonEncode(items.map((p) => p.toJson()).toList()),
    );
  }
}
