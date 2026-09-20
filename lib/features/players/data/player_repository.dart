import '../../../core/network/fcbaz_api.dart';
import '../domain/player.dart';

enum PlayerSort {
  ratingDesc,
  ratingAsc,
  priceAsc,
  priceDesc,
  pace,
  shooting,
  passing,
  dribbling,
  defending,
  physical,
}

class PlayerFacets {
  const PlayerFacets({
    this.versions = const [],
    this.rarities = const [],
    this.cardTypes = const [],
    this.leagues = const [],
    this.clubs = const [],
    this.nations = const [],
  });

  final List<String> versions;
  final List<String> rarities;
  final List<String> cardTypes;
  final List<String> leagues;
  final List<String> clubs;
  final List<String> nations;

  factory PlayerFacets.fromJson(Map<String, dynamic> json) {
    List<String> list(dynamic value) => value is List
        ? value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const [];

    return PlayerFacets(
      versions: list(json['versions']),
      rarities: list(json['rarities']),
      cardTypes: list(json['card_types']),
      leagues: list(json['leagues']),
      clubs: list(json['clubs']),
      nations: list(json['nations']),
    );
  }
}

class PlayerFilter {
  const PlayerFilter({
    this.query = '',
    this.position,
    this.version,
    this.rarity,
    this.cardType,
    this.league,
    this.club,
    this.nation,
    this.minRating = 40,
    this.maxRating = 99,
    this.minPrice,
    this.maxPrice,
    this.platform = 'console',
    this.sort = PlayerSort.ratingDesc,
  });

  final String query;
  final String? position;
  final String? version;
  final String? rarity;
  final String? cardType;
  final String? league;
  final String? club;
  final String? nation;
  final int minRating;
  final int maxRating;
  final int? minPrice;
  final int? maxPrice;
  final String platform;
  final PlayerSort sort;

  int get activeCount {
    var count = 0;
    if (position != null) count++;
    if (version != null) count++;
    if (rarity != null) count++;
    if (cardType != null) count++;
    if (league != null) count++;
    if (club != null) count++;
    if (nation != null) count++;
    if (minRating != 40 || maxRating != 99) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (platform != 'console') count++;
    if (sort != PlayerSort.ratingDesc) count++;
    return count;
  }

  PlayerFilter copyWith({
    String? query,
    String? position,
    bool clearPosition = false,
    String? version,
    bool clearVersion = false,
    String? rarity,
    bool clearRarity = false,
    String? cardType,
    bool clearCardType = false,
    String? league,
    bool clearLeague = false,
    String? club,
    bool clearClub = false,
    String? nation,
    bool clearNation = false,
    int? minRating,
    int? maxRating,
    int? minPrice,
    bool clearMinPrice = false,
    int? maxPrice,
    bool clearMaxPrice = false,
    String? platform,
    PlayerSort? sort,
  }) {
    return PlayerFilter(
      query: query ?? this.query,
      position: clearPosition ? null : (position ?? this.position),
      version: clearVersion ? null : (version ?? this.version),
      rarity: clearRarity ? null : (rarity ?? this.rarity),
      cardType: clearCardType ? null : (cardType ?? this.cardType),
      league: clearLeague ? null : (league ?? this.league),
      club: clearClub ? null : (club ?? this.club),
      nation: clearNation ? null : (nation ?? this.nation),
      minRating: minRating ?? this.minRating,
      maxRating: maxRating ?? this.maxRating,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      platform: platform ?? this.platform,
      sort: sort ?? this.sort,
    );
  }
}

class PlayerSearchResult {
  const PlayerSearchResult({
    required this.players,
    required this.facets,
  });

  final List<Player> players;
  final PlayerFacets facets;
}

class PlayerRepository {
  PlayerRepository({FCBazApi? api}) : api = api ?? FCBazApi();

  final FCBazApi api;

  Future<List<Player>> getPlayers() => api.fetchPlayers();

  Future<List<Player>> search(String query) => api.searchPlayers(query);

  Future<Player> getPlayer(String id) => api.fetchPlayer(id);

  Future<List<Player>> getVersions(String id) async {
    final json = await api.getJson(
      '/api/v1/players/' + Uri.encodeComponent(id) + '/versions',
    );
    final raw = json is Map ? (json['data'] ?? json['players'] ?? const []) : json;
    if (raw is! List) {
      throw const FCBazApiException('نسخه‌های دیگر بازیکن معتبر نیست.');
    }
    return raw
        .whereType<Map>()
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();
  }

  Future<PlayerSearchResult> advanced(
    PlayerFilter filter, {
    int page = 1,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'min_rating': filter.minRating.toString(),
      'max_rating': filter.maxRating.toString(),
      'platform': filter.platform,
      'sort': _sortKey(filter.sort),
    };

    void add(String key, Object? value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) params[key] = text;
    }

    add('q', filter.query);
    add('position', filter.position);
    add('version', filter.version);
    add('rarity', filter.rarity);
    add('card_type', filter.cardType);
    add('league', filter.league);
    add('club', filter.club);
    add('nation', filter.nation);
    add('min_price', filter.minPrice);
    add('max_price', filter.maxPrice);

    final query = params.entries
        .map(
          (e) =>
              Uri.encodeQueryComponent(e.key) +
              '=' +
              Uri.encodeQueryComponent(e.value),
        )
        .join('&');

    final json = await api.getJson('/api/v1/players/advanced?' + query);
    final raw = json is Map ? (json['data'] ?? const []) : json;

    if (raw is! List) {
      throw const FCBazApiException('پاسخ فیلتر پیشرفته معتبر نیست.');
    }

    final players = raw
        .whereType<Map>()
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();

    final meta = json is Map && json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : const <String, dynamic>{};

    final facetsRaw = meta['facets'] is Map
        ? Map<String, dynamic>.from(meta['facets'] as Map)
        : const <String, dynamic>{};

    return PlayerSearchResult(
      players: players,
      facets: PlayerFacets.fromJson(facetsRaw),
    );
  }

  String _sortKey(PlayerSort sort) {
    switch (sort) {
      case PlayerSort.ratingDesc:
        return 'rating_desc';
      case PlayerSort.ratingAsc:
        return 'rating_asc';
      case PlayerSort.priceAsc:
        return 'price_asc';
      case PlayerSort.priceDesc:
        return 'price_desc';
      case PlayerSort.pace:
        return 'pace';
      case PlayerSort.shooting:
        return 'shooting';
      case PlayerSort.passing:
        return 'passing';
      case PlayerSort.dribbling:
        return 'dribbling';
      case PlayerSort.defending:
        return 'defending';
      case PlayerSort.physical:
        return 'physical';
    }
  }
}
