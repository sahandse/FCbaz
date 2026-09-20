import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../players/domain/player.dart';

class MyClubItem {
  const MyClubItem({
    required this.playerId,
    required this.playerName,
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
    required this.acquisitionPrice,
    required this.untradeable,
  });

  final String playerId;
  final String playerName;
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
  final int acquisitionPrice;
  final bool untradeable;

  factory MyClubItem.fromPlayer(
    Player player, {
    required int acquisitionPrice,
    bool untradeable = false,
  }) {
    return MyClubItem(
      playerId: player.id,
      playerName: player.name,
      rating: player.rating,
      position: player.position,
      positions: player.positions,
      clubName: player.clubName,
      leagueName: player.leagueName,
      nationName: player.nationName,
      version: player.version,
      imageUrl: player.imageUrl,
      pace: player.pace,
      shooting: player.shooting,
      passing: player.passing,
      dribbling: player.dribbling,
      defending: player.defending,
      physical: player.physical,
      skillMoves: player.skillMoves,
      weakFoot: player.weakFoot,
      acquisitionPrice: acquisitionPrice,
      untradeable: untradeable,
    );
  }

  Player toPlayer() => Player(
        id: playerId,
        name: playerName,
        rating: rating,
        position: position,
        positions: positions,
        clubName: clubName,
        leagueName: leagueName,
        nationName: nationName,
        version: version,
        imageUrl: imageUrl,
        pace: pace,
        shooting: shooting,
        passing: passing,
        dribbling: dribbling,
        defending: defending,
        physical: physical,
        skillMoves: skillMoves,
        weakFoot: weakFoot,
      );

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'player_name': playerName,
        'rating': rating,
        'position': position,
        'positions': positions,
        'club_name': clubName,
        'league_name': leagueName,
        'nation_name': nationName,
        'version': version,
        'image_url': imageUrl,
        'pace': pace,
        'shooting': shooting,
        'passing': passing,
        'dribbling': dribbling,
        'defending': defending,
        'physical': physical,
        'skill_moves': skillMoves,
        'weak_foot': weakFoot,
        'acquisition_price': acquisitionPrice,
        'untradeable': untradeable,
      };

  factory MyClubItem.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is int ? value : int.tryParse((value ?? '0').toString()) ?? 0;
    List<String> asStrings(dynamic value) =>
        value is List ? value.map((e) => e.toString()).toList() : const [];

    return MyClubItem(
      playerId: (json['player_id'] ?? '').toString(),
      playerName: (json['player_name'] ?? '').toString(),
      rating: asInt(json['rating']),
      position: (json['position'] ?? '').toString(),
      positions: asStrings(json['positions']),
      clubName: (json['club_name'] ?? '').toString(),
      leagueName: (json['league_name'] ?? '').toString(),
      nationName: (json['nation_name'] ?? '').toString(),
      version: (json['version'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? '').toString(),
      pace: asInt(json['pace']),
      shooting: asInt(json['shooting']),
      passing: asInt(json['passing']),
      dribbling: asInt(json['dribbling']),
      defending: asInt(json['defending']),
      physical: asInt(json['physical']),
      skillMoves: asInt(json['skill_moves']),
      weakFoot: asInt(json['weak_foot']),
      acquisitionPrice: asInt(json['acquisition_price']),
      untradeable: json['untradeable'] == true,
    );
  }
}

class MyClubRepository {
  static const _key = 'fcbaz_my_club';

  Future<List<MyClubItem>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => MyClubItem.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.playerId.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Set<String>> getPlayerIds() async =>
      (await getAll()).map((e) => e.playerId).toSet();

  Future<void> upsert(MyClubItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = [...await getAll()];
    final index = items.indexWhere((e) => e.playerId == item.playerId);

    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }

    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> remove(String playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = [...await getAll()]..removeWhere((e) => e.playerId == playerId);
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
