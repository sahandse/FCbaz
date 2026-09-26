import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class LiveCatalogHealth {
  const LiveCatalogHealth({
    required this.generatedAt,
    required this.loadedAt,
    required this.players,
    required this.sbcs,
    required this.evolutions,
    required this.objectives,
    required this.sources,
    required this.fromPersistentCache,
  });

  final DateTime? generatedAt;
  final DateTime? loadedAt;
  final int players;
  final int sbcs;
  final int evolutions;
  final int objectives;
  final List<String> sources;
  final bool fromPersistentCache;

  bool get isFresh {
    final at = generatedAt;
    if (at == null) return false;
    return DateTime.now().toUtc().difference(at.toUtc()) < const Duration(hours: 24);
  }
}

class LiveFc27Catalog {
  LiveFc27Catalog({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  static const _url =
      'https://raw.githubusercontent.com/sahandse/FCbaz/main/data/live/catalog.json';
  static const _cacheJsonKey = 'fcbaz_live_fc27_catalog_json_v1';
  static const _cacheSavedAtKey = 'fcbaz_live_fc27_catalog_saved_at_v1';

  static Map<String, dynamic>? _memory;
  static DateTime? _loadedAt;
  static bool _fromPersistentCache = false;

  Future<Map<String, dynamic>> load({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _memory != null &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < const Duration(minutes: 10)) {
      return _memory!;
    }

    if (!forceRefresh && _memory == null) {
      final cached = await _readPersistentCache(maxAge: const Duration(minutes: 30));
      if (cached != null) return cached;
    }

    try {
      final request = await _client.getUrl(Uri.parse(_url)).timeout(
            const Duration(seconds: 8),
          );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'FCBaz/1.4 Android FC27 companion',
      );

      final response = await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Live catalog HTTP ${response.statusCode}');
      }

      final text = await utf8.decoder.bind(response).join();
      final data = _decodeAndValidate(text);
      _memory = data;
      _loadedAt = DateTime.now();
      _fromPersistentCache = false;
      await _savePersistentCache(text);
      return data;
    } catch (_) {
      if (_memory != null) return _memory!;
      final cached = await _readPersistentCache();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Map<String, dynamic> _decodeAndValidate(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('Live FC27 catalog is not a JSON object');
    }

    final data = Map<String, dynamic>.from(decoded);
    if ((data['game_year'] ?? '').toString() != '27') {
      throw const FormatException('Live catalog is not FC27 data');
    }

    final players = data['players'];
    if (players is! List || players.isEmpty) {
      throw const FormatException('Live FC27 catalog has no players');
    }
    return data;
  }

  Future<void> _savePersistentCache(String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheJsonKey, text);
      await prefs.setString(_cacheSavedAtKey, DateTime.now().toUtc().toIso8601String());
    } catch (_) {
      // Memory cache is still usable even if the platform cache cannot be written.
    }
  }

  Future<Map<String, dynamic>?> _readPersistentCache({Duration? maxAge}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(_cacheJsonKey);
      if (text == null || text.trim().isEmpty) return null;

      if (maxAge != null) {
        final savedAt = DateTime.tryParse(prefs.getString(_cacheSavedAtKey) ?? '');
        if (savedAt == null || DateTime.now().toUtc().difference(savedAt.toUtc()) > maxAge) {
          return null;
        }
      }

      final data = _decodeAndValidate(text);
      _memory = data;
      _loadedAt = DateTime.now();
      _fromPersistentCache = true;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> list(
    String key, {
    bool forceRefresh = false,
  }) async {
    final data = await load(forceRefresh: forceRefresh);
    final raw = data[key];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<DateTime?> generatedAt() async {
    final data = await load();
    return DateTime.tryParse((data['generated_at'] ?? '').toString());
  }

  Future<LiveCatalogHealth> health({bool forceRefresh = false}) async {
    final data = await load(forceRefresh: forceRefresh);
    int count(String key) => data[key] is List ? (data[key] as List).length : 0;
    final rawSources = data['sources'];
    final sources = rawSources is List
        ? rawSources.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const <String>[];

    return LiveCatalogHealth(
      generatedAt: DateTime.tryParse((data['generated_at'] ?? '').toString()),
      loadedAt: _loadedAt,
      players: count('players'),
      sbcs: count('sbcs'),
      evolutions: count('evolutions'),
      objectives: count('objectives'),
      sources: sources,
      fromPersistentCache: _fromPersistentCache,
    );
  }

  Future<void> clearPersistentCache() async {
    _memory = null;
    _loadedAt = null;
    _fromPersistentCache = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheJsonKey);
    await prefs.remove(_cacheSavedAtKey);
  }
}
