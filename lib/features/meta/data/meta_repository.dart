import '../../../core/network/fcbaz_api.dart';

class MetaRepository {
  MetaRepository({FCBazApi? api}) : api = api ?? FCBazApi();

  final FCBazApi api;

  Future<List<Map<String, dynamic>>> getBestPlayers({String? position}) async {
    final suffix = position == null
        ? ''
        : '?position=' + Uri.encodeQueryComponent(position);
    final json = await api.getJson('/api/v1/meta/players' + suffix);
    final raw = json is Map ? (json['data'] ?? json['items'] ?? const []) : json;
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getNews() async {
    final json = await api.getJson('/api/v1/news?game_year=27');
    final raw = json is Map ? (json['data'] ?? json['items'] ?? const []) : json;
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
