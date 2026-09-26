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
    if (api.isConfigured) {
      try {
        final owned = ownedPlayerIds.isEmpty
            ? ''
            : '&owned_ids=' + Uri.encodeQueryComponent(ownedPlayerIds.join(','));
        final json = await api.getJson(
          '/api/v1/sbc/' + Uri.encodeComponent(id) + '/solution?mode=cheapest' + owned,
        );
        final raw = json is Map ? (json['data'] ?? json) : json;
        if (raw is Map) {
          final parsed = SbcSolution.fromJson(Map<String, dynamic>.from(raw));
          if (parsed.players.isNotEmpty || parsed.notes.isNotEmpty || parsed.totalCost > 0) {
            return parsed;
          }
        }
      } catch (_) {}
    }

    final items = await liveCatalog.list('sbcs');
    for (final item in items) {
      if ((item['id'] ?? '').toString() != id) continue;

      final rawPublic = item['public_solution'];
      if (rawPublic is Map) {
        final map = Map<String, dynamic>.from(rawPublic);
        map['owned_player_ids'] = ownedPlayerIds.toList();
        final parsed = SbcSolution.fromJson(map);
        if (parsed.notes.isNotEmpty || parsed.totalCost > 0 || parsed.itemScore != null) {
          return parsed;
        }
      }

      final challenge = SbcChallenge.fromJson(item);
      final notes = <String>[
        ...challenge.guideFa,
        if (challenge.guideFa.isEmpty) ...challenge.requirements,
      ];
      if (notes.isNotEmpty || challenge.estimatedCost != null || challenge.itemScore != null) {
        return SbcSolution(
          totalCost: challenge.estimatedCost ?? 0,
          remainingCost: challenge.estimatedCost ?? 0,
          playerIds: const [],
          players: const [],
          ownedPlayerIds: ownedPlayerIds.toList(),
          notes: notes,
          itemScore: challenge.itemScore,
        );
      }
      break;
    }

    throw const FCBazApiException(
      'برای این SBC هنوز راه‌حل عمومی قابل اتکا پیدا نشده است؛ داده ساختگی نمایش داده نمی‌شود.',
    );
  }
}
