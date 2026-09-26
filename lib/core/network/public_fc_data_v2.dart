import 'dart:convert';
import 'dart:io';

import '../../features/players/domain/player.dart';
import 'live_fc27_catalog.dart';

class PublicFcData {
  PublicFcData({HttpClient? client, LiveFc27Catalog? liveCatalog})
      : _client = client ?? HttpClient(),
        _liveCatalog = liveCatalog ?? LiveFc27Catalog();

  final HttpClient _client;
  final LiveFc27Catalog _liveCatalog;

  static const _futbinBase = 'https://www.futbin.org/futbin/api/';
  static final Map<String, _PublicCacheEntry> _cache = {};

  Future<List<Player>> getPlayers({
    int page = 1,
    String platform = 'console',
  }) async {
    final live = await _livePlayers();
    if (live.isNotEmpty) {
      const pageSize = 100;
      final start = (page - 1).clamp(0, 9999) * pageSize;
      if (start >= live.length) return const [];
      final end = (start + pageSize).clamp(0, live.length);
      return live.sublist(start, end);
    }
    return _futbinPlayers(page: page, platform: platform);
  }

  Future<List<Player>> search(
    String query, {
    String platform = 'console',
  }) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    return getFiltered(
      params: {
        'q': q,
        'platform': platform,
        'sort': 'rating_desc',
      },
    );
  }

  Future<Player?> getPlayer(
    String id, {
    String platform = 'console',
  }) async {
    final live = await _livePlayers();
    for (final player in live) {
      if (player.id == id) return player;
    }

    try {
      for (var page = 1; page <= 10; page++) {
        final rows = await _futbinPlayers(page: page, platform: platform);
        if (rows.isEmpty) break;
        for (final player in rows) {
          if (player.id == id) return player;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<Player>> getTrending({
    String platform = 'console',
  }) async {
    // Only call data "trending/popular" when a real popularity source exists.
    try {
      final json = await _getFutbin(
        'getPopularPlayers',
        const {},
        ttl: const Duration(minutes: 2),
      );
      final data = json is Map ? json['data'] : null;
      if (data is List) {
        final players = data
            .whereType<Map>()
            .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
            .toList();
        if (players.isNotEmpty) return players;
      }
    } catch (_) {}

    try {
      final raw = await _liveCatalog.list('popular_players');
      return raw
          .map(Player.fromJson)
          .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
          .take(30)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Player>> getFiltered({
    required Map<String, String> params,
  }) async {
    var players = await _livePlayers();
    if (players.isEmpty) {
      try {
        final page = int.tryParse(params['page'] ?? '') ?? 1;
        players = await _futbinPlayers(
          page: page,
          platform: params['platform'] == 'pc' ? 'pc' : 'console',
        );
      } catch (_) {
        return const [];
      }
    }

    final q = (params['q'] ?? '').trim().toLowerCase();
    final position = (params['position'] ?? '').trim().toUpperCase();
    final minRating = _int(params['min_rating']);
    final maxRating = _int(params['max_rating']);
    final minPrice = _int(params['min_price']);
    final maxPrice = _int(params['max_price']);
    final minSkills = _int(params['min_skills']);
    final maxSkills = _int(params['max_skills']);
    final minWeakFoot = _int(params['min_weak_foot']);
    final maxWeakFoot = _int(params['max_weak_foot']);
    final pc = params['platform'] == 'pc';

    int price(Player p) => pc ? p.pricePc : p.pricePs;

    players = players.where((p) {
      if (q.isNotEmpty &&
          !p.name.toLowerCase().contains(q) &&
          !p.clubName.toLowerCase().contains(q) &&
          !p.leagueName.toLowerCase().contains(q) &&
          !p.nationName.toLowerCase().contains(q)) {
        return false;
      }
      if (position.isNotEmpty &&
          p.position.toUpperCase() != position &&
          !p.positions.map((e) => e.toUpperCase()).contains(position)) {
        return false;
      }
      if (minRating != null && p.rating < minRating) return false;
      if (maxRating != null && p.rating > maxRating) return false;
      if (!_contains(p.leagueName, params['league'])) return false;
      if (!_contains(p.clubName, params['club'])) return false;
      if (!_contains(p.nationName, params['nation'])) return false;

      final requestedCard = params['version'] ?? params['rarity'] ?? params['card_type'];
      if (!_cardMatches(p, requestedCard)) return false;

      if (!_statRange(p.pace, params['min_pace'], params['max_pace'])) return false;
      if (!_statRange(p.shooting, params['min_shooting'], params['max_shooting'])) return false;
      if (!_statRange(p.passing, params['min_passing'], params['max_passing'])) return false;
      if (!_statRange(p.dribbling, params['min_dribbling'], params['max_dribbling'])) return false;
      if (!_statRange(p.defending, params['min_defending'], params['max_defending'])) return false;
      if (!_statRange(p.physical, params['min_physical'], params['max_physical'])) return false;

      if (minSkills != null && p.skillMoves < minSkills) return false;
      if (maxSkills != null && p.skillMoves > maxSkills) return false;
      if (minWeakFoot != null && p.weakFoot < minWeakFoot) return false;
      if (maxWeakFoot != null && p.weakFoot > maxWeakFoot) return false;

      final value = price(p);
      if (minPrice != null && (value <= 0 || value < minPrice)) return false;
      if (maxPrice != null && (value <= 0 || value > maxPrice)) return false;
      return true;
    }).toList();

    _sort(players, params['sort'] ?? 'rating_desc', params['platform']);
    return players;
  }

  Future<Map<String, dynamic>?> getPrice(
    String playerId, {
    String platform = 'console',
  }) async {
    try {
      final p = platform == 'pc' ? 'PC' : 'PS';
      final json = await _getFutbin(
        'getPlayersPrice',
        {
          'player_ids': playerId,
          'platform': p,
        },
        ttl: const Duration(seconds: 45),
      );
      if (json is! Map) return null;
      final player = json[playerId];
      if (player is! Map) return null;
      final prices = player['prices'];
      if (prices is! Map) return null;
      final raw = prices[p];
      if (raw is! Map) return null;

      final current = _coin(raw['LCPrice']);
      if (current <= 0) return null;
      return {
        'player_id': playerId,
        'platform': platform,
        'current': current,
        'low': _coin(raw['MinPrice']),
        'high': _coin(raw['MaxPrice']),
        'change_24h_percent': null,
        'updated_text': (raw['updated'] ?? '').toString(),
        'source': 'futbin-public',
        'source_url': 'https://www.futbin.org/',
      };
    } catch (_) {
      return null;
    }
  }

  Future<List<Player>> _livePlayers() async {
    try {
      final raw = await _liveCatalog.list('players');
      final players = raw
          .map(Player.fromJson)
          .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
          .toList();
      players.sort((a, b) => b.rating.compareTo(a.rating));
      return players;
    } catch (_) {
      return const [];
    }
  }

  Future<List<Player>> _futbinPlayers({
    required int page,
    required String platform,
  }) async {
    final json = await _getFutbin(
      'getFilteredPlayers',
      {
        'platform': platform == 'pc' ? 'PC' : 'PS',
        'page': page.toString(),
      },
      ttl: const Duration(minutes: 2),
    );
    final data = json is Map ? json['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
        .toList();
  }

  Future<dynamic> _getFutbin(
    String endpoint,
    Map<String, String> params, {
    Duration ttl = const Duration(seconds: 90),
  }) async {
    final uri = Uri.parse(_futbinBase + endpoint).replace(
      queryParameters: params.isEmpty ? null : params,
    );
    final key = uri.toString();
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.at) < ttl) {
      return cached.value;
    }

    final request = await _client.getUrl(uri).timeout(const Duration(seconds: 8));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 FCBaz/1.4',
    );
    request.headers.set('Referer', 'https://www.futbin.com/');
    request.headers.set('Origin', 'https://www.futbin.com');

    final response = await request.close().timeout(const Duration(seconds: 12));
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(body);
    _cache[key] = _PublicCacheEntry(value: json, at: DateTime.now());
    return json;
  }

  bool _contains(String source, String? value) {
    final q = value?.trim().toLowerCase() ?? '';
    return q.isEmpty || source.toLowerCase().contains(q);
  }

  bool _cardMatches(Player player, String? requested) {
    var q = (requested ?? '').trim().toLowerCase();
    if (q.isEmpty) return true;
    q = q.replaceFirst(RegExp(r'^base\s+'), '');

    final values = [player.version, player.rarity, player.cardType]
        .map((e) => e.trim().toLowerCase().replaceFirst(RegExp(r'^base\s+'), ''))
        .where((e) => e.isNotEmpty)
        .toList();

    if (q == 'gold rare' || q == 'gold') {
      return values.any((e) => e == 'gold' || e == 'gold rare');
    }
    if (q.contains('team of the week') || q == 'totw') {
      return values.any((e) => e.contains('team of the week') || e.contains('totw'));
    }
    if (q.contains('hall of fut')) {
      return values.any((e) => e.contains('hall of fut'));
    }
    return values.any((e) => e == q || e.contains(q) || q.contains(e));
  }

  bool _statRange(int value, String? minRaw, String? maxRaw) {
    final min = _int(minRaw);
    final max = _int(maxRaw);
    if (min != null && value < min) return false;
    if (max != null && value > max) return false;
    return true;
  }

  int? _int(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return int.tryParse(value.trim());
  }

  void _sort(List<Player> players, String sort, String? platform) {
    final pc = platform == 'pc';
    int price(Player p) => pc ? p.pricePc : p.pricePs;

    switch (sort) {
      case 'rating_asc':
        players.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case 'price_asc':
        players.sort((a, b) {
          final ap = price(a);
          final bp = price(b);
          if (ap <= 0 && bp > 0) return 1;
          if (bp <= 0 && ap > 0) return -1;
          return ap.compareTo(bp);
        });
        break;
      case 'price_desc':
        players.sort((a, b) => price(b).compareTo(price(a)));
        break;
      case 'pace':
        players.sort((a, b) => b.pace.compareTo(a.pace));
        break;
      case 'shooting':
        players.sort((a, b) => b.shooting.compareTo(a.shooting));
        break;
      case 'passing':
        players.sort((a, b) => b.passing.compareTo(a.passing));
        break;
      case 'dribbling':
        players.sort((a, b) => b.dribbling.compareTo(a.dribbling));
        break;
      case 'defending':
        players.sort((a, b) => b.defending.compareTo(a.defending));
        break;
      case 'physical':
        players.sort((a, b) => b.physical.compareTo(a.physical));
        break;
      default:
        players.sort((a, b) => b.rating.compareTo(a.rating));
    }
  }

  int _coin(dynamic value) {
    if (value is num) return value.round();
    final raw = (value ?? '')
        .toString()
        .trim()
        .toUpperCase()
        .replaceAll(',', '');
    if (raw.isEmpty) return 0;
    var multiplier = 1.0;
    var number = raw;
    if (raw.endsWith('K')) {
      multiplier = 1000;
      number = raw.substring(0, raw.length - 1);
    } else if (raw.endsWith('M')) {
      multiplier = 1000000;
      number = raw.substring(0, raw.length - 1);
    }
    return ((double.tryParse(number) ?? 0) * multiplier).round();
  }
}

class _PublicCacheEntry {
  const _PublicCacheEntry({required this.value, required this.at});
  final dynamic value;
  final DateTime at;
}
