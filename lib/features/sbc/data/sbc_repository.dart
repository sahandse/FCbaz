import '../../../core/network/fcbaz_api.dart';
import '../../../core/network/free_github_content.dart';
import '../domain/sbc.dart';

class SbcRepository {
  SbcRepository({
    FCBazApi? api,
    FreeGithubContent? freeContent,
  })  : api = api ?? FCBazApi(),
        freeContent = freeContent ?? FreeGithubContent();

  final FCBazApi api;
  final FreeGithubContent freeContent;

  Future<List<SbcChallenge>> getActive() async {
    try {
      final json = await api.getJson('/api/v1/sbc?status=active&game_year=26');
      final raw =
          json is Map ? (json['data'] ?? json['items'] ?? const []) : json;
      if (raw is List) {
        final items = raw
            .whereType<Map>()
            .map((e) => SbcChallenge.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
            .toList();
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    final free = await freeContent.sbcs();
    return free
        .map(SbcChallenge.fromJson)
        .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
        .toList();
  }

  Future<SbcChallenge> getById(String id) async {
    try {
      final json = await api.getJson('/api/v1/sbc/' + Uri.encodeComponent(id));
      final raw = json is Map ? (json['data'] ?? json) : json;
      if (raw is Map) {
        return SbcChallenge.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {}

    final free = await freeContent.sbcs();
    for (final item in free) {
      if ((item['id'] ?? '').toString() == id) {
        return SbcChallenge.fromJson(item);
      }
    }
    throw const FCBazApiException('SBC پیدا نشد.');
  }

  Future<SbcSolution> getCheapestSolution(
    String id, {
    Set<String> ownedPlayerIds = const {},
  }) async {
    final owned = ownedPlayerIds.isEmpty
        ? ''
        : '&owned_ids=' +
            Uri.encodeQueryComponent(ownedPlayerIds.join(','));
    try {
      final json = await api.getJson(
        '/api/v1/sbc/' +
            Uri.encodeComponent(id) +
            '/solution?mode=cheapest' +
            owned,
      );
      final raw = json is Map ? (json['data'] ?? json) : json;
      if (raw is Map) {
        return SbcSolution.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {}

    throw const FCBazApiException(
      'راه‌حل زنده در دسترس نیست. از تب ترکیب ریتینگ و Fodder استفاده کنید.',
    );
  }
}
