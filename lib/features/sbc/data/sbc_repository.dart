import '../../../core/network/fcbaz_api.dart';
import '../../../core/network/live_fc27_catalog.dart';
import '../domain/sbc.dart';

class SbcRepository {
  SbcRepository({
    FCBazApi? api,
    LiveFc27Catalog? liveCatalog,
  })  : api = api ?? FCBazApi(),
        liveCatalog = liveCatalog ?? LiveFc27Catalog();

  final FCBazApi api;
  final LiveFc27Catalog liveCatalog;

  Future<List<SbcChallenge>> getActive({bool forceRefresh = false}) async {
    if (api.isConfigured) {
      try {
        final json = await api.getJson(
          '/api/v1/sbc?status=active&game_year=27',
          forceRefresh: forceRefresh,
          cacheTtl: const Duration(minutes: 2),
        );
        final raw = json is Map ? (json['data'] ?? json['items'] ?? const []) : json;
        if (raw is List) {
          final items = raw
              .whereType<Map>()
              .map((e) => SbcChallenge.fromJson(Map<String, dynamic>.from(e)))
              .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
              .toList();
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    final raw = await liveCatalog.list('sbcs', forceRefresh: forceRefresh);
    return raw
        .map(SbcChallenge.fromJson)
        .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
        .toList();
  }

  Future<SbcChallenge> getById(String id) async {
    if (api.isConfigured) {
      try {
        final json = await api.getJson('/api/v1/sbc/' + Uri.encodeComponent(id));
        final raw = json is Map ? (json['data'] ?? json) : json;
        if (raw is Map) {
          final item = SbcChallenge.fromJson(Map<String, dynamic>.from(raw));
          if (item.id.isNotEmpty) return item;
        }
      } catch (_) {}
    }

    final items = await getActive();
    for (final item in items) {
      if (item.id == id) return item;
    }
    throw const FCBazApiException('SBC موردنظر در منبع زنده پیدا نشد.');
  }

  Future<SbcSolution> getCheapestSolution(
    String id, {
    Set<String> ownedPlayerIds = const {},
  }) async {
    if (!api.isConfigured) {
      throw const FCBazApiException(
        'حل خودکار SBC فقط با Backend واقعی فعال می‌شود؛ داده ساختگی ساخته نمی‌شود.',
      );
    }

    final owned = ownedPlayerIds.isEmpty
        ? ''
        : '&owned_ids=' + Uri.encodeQueryComponent(ownedPlayerIds.join(','));
    final json = await api.getJson(
      '/api/v1/sbc/' + Uri.encodeComponent(id) + '/solution?mode=cheapest' + owned,
    );
    final raw = json is Map ? (json['data'] ?? json) : json;
    if (raw is! Map) {
      throw const FCBazApiException('راه‌حل SBC معتبر نیست.');
    }
    return SbcSolution.fromJson(Map<String, dynamic>.from(raw));
  }
}
