import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PlayerReview {
  const PlayerReview({
    required this.playerId,
    required this.rating,
    required this.text,
    required this.updatedAt,
  });

  final String playerId;
  final int rating;
  final String text;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'rating': rating,
        'text': text,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PlayerReview.fromJson(Map<String, dynamic> json) => PlayerReview(
        playerId: (json['player_id'] ?? '').toString(),
        rating: json['rating'] is int
            ? json['rating'] as int
            : int.tryParse((json['rating'] ?? '0').toString()) ?? 0,
        text: (json['text'] ?? '').toString(),
        updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class PlayerReviewRepository {
  static const _key = 'fcbaz_player_reviews';

  Future<Map<String, PlayerReview>> _all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          PlayerReview.fromJson(
            value is Map
                ? Map<String, dynamic>.from(value)
                : const <String, dynamic>{},
          ),
        ),
      );
    } catch (_) {
      return const {};
    }
  }

  Future<PlayerReview?> get(String playerId) async =>
      (await _all())[playerId];

  Future<void> save({
    required String playerId,
    required int rating,
    required String text,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final all = {...await _all()};
    all[playerId] = PlayerReview(
      playerId: playerId,
      rating: rating.clamp(1, 5).toInt(),
      text: text.trim(),
      updatedAt: DateTime.now(),
    );
    await prefs.setString(
      _key,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  Future<void> remove(String playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = {...await _all()}..remove(playerId);
    await prefs.setString(
      _key,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }
}
