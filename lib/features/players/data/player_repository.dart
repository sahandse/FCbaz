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
    this.playStyle,
    this.playStylePlus,
    this.role,
    this.minSkillMoves,
    this.minWeakFoot,
    this.minPace,
    this.maxPace,
    this.minShooting,
    this.maxShooting,
    this.minPassing,
    this.maxPassing,
    this.minDribbling,
    this.maxDribbling,
    this.minDefending,
    this.maxDefending,
    this.minPhysical,
    this.maxPhysical,
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
  final String? playStyle;
  final String? playStylePlus;
  final String? role;
  final int? minSkillMoves;
  final int? minWeakFoot;
  final int? minPace;
  final int? maxPace;
  final int? minShooting;
  final int? maxShooting;
  final int? minPassing;
  final int? maxPassing;
  final int? minDribbling;
  final int? maxDribbling;
  final int? minDefending;
  final int? maxDefending;
  final int? minPhysical;
  final int? maxPhysical;
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
    if (playStyle != null) count++;
    if (playStylePlus != null) count++;
    if (role != null) count++;
    if (minSkillMoves != null) count++;
    if (minWeakFoot != null) count++;
    if (minPace != null || maxPace != null) count++;
    if (minShooting != null || maxShooting != null) count++;
    if (minPassing != null || maxPassing != null) count++;
    if (minDribbling != null || maxDribbling != null) count++;
    if (minDefending != null || maxDefending != null) count++;
    if (minPhysical != null || maxPhysical != null) count++;
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
    String? playStyle,
    bool clearPlayStyle = false,
    String? playStylePlus,
    bool clearPlayStylePlus = false,
    String? role,
    bool clearRole = false,
    int? minSkillMoves,
    bool clearMinSkillMoves = false,
    int? minWeakFoot,
    bool clearMinWeakFoot = false,
    int? minPace,
    bool clearMinPace = false,
    int? maxPace,
    bool clearMaxPace = false,
    int? minShooting,
    bool clearMinShooting = false,
    int? maxShooting,
    bool clearMaxShooting = false,
    int? minPassing,
    bool clearMinPassing = false,
    int? maxPassing,
    bool clearMaxPassing = false,
    int? minDribbling,
    bool clearMinDribbling = false,
    int? maxDribbling,
    bool clearMaxDribbling = false,
    int? minDefending,
    bool clearMinDefending = false,
    int? maxDefending,
    bool clearMaxDefending = false,
    int? minPhysical,
    bool clearMinPhysical = false,
    int? maxPhysical,
    bool clearMaxPhysical = false,
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
      playStyle: clearPlayStyle ? null : (playStyle ?? this.playStyle),
      playStylePlus: clearPlayStylePlus ? null : (playStylePlus ?? this.playStylePlus),
      role: clearRole ? null : (role ?? this.role),
      minSkillMoves: clearMinSkillMoves ? null : (minSkillMoves ?? this.minSkillMoves),
      minWeakFoot: clearMinWeakFoot ? null : (minWeakFoot ?? this.minWeakFoot),
      minPace: clearMinPace ? null : (minPace ?? this.minPace),
      maxPace: clearMaxPace ? null : (maxPace ?? this.maxPace),
      minShooting: clearMinShooting ? null : (minShooting ?? this.minShooting),
      maxShooting: clearMaxShooting ? null : (maxShooting ?? this.maxShooting),
      minPassing: clearMinPassing ? null : (minPassing ?? this.minPassing),
      maxPassing: clearMaxPassing ? null : (maxPassing ?? this.maxPassing),
      minDribbling: clearMinDribbling ? null : (minDribbling ?? this.minDribbling),
      maxDribbling: clearMaxDribbling ? null : (maxDribbling ?? this.maxDribbling),
      minDefending: clearMinDefending ? null : (minDefending ?? this.minDefending),
      maxDefending: clearMaxDefending ? null : (maxDefending ?? this.maxDefending),
      minPhysical: clearMinPhysical ? null : (minPhysical ?? this.minPhysical),
      maxPhysical: clearMaxPhysical ? null : (maxPhysical ?? this.maxPhysical),
      sort: sort ?? this.sort,
    );
  }

  Map<String, dynamic> toJson() => {
        'query': query,
        'position': position,
        'version': version,
        'rarity': rarity,
        'card_type': cardType,
        'league': league,
        'club': club,
        'nation': nation,
        'min_rating': minRating,
        'max_rating': maxRating,
        'min_price': minPrice,
        'max_price': maxPrice,
        'platform': platform,
        'play_style': playStyle,
        'play_style_plus': playStylePlus,
        'role': role,
        'min_skill_moves': minSkillMoves,
        'min_weak_foot': minWeakFoot,
        'min_pace': minPace,
        'max_pace': maxPace,
        'min_shooting': minShooting,
        'max_shooting': maxShooting,
        'min_passing': minPassing,
        'max_passing': maxPassing,
        'min_dribbling': minDribbling,
        'max_dribbling': maxDribbling,
        'min_defending': minDefending,
        'max_defending': maxDefending,
        'min_physical': minPhysical,
        'max_physical': maxPhysical,
        'sort': sort.name,
      };

  factory PlayerFilter.fromJson(Map<String, dynamic> json) {
    int? asNullableInt(dynamic value) =>
        value == null ? null : int.tryParse(value.toString());
    PlayerSort parseSort(dynamic value) => PlayerSort.values.firstWhere(
          (e) => e.name == value,
          orElse: () => PlayerSort.ratingDesc,
        );

    return PlayerFilter(
      query: (json['query'] ?? '').toString(),
      position: json['position']?.toString(),
      version: json['version']?.toString(),
      rarity: json['rarity']?.toString(),
      cardType: json['card_type']?.toString(),
      league: json['league']?.toString(),
      club: json['club']?.toString(),
      nation: json['nation']?.toString(),
      minRating: asNullableInt(json['min_rating']) ?? 40,
      maxRating: asNullableInt(json['max_rating']) ?? 99,
      minPrice: asNullableInt(json['min_price']),
      maxPrice: asNullableInt(json['max_price']),
      platform: (json['platform'] ?? 'console').toString(),
      playStyle: json['play_style']?.toString(),
      playStylePlus: json['play_style_plus']?.toString(),
      role: json['role']?.toString(),
      minSkillMoves: asNullableInt(json['min_skill_moves']),
      minWeakFoot: asNullableInt(json['min_weak_foot']),
      minPace: asNullableInt(json['min_pace']),
      maxPace: asNullableInt(json['max_pace']),
      minShooting: asNullableInt(json['min_shooting']),
      maxShooting: asNullableInt(json['max_shooting']),
      minPassing: asNullableInt(json['min_passing']),
      maxPassing: asNullableInt(json['max_passing']),
      minDribbling: asNullableInt(json['min_dribbling']),
      maxDribbling: asNullableInt(json['max_dribbling']),
      minDefending: asNullableInt(json['min_defending']),
      maxDefending: asNullableInt(json['max_defending']),
      minPhysical: asNullableInt(json['min_physical']),
      maxPhysical: asNullableInt(json['max_physical']),
      sort: parseSort(json['sort']),
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
    add('play_style', filter.playStyle);
    add('play_style_plus', filter.playStylePlus);
    add('role', filter.role);
    add('min_skill_moves', filter.minSkillMoves);
    add('min_weak_foot', filter.minWeakFoot);
    add('min_pace', filter.minPace);
    add('max_pace', filter.maxPace);
    add('min_shooting', filter.minShooting);
    add('max_shooting', filter.maxShooting);
    add('min_passing', filter.minPassing);
    add('max_passing', filter.maxPassing);
    add('min_dribbling', filter.minDribbling);
    add('max_dribbling', filter.maxDribbling);
    add('min_defending', filter.minDefending);
    add('max_defending', filter.maxDefending);
    add('min_physical', filter.minPhysical);
    add('max_physical', filter.maxPhysical);

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
