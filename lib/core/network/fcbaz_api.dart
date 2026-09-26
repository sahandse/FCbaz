import 'dart:convert';
import 'dart:io';

import '../../features/players/domain/player.dart';

class FCBazApiException implements Exception {
  const FCBazApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _CacheEntry {
  const _CacheEntry({
    required this.value,
    required this.createdAt,
  });

  final dynamic value;
  final DateTime createdAt;
}

class FCBazApi {
  FCBazApi({HttpClient? client}) : _client = client ?? HttpClient();

  static const baseUrl = String.fromEnvironment('FCBAZ_API_BASE_URL');
  final HttpClient _client;

  static final Map<String, _CacheEntry> _cache = {};

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  Future<List<Player>> fetchPlayers({bool forceRefresh = false}) async {
    final json = await getJson(
      '/api/v1/players',
      forceRefresh: forceRefresh,
      cacheTtl: const Duration(seconds: 90),
    );
    final raw = json is Map ? (json['data'] ?? json['players']) : json;
    if (raw is! List) {
      throw const FCBazApiException('پاسخ بازیکنان معتبر نیست.');
    }
    return raw
        .whereType<Map>()
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();
  }

  Future<List<Player>> searchPlayers(
    String query, {
    bool forceRefresh = false,
  }) async {
    final encoded = Uri.encodeQueryComponent(query);
    final json = await getJson(
      '/api/v1/players/search?q=$encoded',
      forceRefresh: forceRefresh,
      cacheTtl: const Duration(seconds: 45),
    );
    final raw = json is Map ? (json['data'] ?? json['players']) : json;
    if (raw is! List) {
      throw const FCBazApiException('پاسخ جستجو معتبر نیست.');
    }
    return raw
        .whereType<Map>()
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();
  }

  Future<Player> fetchPlayer(
    String id, {
    bool forceRefresh = false,
  }) async {
    final json = await getJson(
      '/api/v1/players/' + Uri.encodeComponent(id),
      forceRefresh: forceRefresh,
      cacheTtl: const Duration(seconds: 90),
    );
    final raw = json is Map ? (json['data'] ?? json['player'] ?? json) : json;
    if (raw is! Map) {
      throw const FCBazApiException('جزئیات بازیکن معتبر نیست.');
    }
    return Player.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<dynamic> getJson(
    String path, {
    bool forceRefresh = false,
    Duration cacheTtl = const Duration(seconds: 60),
  }) =>
      _requestJson(
        path: path,
        forceRefresh: forceRefresh,
        cacheTtl: cacheTtl,
      );

  void clearPublicCache() => _cache.clear();

  void invalidatePath(String pathPrefix) {
    _cache.removeWhere((key, _) => key.startsWith(pathPrefix));
  }

  Future<dynamic> _requestJson({
    required String path,
    bool forceRefresh = false,
    Duration cacheTtl = Duration.zero,
  }) async {
    if (!isConfigured) {
      throw const FCBazApiException('Backend FCBaz هنوز متصل نشده است.');
    }

    if (!forceRefresh && cacheTtl > Duration.zero) {
      final entry = _cache[path];
      if (entry != null &&
          DateTime.now().difference(entry.createdAt) < cacheTtl) {
        return entry.value;
      }
    }

    final uri = Uri.parse(baseUrl).resolve(path);
    final request =
        await _client.getUrl(uri).timeout(const Duration(seconds: 8));

    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set('X-FCBaz-Game-Year', '27');

    final response =
        await request.close().timeout(const Duration(seconds: 15));
    final responseBody = await utf8.decoder.bind(response).join();

    dynamic decoded;
    if (responseBody.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(responseBody);
      } on FormatException {
        throw const FCBazApiException('پاسخ سرور قابل خواندن نیست.');
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? (decoded['message'] ?? decoded['error'])?.toString()
          : null;
      throw FCBazApiException(
        message?.isNotEmpty == true
            ? message!
            : 'خطای سرور (' + response.statusCode.toString() + ')',
      );
    }

    if (cacheTtl > Duration.zero) {
      _cache[path] = _CacheEntry(
        value: decoded,
        createdAt: DateTime.now(),
      );
    }

    return decoded;
  }
}
