class Player {
  const Player({
    required this.id,
    required this.name,
    required this.rating,
    required this.position,
    required this.positions,
    required this.clubName,
    required this.leagueName,
    required this.nationName,
    required this.version,
    required this.imageUrl,
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.defending,
    required this.physical,
    required this.skillMoves,
    required this.weakFoot,
    this.cardImageUrl = '',
    this.cardArtUrl = '',
    this.playStyles = const [],
    this.playStylesPlus = const [],
    this.roles = const [],
    this.inGameStats = const {},
    this.traits = const [],
    this.foot = '',
    this.height = '',
    this.workRates = '',
    this.rarity = '',
    this.cardType = '',
    this.pricePs = 0,
    this.pricePc = 0,
  });

  final String id;
  final String name;
  final int rating;
  final String position;
  final List<String> positions;
  final String clubName;
  final String leagueName;
  final String nationName;
  final String version;
  final String imageUrl;
  final String cardImageUrl;

  /// Full-item artwork (rating, stats and frame baked in) published by FUT.GG
  /// for cards EA does not expose in its public ratings roster, such as the
  /// Hall of FUT items.
  final String cardArtUrl;
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defending;
  final int physical;
  final int skillMoves;
  final int weakFoot;
  final List<String> playStyles;
  final List<String> playStylesPlus;
  final List<String> roles;
  final Map<String, int> inGameStats;
  final List<String> traits;
  final String foot;
  final String height;
  final String workRates;
  final String rarity;
  final String cardType;
  final int pricePs;
  final int pricePc;

  static const _eaPortraitBase =
      'https://ratings-images-prod.pulse.ea.com/FC25/full/player-portraits/';

  /// EA serves a 512px official ratings portrait, while the FC27 hub snapshot
  /// is 160px. Use the sharp one on large cards and keep [imageUrl] as fallback.
  String get highResImageUrl {
    if (imageUrl.contains('ratings-images-prod.pulse.ea.com')) return imageUrl;
    final trimmed = id.trim();
    if (RegExp(r'^\d{4,}$').hasMatch(trimmed)) {
      return '${_eaPortraitBase}p$trimmed.png?padding=0.7';
    }
    return imageUrl;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rating': rating,
    'position': position,
    'positions': positions,
    'club_name': clubName,
    'league_name': leagueName,
    'nation_name': nationName,
    'version': version,
    'image_url': imageUrl,
    'card_image_url': cardImageUrl,
    'card_art_url': cardArtUrl,
    'pace': pace,
    'shooting': shooting,
    'passing': passing,
    'dribbling': dribbling,
    'defending': defending,
    'physical': physical,
    'skill_moves': skillMoves,
    'weak_foot': weakFoot,
    'playstyles': playStyles,
    'playstyles_plus': playStylesPlus,
    'roles': roles,
    'in_game_stats': inGameStats,
    'traits': traits,
    'foot': foot,
    'height': height,
    'work_rates': workRates,
    'rarity': rarity,
    'card_type': cardType,
    'price_ps': pricePs,
    'price_pc': pricePc,
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

    int priceFor(String platform, List<String> keys) {
      for (final key in keys) {
        final value = asInt(json[key]);
        if (value > 0) return value;
      }
      final prices = json['prices'];
      if (prices is Map) {
        final raw = prices[platform] ?? prices[platform.toLowerCase()];
        if (raw is Map) {
          for (final key in const ['LCPrice', 'price', 'current', 'value']) {
            final value = asInt(raw[key]);
            if (value > 0) return value;
          }
        } else {
          final value = asInt(raw);
          if (value > 0) return value;
        }
      }
      final market = json['market_prices'] ?? json['marketPrices'];
      if (market is Map) {
        final raw = market[platform] ?? market[platform.toLowerCase()];
        if (raw is Map) {
          for (final key in const ['LCPrice', 'price', 'current', 'value']) {
            final value = asInt(raw[key]);
            if (value > 0) return value;
          }
        } else {
          final value = asInt(raw);
          if (value > 0) return value;
        }
      }
      return 0;
    }

    String asString(dynamic value) => value?.toString() ?? '';

    List<String> asStrings(dynamic value) {
      if (value is! List) return const [];
      return value
          .map((e) {
            if (e is Map) {
              return (e['name'] ?? e['title'] ?? e['label'] ?? '').toString();
            }
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }

    Map<String, int> asStats(dynamic value) {
      if (value is! Map) return const {};
      final out = <String, int>{};
      for (final entry in value.entries) {
        if (entry.value is Map) {
          for (final child in (entry.value as Map).entries) {
            final n = asInt(child.value);
            if (n > 0) out[child.key.toString()] = n;
          }
        } else {
          final n = asInt(entry.value);
          if (n > 0) out[entry.key.toString()] = n;
        }
      }
      return out;
    }

    return Player(
      id: asString(
        json['id'] ??
            json['ID'] ??
            json['player_id'] ??
            json['playerid'] ??
            json['resource_id'],
      ),
      name: asString(json['name'] ?? json['playername'] ?? json['common_name']),
      rating: asInt(
        json['rating'] ??
            json['overall'] ??
            json['overall_rating'] ??
            json['rat'],
      ),
      position: asString(json['position'] ?? json['pos']),
      positions: (() {
        final value =
            json['positions'] ??
            json['alternative_positions'] ??
            json['alternate_positions'] ??
            json['altPos'] ??
            json['pos_all'] ??
            json['pos'];
        if (value is String) {
          return value
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        return asStrings(value);
      })(),
      clubName: asString(json['club_name'] ?? json['club']),
      leagueName: asString(
        json['league_name'] ?? json['league'] ?? json['leagueFA'],
      ),
      nationName: asString(
        json['nation_name'] ??
            json['nation'] ??
            json['nationality'] ??
            json['nat'],
      ),
      version: asString(
        json['version'] ??
            json['rarity'] ??
            json['raretype'] ??
            json['card_type'] ??
            json['cardType'],
      ),
      imageUrl: asString(
        json['image_url'] ??
            json['imageUrl'] ??
            json['image'] ??
            json['portrait_url'] ??
            json['portraitUrl'] ??
            json['headshot_url'] ??
            json['headshot'] ??
            json['player_image'] ??
            json['playerImage'] ??
            json['face_url'],
      ),
      cardImageUrl: asString(
        json['card_image_url'] ??
            json['cardImageUrl'] ??
            json['card_image'] ??
            json['item_image_url'] ??
            json['itemImageUrl'],
      ),
      cardArtUrl: asString(
        json['card_art_url'] ?? json['cardArtUrl'] ?? json['futgg_card_url'],
      ),
      pace: asInt(
        json['pace'] ??
            json['pac'] ??
            (json['stats'] is Map ? (json['stats'] as Map)['PAC'] : null),
      ),
      shooting: asInt(
        json['shooting'] ??
            json['sho'] ??
            (json['stats'] is Map ? (json['stats'] as Map)['SHO'] : null),
      ),
      passing: asInt(
        json['passing'] ??
            json['pas'] ??
            (json['stats'] is Map ? (json['stats'] as Map)['PAS'] : null),
      ),
      dribbling: asInt(
        json['dribbling'] ??
            json['dri'] ??
            (json['stats'] is Map ? (json['stats'] as Map)['DRI'] : null),
      ),
      defending: asInt(
        json['defending'] ??
            json['def'] ??
            (json['stats'] is Map ? (json['stats'] as Map)['DEF'] : null),
      ),
      physical: asInt(
        json['physical'] ??
            json['physicality'] ??
            json['phy'] ??
            (json['stats'] is Map ? (json['stats'] as Map)['PHY'] : null),
      ),
      skillMoves: asInt(json['skill_moves'] ?? json['skillMoves']),
      weakFoot: asInt(json['weak_foot'] ?? json['weakFoot']),
      playStyles: asStrings(
        json['playstyles'] ?? json['play_styles'] ?? json['playStyles'],
      ),
      playStylesPlus: asStrings(
        json['playstyles_plus'] ??
            json['play_styles_plus'] ??
            json['playStylesPlus'],
      ),
      roles: asStrings(json['roles'] ?? json['player_roles']),
      inGameStats: asStats(
        json['in_game_stats'] ??
            json['inGameStats'] ??
            json['detailed_stats'] ??
            json['attributes'] ??
            json['stats'],
      ),
      traits: asStrings(json['traits']),
      foot: asString(
        json['foot'] ?? json['preferred_foot'] ?? json['preferredFoot'],
      ),
      height: asString(json['height']),
      workRates: asString(json['work_rates'] ?? json['workrates']),
      rarity: asString(json['rarity'] ?? json['raretype']),
      cardType: asString(json['card_type'] ?? json['cardType'] ?? json['type']),
      pricePs: priceFor('PS', const [
        'price_ps',
        'price_ps_coins',
        'ps_LCPrice',
        'psPrice',
        'playstation_price',
      ]),
      pricePc: priceFor('PC', const [
        'price_pc',
        'price_pc_coins',
        'pc_LCPrice',
        'pcPrice',
        'pc_price',
      ]),
    );
  }
}
