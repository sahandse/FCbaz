import '../../../core/network/fcbaz_api.dart';
import '../../../core/network/public_fc_data.dart';
import '../../players/domain/player.dart';
import '../domain/meta_player_entry.dart';

class MetaRepository {
  MetaRepository({
    FCBazApi? api,
    PublicFcData? publicData,
  })  : api = api ?? FCBazApi(),
        publicData = publicData ?? PublicFcData();

  final FCBazApi api;
  final PublicFcData publicData;

  Future<List<MetaPlayerEntry>> getBestPlayers({
    String? position,
    String? role,
    String platform = 'console',
  }) async {
    try {
      final query = <String, String>{};
      if (position != null && position.isNotEmpty) query['position'] = position;
      if (role != null && role.isNotEmpty) query['role'] = role;
      if (platform.isNotEmpty) query['platform'] = platform;

      final suffix = query.isEmpty
          ? ''
          : '?' + query.entries.map((e) =>
              Uri.encodeQueryComponent(e.key) + '=' + Uri.encodeQueryComponent(e.value)).join('&');

      final json = await api.getJson('/api/v1/meta/players' + suffix);
      final raw = json is Map ? (json['data'] ?? json['items'] ?? const []) : json;
      if (raw is List) {
        final items = raw
            .whereType<Map>()
            .map((e) => MetaPlayerEntry.fromBackend(Map<String, dynamic>.from(e)))
            .where((e) => e.player.id.isNotEmpty)
            .toList();
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    final params = <String, String>{
      'page': '1',
      'platform': platform,
      'sort': 'rating_desc',
      'min_rating': '70',
      'max_rating': '99',
    };
    if (position != null && position.isNotEmpty) {
      params['position'] = position;
    }

    final players = await publicData.getFiltered(params: params);
    final filtered = role == null || role.isEmpty
        ? players
        : players.where((p) => p.roles.any((r) => r.toLowerCase() == role.toLowerCase())).toList();

    return filtered.take(30).map(MetaPlayerEntry.fromPublic).toList();
  }

  Future<List<String>> getAvailableRoles({String? position}) async {
    final items = await getBestPlayers(position: position);
    final roles = <String>{};
    for (final item in items) {
      if (item.role.isNotEmpty) roles.add(item.role);
      roles.addAll(item.player.roles.where((e) => e.trim().isNotEmpty));
    }
    final out = roles.toList()..sort();
    return out;
  }

  Future<List<Map<String, dynamic>>> getNews() async {
    return const [];
  }
}
