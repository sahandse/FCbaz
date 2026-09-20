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
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defending;
  final int physical;
  final int skillMoves;
  final int weakFoot;

  factory Player.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
    String asString(dynamic value) => value?.toString() ?? '';
    List<String> asStrings(dynamic value) => value is List
        ? value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const [];

    return Player(
      id: asString(json['id']),
      name: asString(json['name']),
      rating: asInt(json['rating'] ?? json['overall']),
      position: asString(json['position']),
      positions: asStrings(json['positions'] ?? json['alternative_positions']),
      clubName: asString(json['club_name'] ?? json['club']),
      leagueName: asString(json['league_name'] ?? json['league']),
      nationName: asString(json['nation_name'] ?? json['nation']),
      version: asString(json['version'] ?? json['rarity']),
      imageUrl: asString(json['image_url'] ?? json['image']),
      pace: asInt(json['pace']),
      shooting: asInt(json['shooting']),
      passing: asInt(json['passing']),
      dribbling: asInt(json['dribbling']),
      defending: asInt(json['defending']),
      physical: asInt(json['physical']),
      skillMoves: asInt(json['skill_moves']),
      weakFoot: asInt(json['weak_foot']),
    );
  }
}
