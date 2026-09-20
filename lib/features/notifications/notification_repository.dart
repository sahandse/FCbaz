import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FCBazNotification {
  const FCBazNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.playerId,
    this.price,
    this.targetPrice,
    this.isRead = false,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? playerId;
  final int? price;
  final int? targetPrice;
  final bool isRead;

  FCBazNotification copyWith({bool? isRead}) => FCBazNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        createdAt: createdAt,
        playerId: playerId,
        price: price,
        targetPrice: targetPrice,
        isRead: isRead ?? this.isRead,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'player_id': playerId,
        'price': price,
        'target_price': targetPrice,
        'is_read': isRead,
      };

  factory FCBazNotification.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic value) =>
        value == null ? null : int.tryParse(value.toString());

    return FCBazNotification(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'info').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      playerId: json['player_id']?.toString(),
      price: asInt(json['price']),
      targetPrice: asInt(json['target_price']),
      isRead: json['is_read'] == true,
    );
  }
}

class NotificationRepository {
  static const _key = 'fcbaz_notifications';
  static const _alertStateKey = 'fcbaz_alert_state';

  Future<List<FCBazNotification>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final items = decoded
          .whereType<Map>()
          .map((e) => FCBazNotification.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .where((e) => e.id.isNotEmpty)
          .toList();

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<int> unreadCount() async =>
      (await getAll()).where((e) => !e.isRead).length;

  Future<void> add(FCBazNotification notification) async {
    final prefs = await SharedPreferences.getInstance();
    final items = [...await getAll()]..removeWhere((e) => e.id == notification.id);
    items.insert(0, notification);

    await prefs.setString(
      _key,
      jsonEncode(items.take(100).map((e) => e.toJson()).toList()),
    );
  }

  Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final items = (await getAll()).map((e) => e.copyWith(isRead: true)).toList();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = [...await getAll()]..removeWhere((e) => e.id == id);
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<Map<String, String>> alertStates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alertStateKey);
    if (raw == null || raw.isEmpty) return const {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return const {};
    }
  }

  Future<void> setAlertState(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    final states = {...await alertStates(), key: value};
    await prefs.setString(_alertStateKey, jsonEncode(states));
  }
}
