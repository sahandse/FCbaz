import '../../../core/network/fcbaz_api.dart';
import '../domain/sbc.dart';

class SbcRepository {
  SbcRepository({FCBazApi? api}) : api = api ?? FCBazApi();

  final FCBazApi api;

  Future<List<SbcChallenge>> getActive() async {
    final json = await api.getJson('/api/v1/sbc?status=active&game_year=27');
    final raw = json is Map ? (json['data'] ?? json['items'] ?? const []) : json;
    if (raw is! List) {
      throw const FCBazApiException('پاسخ SBC معتبر نیست.');
    }
    return raw
        .whereType<Map>()
        .map((e) => SbcChallenge.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
        .toList();
  }

  Future<SbcChallenge> getById(String id) async {
    final json = await api.getJson('/api/v1/sbc/' + Uri.encodeComponent(id));
    final raw = json is Map ? (json['data'] ?? json) : json;
    if (raw is! Map) {
      throw const FCBazApiException('جزئیات SBC معتبر نیست.');
    }
    return SbcChallenge.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<SbcSolution> getCheapestSolution(
    String id, {
    Set<String> ownedPlayerIds = const {},
  }) async {
    final owned = ownedPlayerIds.isEmpty
        ? ''
        : '&owned_ids=' +
            Uri.encodeQueryComponent(ownedPlayerIds.join(','));
    final json = await api.getJson(
      '/api/v1/sbc/' +
          Uri.encodeComponent(id) +
          '/solution?mode=cheapest' +
          owned,
    );
    final raw = json is Map ? (json['data'] ?? json) : json;
    if (raw is! Map) {
      throw const FCBazApiException('راه‌حل SBC معتبر نیست.');
    }
    return SbcSolution.fromJson(Map<String, dynamic>.from(raw));
  }
}
