import '../../../core/network/fcbaz_api.dart';
import '../../../core/network/live_fc27_catalog.dart';
import '../domain/evolution.dart';

class EvolutionRepository {
  EvolutionRepository({
    FCBazApi? api,
    LiveFc27Catalog? liveCatalog,
  })  : api = api ?? FCBazApi(),
        liveCatalog = liveCatalog ?? LiveFc27Catalog();

  final FCBazApi api;
  final LiveFc27Catalog liveCatalog;

  Future<List<Evolution>> getActive({bool forceRefresh = false}) async {
    if (api.isConfigured) {
      try {
        final json = await api.getJson(
          '/api/v1/evolutions?status=active&game_year=27',
          forceRefresh: forceRefresh,
          cacheTtl: const Duration(minutes: 2),
        );
        final raw = json is Map ? (json['data'] ?? json['items'] ?? const []) : json;
        if (raw is List) {
          final items = raw
              .whereType<Map>()
              .map((e) => Evolution.fromJson(Map<String, dynamic>.from(e)))
              .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
              .toList();
          if (items.isNotEmpty) return items;
        }
      } catch (_) {
        // Fall through to the verified public snapshot.
      }
    }

    final raw = await liveCatalog.list(
      'evolutions',
      forceRefresh: forceRefresh,
    );
    return raw
        .map(Evolution.fromJson)
        .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
        .toList();
  }
}
