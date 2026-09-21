import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../../features/players/domain/player.dart';
import 'player_media.dart';

/// Free real-data layer for FCBaz.
///
/// Priority:
/// 1. Live public market endpoints when reachable (prices / trending).
/// 2. Bundled FC26 community player catalog (real ratings/stats).
///
/// Never invents coin prices or player cards.
class PublicFcData {
  PublicFcData({
    HttpClient? client,
    Uint8List? catalogBytes,
  })  : _client = client ?? HttpClient(),
        _injectedCatalogBytes = catalogBytes;

  final HttpClient _client;
  final Uint8List? _injectedCatalogBytes;

  static const _marketApiBase = 'https://www.futbin.org/futbin/api/';
  static const _catalogAsset = 'assets/data/players_fc26.json.gz';
  static const _catalogRemote =
      'https://raw.githubusercontent.com/ismailoksuz/EAFC26-DataHub/main/data/players.json.gz';

  static final Map<String, _PublicCacheEntry> _cache = {};
  static List<Player>? _catalog;

  Future<List<Player>> getPlayers({
    int page = 1,
    String platform = 'console',
  }) async {
    final live = await _marketPlayers(page: page, platform: platform);
    if (live.isNotEmpty) {
      return enrichWithPrices(live, platform: platform);
    }

    final catalog = await _loadCatalog();
    const pageSize = 40;
    final start = (page < 1 ? 0 : page - 1) * pageSize;
    if (start >= catalog.length) return const [];
    return enrichWithPrices(
      catalog.skip(start).take(pageSize).toList(),
      platform: platform,
    );
  }

  Future<List<Player>> search(
    String query, {
    String platform = 'console',
  }) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];

    final live = await _marketSearch(q, platform: platform);
    if (live.isNotEmpty) {
      return enrichWithPrices(live, platform: platform);
    }

    final catalog = await _loadCatalog();
    final found = catalog
        .where((e) => e.name.toLowerCase().contains(q))
        .take(40)
        .toList();
    return enrichWithPrices(found, platform: platform);
  }

  Future<Player?> getPlayer(
    String id, {
    String platform = 'console',
  }) async {
    final live = await _marketFindById(id, platform: platform);
    if (live != null) {
      final enriched = await enrichWithPrices([live], platform: platform);
      return enriched.isEmpty ? live : enriched.first;
    }

    final catalog = await _loadCatalog();
    for (final player in catalog) {
      if (player.id == id) {
        final enriched = await enrichWithPrices([player], platform: platform);
        return enriched.isEmpty ? player : enriched.first;
      }
    }
    return null;
  }

  Future<List<Player>> getTrending({
    String platform = 'console',
  }) async {
    try {
      final json = await _getMarketApi(
        'getPopularPlayers',
        const {},
        ttl: const Duration(minutes: 2),
      );
      final data = json is Map ? json['data'] : null;
      if (data is List) {
        final players = data
            .whereType<Map>()
            .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id.isNotEmpty && e.name.isNotEmpty && e.rating > 0)
            .map(_withPortrait)
            .toList();
        if (players.isNotEmpty) {
          return enrichWithPrices(players, platform: platform);
        }
      }
    } catch (_) {}

    final catalog = await _loadCatalog();
    return enrichWithPrices(catalog.take(24).toList(), platform: platform);
  }

  Future<List<Player>> getFiltered({
    required Map<String, String> params,
  }) async {
    final platform = params['platform'] == 'pc' ? 'pc' : 'console';
    try {
      final apiPlatform = platform == 'pc' ? 'PC' : 'PS';
      final apiParams = <String, String>{
        'platform': apiPlatform,
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

      final json = await _getMarketApi(
        'getFilteredPlayers',
        apiParams,
        ttl: const Duration(minutes: 2),
      );
      final data = json is Map ? json['data'] : null;
      if (data is List) {
        var players = data
            .whereType<Map>()
            .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id.isNotEmpty && e.name.isNotEmpty && e.rating > 0)
            .map(_withPortrait)
            .toList();

        final q = (params['q'] ?? '').trim().toLowerCase();
        if (q.isNotEmpty) {
          players =
              players.where((e) => e.name.toLowerCase().contains(q)).toList();
        }

        players = _textFilter(players, params);
        _sort(players, params['sort'] ?? 'rating_desc', params['platform']);
        if (players.isNotEmpty) {
          return enrichWithPrices(players, platform: platform);
        }
      }
    } catch (_) {}

    var catalog = await _loadCatalog();
    catalog = _textFilter(List<Player>.from(catalog), params);

    final q = (params['q'] ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      catalog = catalog.where((e) => e.name.toLowerCase().contains(q)).toList();
    }

    final minPace = int.tryParse(params['min_pace'] ?? '');
    final maxPace = int.tryParse(params['max_pace'] ?? '');
    final minSho = int.tryParse(params['min_shooting'] ?? '');
    final maxSho = int.tryParse(params['max_shooting'] ?? '');
    final minPas = int.tryParse(params['min_passing'] ?? '');
    final maxPas = int.tryParse(params['max_passing'] ?? '');
    final minDri = int.tryParse(params['min_dribbling'] ?? '');
    final maxDri = int.tryParse(params['max_dribbling'] ?? '');
    final minDef = int.tryParse(params['min_defending'] ?? '');
    final maxDef = int.tryParse(params['max_defending'] ?? '');
    final minPhy = int.tryParse(params['min_physical'] ?? '');
    final maxPhy = int.tryParse(params['max_physical'] ?? '');
    final minSkills = int.tryParse(params['min_skills'] ?? '');
    final minWf = int.tryParse(params['min_weak_foot'] ?? '');

    catalog = catalog.where((p) {
      if (minPace != null && p.pace < minPace) return false;
      if (maxPace != null && p.pace > maxPace) return false;
      if (minSho != null && p.shooting < minSho) return false;
      if (maxSho != null && p.shooting > maxSho) return false;
      if (minPas != null && p.passing < minPas) return false;
      if (maxPas != null && p.passing > maxPas) return false;
      if (minDri != null && p.dribbling < minDri) return false;
      if (maxDri != null && p.dribbling > maxDri) return false;
      if (minDef != null && p.defending < minDef) return false;
      if (maxDef != null && p.defending > maxDef) return false;
      if (minPhy != null && p.physical < minPhy) return false;
      if (maxPhy != null && p.physical > maxPhy) return false;
      if (minSkills != null && p.skillMoves < minSkills) return false;
      if (minWf != null && p.weakFoot < minWf) return false;
      return true;
    }).toList();

    _sort(catalog, params['sort'] ?? 'rating_desc', params['platform']);

    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    const pageSize = 40;
    final start = (page - 1).clamp(0, 100000) * pageSize;
    if (start >= catalog.length) return const [];
    return enrichWithPrices(
      catalog.skip(start).take(pageSize).toList(),
      platform: platform,
    );
  }

  Future<Map<String, dynamic>?> getPrice(
    String playerId, {
    String platform = 'console',
  }) async {
    final batch = await getPricesBatch([playerId], platform: platform);
    return batch[playerId];
  }

  Future<Map<String, Map<String, dynamic>>> getPricesBatch(
    List<String> playerIds, {
    String platform = 'console',
  }) async {
    final ids = playerIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isEmpty) return const {};

    final out = <String, Map<String, dynamic>>{};
    final p = platform == 'pc' ? 'PC' : 'PS';

    for (var i = 0; i < ids.length; i += 20) {
      final chunk = ids.skip(i).take(20).toList();
      try {
        final json = await _getMarketApi(
          'getPlayersPrice',
          {
            'player_ids': chunk.join(','),
            'platform': p,
          },
          ttl: const Duration(seconds: 45),
        );
        if (json is! Map) continue;

        for (final id in chunk) {
          final player = json[id];
          if (player is! Map) continue;
          final prices = player['prices'];
          if (prices is! Map) continue;
          final raw = prices[p];
          if (raw is! Map) continue;
          final current = _coin(raw['LCPrice']);
          if (current <= 0) continue;
          final bins = <int>[
            current,
            _coin(raw['LCPrice2']),
            _coin(raw['LCPrice3']),
            _coin(raw['LCPrice4']),
            _coin(raw['LCPrice5']),
          ].where((e) => e > 0).toSet().toList()
            ..sort();
          out[id] = {
            'player_id': id,
            'platform': platform,
            'current': current,
            'low': _coin(raw['MinPrice']),
            'high': _coin(raw['MaxPrice']),
            'lowest_bins': bins.take(3).toList(),
            'change_24h_percent': 0,
            'updated_text': (raw['updated'] ?? '').toString(),
            'source': 'live-market',
          };
        }
      } catch (_) {}
    }

    return out;
  }

  Future<List<Player>> enrichWithPrices(
    List<Player> players, {
    String platform = 'console',
  }) async {
    if (players.isEmpty) return players;
    final withImages = players.map(_withPortrait).toList();
    final needsPrice = withImages
        .where((p) => (platform == 'pc' ? p.pricePc : p.pricePs) <= 0)
        .map((p) => p.id)
        .toList();
    if (needsPrice.isEmpty) return withImages;

    final prices = await getPricesBatch(needsPrice, platform: platform);
    if (prices.isEmpty) return withImages;

    return withImages.map((player) {
      final price = prices[player.id];
      if (price == null) return player;
      final current = price['current'];
      final value = current is int ? current : int.tryParse('$current') ?? 0;
      if (value <= 0) return player;
      if (platform == 'pc') {
        return player.copyWith(pricePc: value);
      }
      return player.copyWith(pricePs: value);
    }).toList();
  }

  Player _withPortrait(Player player) {
    final resolved = PlayerMedia.resolve(player.id, player.imageUrl);
    if (resolved == player.imageUrl && player.cardImageUrl.isNotEmpty) {
      return player;
    }
    return player.copyWith(
      imageUrl: resolved,
      cardImageUrl:
          player.cardImageUrl.isEmpty ? resolved : player.cardImageUrl,
    );
  }

  Future<List<Player>> _marketPlayers({
    required int page,
    required String platform,
  }) async {
    try {
      final json = await _getMarketApi(
        'getFilteredPlayers',
        {
          'platform': platform == 'pc' ? 'PC' : 'PS',
          'page': page.toString(),
        },
      );
      final data = json is Map ? json['data'] : null;
      if (data is List) {
        final players = data
            .whereType<Map>()
            .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id.isNotEmpty && e.name.isNotEmpty && e.rating > 0)
            .map(_withPortrait)
            .toList();
        if (players.isNotEmpty) return players;
      }
    } catch (_) {}
    return const [];
  }

  Future<List<Player>> _marketSearch(
    String q, {
    required String platform,
  }) async {
    final found = <Player>[];
    final seen = <String>{};

    try {
      for (var page = 1; page <= 8; page++) {
        final json = await _getMarketApi(
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
          final player = _withPortrait(
            Player.fromJson(Map<String, dynamic>.from(raw)),
          );
          if (player.id.isEmpty || player.name.isEmpty || player.rating <= 0) {
            continue;
          }
          if (!player.name.toLowerCase().contains(q)) continue;
          if (seen.add(player.id)) found.add(player);
        }
        if (found.length >= 30) break;
      }
    } catch (_) {}

    return found;
  }

  Future<Player?> _marketFindById(
    String id, {
    required String platform,
  }) async {
    try {
      for (var page = 1; page <= 12; page++) {
        final json = await _getMarketApi(
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
          if (rawId == id) {
            final player = _withPortrait(Player.fromJson(map));
            if (player.rating > 0) return player;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<dynamic> _getMarketApi(
    String endpoint,
    Map<String, String> params, {
    Duration ttl = const Duration(seconds: 90),
  }) async {
    final uri = Uri.parse(_marketApiBase + endpoint).replace(
      queryParameters: params.isEmpty ? null : params,
    );
    final key = uri.toString();
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.at) < ttl) {
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

  Future<List<Player>> _loadCatalog() async {
    if (_catalog != null) return _catalog!;

    Uint8List? bytes = _injectedCatalogBytes;
    if (bytes == null) {
      try {
        final data = await rootBundle.load(_catalogAsset);
        bytes = data.buffer.asUint8List();
      } catch (_) {
        bytes = await _downloadRemoteCatalog();
      }
    }

    if (bytes == null || bytes.isEmpty) {
      _catalog = const [];
      return _catalog!;
    }

    try {
      final decoded = gzip.decode(bytes);
      final raw = jsonDecode(utf8.decode(decoded));
      final players = <Player>[];

      if (raw is List) {
        for (final item in raw.whereType<Map>()) {
          final player = _playerFromCatalog(Map<String, dynamic>.from(item));
          if (player != null) players.add(_withPortrait(player));
        }
      }

      players.sort((a, b) {
        final byRating = b.rating.compareTo(a.rating);
        if (byRating != 0) return byRating;
        return a.name.compareTo(b.name);
      });

      _catalog = players;
      return players;
    } catch (_) {
      _catalog = const [];
      return _catalog!;
    }
  }

  Future<Uint8List?> _downloadRemoteCatalog() async {
    try {
      final request = await _client.getUrl(Uri.parse(_catalogRemote));
      request.headers.set(HttpHeaders.userAgentHeader, 'FCBaz/1.0');
      final response = await request.close().timeout(
            const Duration(seconds: 45),
          );
      if (response.statusCode != 200) return null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } catch (_) {
      return null;
    }
  }

  Player? _playerFromCatalog(Map<String, dynamic> json) {
    if (json.containsKey('n') || json.containsKey('r')) {
      final id = (json['id'] ?? '').toString();
      final name = (json['n'] ?? json['ln'] ?? '').toString();
      final rating = _asInt(json['r']);
      if (id.isEmpty || name.isEmpty || rating <= 0) return null;

      final positions = (json['ps'] is List)
          ? (json['ps'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : <String>[];
      final position = (json['p'] ??
              (positions.isNotEmpty ? positions.first : 'CM'))
          .toString();
      final image = PlayerMedia.resolve(id, (json['img'] ?? '').toString());

      return Player(
        id: id,
        name: name,
        rating: rating,
        position: position,
        positions: positions.isEmpty ? [position] : positions,
        clubName: (json['c'] ?? '').toString(),
        leagueName: (json['l'] ?? '').toString(),
        nationName: (json['na'] ?? '').toString(),
        version: 'Gold',
        imageUrl: image,
        cardImageUrl: image,
        pace: _asInt(json['pac']),
        shooting: _asInt(json['sho']),
        passing: _asInt(json['pas']),
        dribbling: _asInt(json['dri']),
        defending: _asInt(json['defe']),
        physical: _asInt(json['phy']),
        skillMoves: _asInt(json['sm']),
        weakFoot: _asInt(json['wf']),
        rarity: 'Rare',
        cardType: 'Gold',
      );
    }

    final id = (json['player_id'] ?? json['id'] ?? '').toString();
    final name =
        (json['short_name'] ?? json['long_name'] ?? json['name'] ?? '')
            .toString();
    final rating = _asInt(json['overall'] ?? json['rating']);
    if (id.isEmpty || name.isEmpty || rating <= 0) return null;

    final posRaw =
        (json['player_positions'] ?? json['position'] ?? 'CM').toString();
    final positions = posRaw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final image = PlayerMedia.resolve(
      id,
      (json['player_face_url'] ?? json['image_url'] ?? '').toString(),
    );

    return Player(
      id: id,
      name: name,
      rating: rating,
      position: positions.isNotEmpty ? positions.first : 'CM',
      positions: positions.isEmpty ? const ['CM'] : positions,
      clubName: (json['club_name'] ?? '').toString(),
      leagueName: (json['league_name'] ?? '').toString(),
      nationName:
          (json['nationality_name'] ?? json['nation_name'] ?? '').toString(),
      version: 'Gold',
      imageUrl: image,
      cardImageUrl: image,
      pace: _asInt(json['pace']),
      shooting: _asInt(json['shooting']),
      passing: _asInt(json['passing']),
      dribbling: _asInt(json['dribbling']),
      defending: _asInt(json['defending']),
      physical: _asInt(json['physic'] ?? json['physical']),
      skillMoves: _asInt(json['skill_moves']),
      weakFoot: _asInt(json['weak_foot']),
      rarity: 'Rare',
      cardType: 'Gold',
    );
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
      if (minRating != null && p.rating < minRating) return false;
      if (maxRating != null && p.rating > maxRating) return false;
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
    final raw =
        (value ?? '').toString().trim().toUpperCase().replaceAll(',', '');
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

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) {
      if (value.isNaN) return 0;
      return value.round();
    }
    return int.tryParse((value ?? '').toString().split('.').first) ?? 0;
  }

  static void debugResetCatalog() {
    _catalog = null;
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
