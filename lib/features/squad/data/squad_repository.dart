import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

      return decoded
          .whereType<Map>()
          .map((entry) => SquadStateModel.fromJson(
                Map<String, dynamic>.from(entry),
              ))
          .where((s) => s.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<SquadStateModel> squads) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(squads.map((e) => e.toJson()).toList()),
    );
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

  String exportSquad(SquadStateModel squad) => jsonEncode(squad.toJson());

  SquadStateModel importSquad(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('فایل ترکیب معتبر نیست.');
    }

    final squad = SquadStateModel.fromJson(
      Map<String, dynamic>.from(decoded),
    );

    if (squad.id.isEmpty || squad.playersBySlot.length > 11) {
      throw const FormatException('ساختار ترکیب معتبر نیست.');
    }

    return SquadStateModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: squad.name + ' (Import)',
      formationId: squad.formationId,
      playersBySlot: squad.playersBySlot,
      playerConfigs: squad.playerConfigs,
      bench: squad.bench.take(7).toList(),
      manager: squad.manager,
    );
  }
}
