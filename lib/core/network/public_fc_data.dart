import 'dart:convert';
import 'dart:io';

import '../../features/players/domain/player.dart';

class PublicFcData {
  PublicFcData({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  static const _futbinBase = 'https://www.futbin.org/futbin/api/';
  static final Map<String, _PublicCacheEntry> _cache = {};

  Future<List<Player>> getPlayers({
    int page = 1,
    String platform = 'console',
  }) async {
    try {
      final json = await _getFutbin(
        'getFilteredPlayers',
        {
          'platform': platform == 'pc' ? 'PC' : 'PS',
          'page': page.toString(),
        },
      );
      final data = json is Map ? json['data'] : null;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    return const [];
  }

  Future<List<Player>> search(
    String query, {
    String platform = 'console',
  }) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];

    final found = <Player>[];
    final seen = <String>{};

    try {
      for (var page = 1; page <= 12; page++) {
        final json = await _getFutbin(
          'getFilteredPlayers',
          {
            'platform': platform == 'pc' ? 'PC' : 'PS',
            'page': page.toString(),
          },
          ttl: const Duration(minutes: 5),
        );
        final data = json is Map ? json['data'] : null;
        if (data is! List || data.isEmpty) break;

        for (final raw in data.whereType<Map>()) {
          final player = Player.fromJson(Map<String, dynamic>.from(raw));
          if (player.id.isEmpty || player.name.isEmpty) continue;
          if (!player.name.toLowerCase().contains(q)) continue;
          if (seen.add(player.id)) found.add(player);
        }
        if (found.length >= 30) break;
      }
    } catch (_) {}

    return found;
  }

  Future<Player?> getPlayer(
    String id, {
    String platform = 'console',
  }) async {
    try {
      for (var page = 1; page <= 20; page++) {
        final json = await _getFutbin(
          'getFilteredPlayers',
          {
            'platform': platform == 'pc' ? 'PC' : 'PS',
            'page': page.toString(),
          },
          ttl: const Duration(minutes: 5),
        );
        final data = json is Map ? json['data'] : null;
        if (data is! List || data.isEmpty) break;

        for (final raw in data.whereType<Map>()) {
          final map = Map<String, dynamic>.from(raw);
          final rawId = (map['ID'] ??
                  map['id'] ??
                  map['playerid'] ??
                  map['resource_id'] ??
                  '')
              .toString();
          if (rawId == id) return Player.fromJson(map);
        }
      }
    } catch (_) {}

    return null;
  }

  Future<List<Player>> getTrending({
    String platform = 'console',
  }) async {
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

    return getPlayers(platform: platform);
  }

  Future<List<Player>> getFiltered({
    required Map<String, String> params,
  }) async {
    try {
      final platform = params['platform'] == 'pc' ? 'PC' : 'PS';
      final apiParams = <String, String>{
        'platform': platform,
        'page': params['page'] ?? '1',
      };

      const supported = {
        'version',
        'position',
        'nation_id',
        'league_id',
        'club_id',
        'min_rating',
        'max_rating',
        'min_price',
        'max_price',
        'min_skills',
        'max_skills',
        'min_weak_foot',
        'max_weak_foot',
        'min_pace',
        'max_pace',
        'min_shooting',
        'max_shooting',
        'min_passing',
        'max_passing',
        'min_dribbling',
        'max_dribbling',
        'min_defending',
        'max_defending',
        'min_physical',
        'max_physical',
      };

      for (final key in supported) {
        final value = params[key];
        if (value != null && value.isNotEmpty) apiParams[key] = value;
      }

      final json = await _getFutbin(
        'getFilteredPlayers',
        apiParams,
        ttl: const Duration(minutes: 2),
      );
      final data = json is Map ? json['data'] : null;
      if (data is List) {
        var players = data
            .whereType<Map>()
            .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
            .toList();

        final q = (params['q'] ?? '').trim().toLowerCase();
        if (q.isNotEmpty) {
          players = players
              .where((e) => e.name.toLowerCase().contains(q))
              .toList();
        }

        players = _textFilter(players, params);
        _sort(players, params['sort'] ?? 'rating_desc', params['platform']);
        return players;
      }
    } catch (_) {}

    return const [];
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

      return {
        'player_id': playerId,
        'platform': platform,
        'current': _coin(raw['LCPrice']),
        'low': _coin(raw['MinPrice']),
        'high': _coin(raw['MaxPrice']),
        'change_24h_percent': 0,
        'updated_text': (raw['updated'] ?? '').toString(),
        'source': 'futbin-public',
      };
    } catch (_) {
      return null;
    }
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
    if (cached != null &&
        DateTime.now().difference(cached.at) < ttl) {
      return cached.value;
    }

    final request = await _client.getUrl(uri).timeout(
          const Duration(seconds: 10),
        );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 FCBaz/1.0',
    );
    request.headers.set('Referer', 'https://www.futbin.com/');
    request.headers.set('Origin', 'https://www.futbin.com');

    final response = await request.close().timeout(
          const Duration(seconds: 15),
        );
    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ' + response.statusCode.toString());
    }

    final json = jsonDecode(body);
    _cache[key] = _PublicCacheEntry(value: json, at: DateTime.now());
    return json;
  }

  List<Player> _textFilter(
    List<Player> players,
    Map<String, String> params,
  ) {
    bool contains(String source, String? value) {
      final q = value?.trim().toLowerCase() ?? '';
      return q.isEmpty || source.toLowerCase().contains(q);
    }

    final position = params['position']?.trim() ?? '';
    final minRating = int.tryParse(params['min_rating'] ?? '');
    final maxRating = int.tryParse(params['max_rating'] ?? '');

    return players.where((p) {
      if (position.isNotEmpty &&
          p.position != position &&
          !p.positions.contains(position)) {
        return false;
      }
      if (p.rating > 0) {
        if (minRating != null && p.rating < minRating) return false;
        if (maxRating != null && p.rating > maxRating) return false;
      }
      if (!contains(p.leagueName, params['league'])) return false;
      if (!contains(p.clubName, params['club'])) return false;
      if (!contains(p.nationName, params['nation'])) return false;
      return true;
    }).toList();
  }

  void _sort(
    List<Player> players,
    String sort,
    String? platform,
  ) {
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
  const _PublicCacheEntry({
    required this.value,
    required this.at,
  });

  final dynamic value;
  final DateTime at;
}
