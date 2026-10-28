import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
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
    return at != null &&
        DateTime.now().toUtc().difference(at.toUtc()) <
            const Duration(hours: 24);
  }
}

class LiveFc27Catalog {
  LiveFc27Catalog({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  // FC27 Hub is the canonical public data source. Do not point this back at
  // FCBaz: that created a circular dependency and prevented source updates.
  static const _hubBase = 'https://sahandse.github.io/FC27/data/';
  static const _cacheJsonKey = 'fcbaz_live_fc27_catalog_json_v3';
  static const _cacheSavedAtKey = 'fcbaz_live_fc27_catalog_saved_at_v3';

  static const _feedNames = <String>[
    'fc27-players.json',
    'fc27-prices.json',
    'fc27-challenges.json',
    'fc27-evolutions.json',
    'fc27-news.json',
    'fc27-card-art.json',
    'available-portraits.json',
  ];

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
      final cached = await _readPersistentCache(
        maxAge: const Duration(minutes: 30),
      );
      if (cached != null) return cached;
      final bundled = await _loadBundledCatalog();
      if (bundled != null) {
        _memory = bundled;
        _loadedAt = DateTime.now();
        _fromPersistentCache = true;
        return bundled;
      }
    }

    try {
      final data = await _loadHubCatalog();
      final text = jsonEncode(data);
      _memory = data;
      _loadedAt = DateTime.now();
      _fromPersistentCache = false;
      await _savePersistentCache(text);
      return data;
    } catch (_) {
      if (_memory != null) return _memory!;
      final cached = await _readPersistentCache();
      if (cached != null) return cached;
      final bundled = await _loadBundledCatalog();
      if (bundled != null) {
        _memory = bundled;
        _loadedAt = DateTime.now();
        _fromPersistentCache = true;
        return bundled;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _loadHubCatalog() async {
    // Read all feeds independently so one optional feed being temporarily
    // unavailable does not hide the player database or other valid sections.
    final results = await Future.wait(
      _feedNames.map((name) async {
        try {
          return MapEntry(name, await _getJson(Uri.parse('$_hubBase$name')));
        } catch (_) {
          return MapEntry<String, dynamic>(name, null);
        }
      }),
    );
    final feeds = Map<String, dynamic>.fromEntries(results);

    final playersFeed = feeds['fc27-players.json'];
    final players = _extractList(playersFeed, const [
      'players',
      'data',
      'items',
      'results',
    ]);
    if (players.isEmpty) {
      throw const FormatException('FC27 Hub returned no player records');
    }

    final priceFeed = feeds['fc27-prices.json'];
    final priceRows = _extractList(priceFeed, const [
      'prices',
      'players',
      'data',
      'items',
      'quotes',
    ]);
    // The FC27 Hub price feed is a quote table (cardId/platform/coins),
    // not a player-shaped object. Group PS and PC quotes by card ID rather
    // than letting the last platform row overwrite the first one.
    final pricesById = <String, Map<String, dynamic>>{};
    for (final row in priceRows) {
      final id =
          (row['cardId'] ??
                  row['card_id'] ??
                  row['versionId'] ??
                  row['version_id'] ??
                  _recordId(row))
              .toString()
              .trim();
      if (id.isEmpty) continue;
      final platform = (row['platform'] ?? '').toString().toLowerCase();
      final coins =
          int.tryParse(
            (row['coins'] ?? row['price'] ?? '').toString().replaceAll(
              RegExp(r'[^0-9]'),
              '',
            ),
          ) ??
          0;
      if (coins <= 0 ||
          (row['status'] != null && row['status'] != 'verified')) {
        continue;
      }
      final merged = pricesById.putIfAbsent(id, () => <String, dynamic>{});
      if (platform == 'ps' || platform == 'playstation' || platform == 'ps5') {
        merged['price_ps'] = coins;
      } else if (platform == 'pc') {
        merged['price_pc'] = coins;
      }
    }

    final mergedPlayers = players.map((raw) {
      final player = Map<String, dynamic>.from(raw);
      final id = _recordId(player);
      final price = pricesById[id];
      if (price != null) {
        // Keep explicit player values; otherwise attach verified PS/PC quotes.
        _copyIfMissing(player, price, const [
          'price_ps',
          'price_pc',
          'pricePs',
          'pricePc',
        ]);
      }
      return player;
    }).toList();

    final challenges = _asMap(feeds['fc27-challenges.json']);
    final sections = _asMap(challenges['sections']);
    final sbcs = _extractListFromValue(
      sections['sbc'] ?? sections['sbcs'] ?? sections['challenges'],
    );
    final objectives = _extractListFromValue(
      sections['objectives'] ?? sections['objective'],
    );
    final evolutionFeed = _asMap(feeds['fc27-evolutions.json']);
    final evolutions =
        _extractList(evolutionFeed, const [
          'evolutions',
          'data',
          'items',
          'results',
        ]).where((item) {
          final text = jsonEncode(item).toLowerCase();
          return !text.contains('fc26');
        }).toList();
    final newsFeed = _asMap(feeds['fc27-news.json']);
    final news = _extractList(newsFeed, const ['items', 'news', 'data']);
    final artFeed = _asMap(feeds['fc27-card-art.json']);
    final portraitsFeed = _asMap(feeds['available-portraits.json']);
    final pricesFeed = _asMap(feeds['fc27-prices.json']);

    final timestamps =
        feeds.values
            .whereType<Map>()
            .map((value) => value['checked_at'] ?? value['updated_at'])
            .whereType<String>()
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    return <String, dynamic>{
      'game_year': '27',
      'generated_at': timestamps.isEmpty
          ? DateTime.now().toUtc().toIso8601String()
          : timestamps.first.toUtc().toIso8601String(),
      'players': mergedPlayers,
      'sbcs': sbcs,
      'evolutions': evolutions,
      'objectives': objectives,
      'news': news,
      'card_art': _asMap(artFeed['art']),
      'available_portraits': _extractList(portraitsFeed, const [
        'ids',
        'portraits',
        'items',
      ]),
      'price_source': pricesFeed['source'] ?? pricesFeed['provider'],
      'price_source_url': pricesFeed['source_url'],
      'price_updated_at': pricesFeed['updated_at'] ?? pricesFeed['checked_at'],
      'priced_players': pricesById.length,
      'sources': _feedNames
          .where((name) => feeds[name] != null)
          .map((name) => '$_hubBase$name')
          .toList(),
    };
  }

  Future<dynamic> _getJson(Uri uri) async {
    final request = await _client
        .getUrl(uri)
        .timeout(const Duration(seconds: 10));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'FCBaz Android companion; FC27 public-data sync',
    );
    final response = await request.close().timeout(const Duration(seconds: 20));
    final text = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('FC27 Hub HTTP ${response.statusCode}');
    }
    return jsonDecode(text);
  }

  List<Map<String, dynamic>> _extractList(
    dynamic value,
    List<String> candidateKeys,
  ) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final map = _asMap(value);
    for (final key in candidateKeys) {
      final list = _extractListFromValue(map[key]);
      if (list.isNotEmpty) return list;
    }
    return const [];
  }

  List<Map<String, dynamic>> _extractListFromValue(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (value is Map) {
      for (final key in const ['items', 'data', 'results', 'challenges']) {
        final nested = value[key];
        if (nested is List) {
          return nested
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  String _recordId(Map<String, dynamic> record) {
    for (final key in const [
      'id',
      'player_id',
      'playerId',
      'resource_id',
      'resourceId',
      'ea_resource_id',
      'ea_id',
      'base_id',
      'cardId',
      'card_id',
      'versionId',
      'version_id',
    ]) {
      final value = record[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  void _copyIfMissing(
    Map<String, dynamic> target,
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final current = target[key];
      final numericCurrent = current is num
          ? current
          : num.tryParse(current?.toString().trim() ?? '');
      final isPrice = key.toLowerCase().contains('price');
      final missing =
          current == null ||
          current.toString().trim().isEmpty ||
          (isPrice && (numericCurrent == null || numericCurrent <= 0));
      if (missing && source.containsKey(key)) {
        target[key] = source[key];
      }
    }
  }

  Future<Map<String, dynamic>?> _loadBundledCatalog() async {
    try {
      return _decodeAndValidate(
        await rootBundle.loadString('assets/data/catalog.json'),
      );
    } catch (_) {
      return null;
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
      await prefs.setString(
        _cacheSavedAtKey,
        DateTime.now().toUtc().toIso8601String(),
      );
    } catch (_) {
      // Memory cache is still usable if persistent storage is unavailable.
    }
  }

  Future<Map<String, dynamic>?> _readPersistentCache({Duration? maxAge}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(_cacheJsonKey);
      if (text == null || text.trim().isEmpty) return null;
      if (maxAge != null) {
        final savedAt = DateTime.tryParse(
          prefs.getString(_cacheSavedAtKey) ?? '',
        );
        if (savedAt == null ||
            DateTime.now().toUtc().difference(savedAt.toUtc()) > maxAge) {
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

  /// The moment the verified coin prices in this catalog were last refreshed.
  /// Older catalogs do not carry the field, so it returns null instead of
  /// pretending the prices are current.
  Future<DateTime?> priceUpdatedAt() async {
    final data = await load();
    return DateTime.tryParse((data['price_updated_at'] ?? '').toString());
  }

  Future<LiveCatalogHealth> health({bool forceRefresh = false}) async {
    final data = await load(forceRefresh: forceRefresh);
    int count(String key) => data[key] is List ? (data[key] as List).length : 0;
    final rawSources = data['sources'];
    final sources = rawSources is List
        ? rawSources
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
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
