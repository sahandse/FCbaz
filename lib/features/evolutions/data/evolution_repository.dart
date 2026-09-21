import '../../../core/network/fcbaz_api.dart';
import '../../../core/network/free_github_content.dart';
import '../domain/evolution.dart';

class EvolutionRepository {
  EvolutionRepository({
    FCBazApi? api,
    FreeGithubContent? freeContent,
  })  : api = api ?? FCBazApi(),
        freeContent = freeContent ?? FreeGithubContent();

  final FCBazApi api;
  final FreeGithubContent freeContent;

  Future<List<Evolution>> getActive() async {
    try {
      final json = await api.getJson(
        '/api/v1/evolutions?status=active&game_year=26',
      );
      final raw =
          json is Map ? (json['data'] ?? json['items'] ?? const []) : json;

      if (raw is List) {
        final items = raw
            .whereType<Map>()
            .map((e) => Evolution.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
            .toList();
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    final free = await freeContent.evolutions();
    return free
        .map(Evolution.fromJson)
        .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
        .toList();
  }
}
