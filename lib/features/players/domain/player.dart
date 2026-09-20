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
      name: asString(
        json['name'] ??
            json['playername'] ??
            json['common_name'],
      ),
      rating: asInt(json['rating'] ?? json['overall']),
      position: asString(json['position']),
      positions: (() {
        final value = json['positions'] ??
            json['alternative_positions'] ??
            json['pos_all'];
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
      leagueName: asString(json['league_name'] ?? json['league']),
      nationName: asString(json['nation_name'] ?? json['nation']),
      version: asString(json['version'] ?? json['rarity']),
      imageUrl: asString(json['image_url'] ?? json['image']),
      cardImageUrl: asString(json['card_image_url'] ?? json['card_image']),
      pace: asInt(json['pace'] ?? json['pac']),
      shooting: asInt(json['shooting'] ?? json['sho']),
      passing: asInt(json['passing'] ?? json['pas']),
      dribbling: asInt(json['dribbling'] ?? json['dri']),
      defending: asInt(json['defending'] ?? json['def']),
      physical: asInt(json['physical'] ?? json['phy']),
      skillMoves: asInt(json['skill_moves']),
      weakFoot: asInt(json['weak_foot']),
      playStyles: asStrings(json['playstyles'] ?? json['play_styles']),
      playStylesPlus: asStrings(
        json['playstyles_plus'] ?? json['play_styles_plus'],
      ),
      roles: asStrings(json['roles'] ?? json['player_roles']),
      inGameStats: asStats(
        json['in_game_stats'] ?? json['detailed_stats'] ?? json['attributes'],
      ),
      traits: asStrings(json['traits']),
      foot: asString(json['foot'] ?? json['preferred_foot']),
      height: asString(json['height']),
      workRates: asString(json['work_rates'] ?? json['workrates']),
      rarity: asString(json['rarity'] ?? json['raretype']),
      cardType: asString(json['card_type'] ?? json['type']),
      pricePs: asInt(
        json['price_ps'] ??
            json['price_ps_coins'] ??
            json['ps_LCPrice'],
      ),
      pricePc: asInt(
        json['price_pc'] ??
            json['price_pc_coins'] ??
            json['pc_LCPrice'],
      ),
    );
  }
}
