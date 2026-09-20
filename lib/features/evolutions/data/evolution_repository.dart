import '../../../core/network/fcbaz_api.dart';
import '../domain/evolution.dart';

class EvolutionRepository {
  EvolutionRepository({FCBazApi? api}) : api = api ?? FCBazApi();
  final FCBazApi api;

  Future<List<Evolution>> getActive() async {
    final json = await api.getJson('/api/v1/evolutions?status=active&game_year=27');
    final raw = json is Map ? (json['data'] ?? json['items'] ?? const []) : json;
    if (raw is! List) {
      throw const FCBazApiException('پاسخ Evolutions معتبر نیست.');
    }
    return raw
        .whereType<Map>()
        .map((e) => Evolution.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> eligiblePlayers(String evolutionId) async {
    final json = await api.getJson(
      '/api/v1/evolutions/' + Uri.encodeComponent(evolutionId) + '/eligible-players',
    );
    final raw = json is Map ? (json['data'] ?? const []) : json;
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
