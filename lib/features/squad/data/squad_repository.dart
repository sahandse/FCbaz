import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../players/domain/player.dart';
import '../domain/squad_models.dart';

class SquadRepository {
  static const _key = 'fcbaz_saved_squads';

  Future<List<SquadStateModel>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded.whereType<Map>().map((entry) {
        final map = Map<String, dynamic>.from(entry);
        final rawPlayers = map['players'];
        final players = <String, Player>{};

        if (rawPlayers is Map) {
          for (final item in rawPlayers.entries) {
            if (item.value is Map) {
              players[item.key.toString()] = Player.fromJson(
                Map<String, dynamic>.from(item.value as Map),
              );
            }
          }
        }

        return SquadStateModel(
          id: (map['id'] ?? '').toString(),
          name: (map['name'] ?? 'ترکیب من').toString(),
          formationId: (map['formation_id'] ?? '433').toString(),
          playersBySlot: players,
        );
      }).where((s) => s.id.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<SquadStateModel> squads) async {
    final prefs = await SharedPreferences.getInstance();
    final data = squads.map((squad) {
      return {
        'id': squad.id,
        'name': squad.name,
        'formation_id': squad.formationId,
        'players': squad.playersBySlot.map((slot, player) => MapEntry(slot, _playerToJson(player))),
      };
    }).toList();

    await prefs.setString(_key, jsonEncode(data));
  }

  Future<void> upsert(SquadStateModel squad) async {
    final all = [...await getAll()];
    final index = all.indexWhere((s) => s.id == squad.id);

    if (index >= 0) {
      all[index] = squad;
    } else {
      all.add(squad);
    }

    await saveAll(all);
  }

  Future<void> delete(String id) async {
    final all = [...await getAll()]..removeWhere((s) => s.id == id);
    await saveAll(all);
  }

  Map<String, dynamic> _playerToJson(Player p) => {
        'id': p.id,
        'name': p.name,
        'rating': p.rating,
        'position': p.position,
        'positions': p.positions,
        'club_name': p.clubName,
        'league_name': p.leagueName,
        'nation_name': p.nationName,
        'version': p.version,
        'image_url': p.imageUrl,
        'pace': p.pace,
        'shooting': p.shooting,
        'passing': p.passing,
        'dribbling': p.dribbling,
        'defending': p.defending,
        'physical': p.physical,
        'skill_moves': p.skillMoves,
        'weak_foot': p.weakFoot,
      };
}
