import '../../../core/network/fcbaz_api.dart';
import '../../../core/network/public_fc_data.dart';
import '../../players/domain/player.dart';

class MetaRepository {
  MetaRepository({
    FCBazApi? api,
    PublicFcData? publicData,
  })  : api = api ?? FCBazApi(),
        publicData = publicData ?? PublicFcData();

  final FCBazApi api;
  final PublicFcData publicData;

  Future<List<Map<String, dynamic>>> getBestPlayers({
    String? position,
  }) async {
    try {
      final suffix = position == null || position.isEmpty
          ? ''
          : '?position=' + Uri.encodeQueryComponent(position);
      final json = await api.getJson('/api/v1/meta/players' + suffix);
      final raw = json is Map ? (json['data'] ?? json['items'] ?? const []) : json;
      if (raw is List) {
        final items = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    final params = <String, String>{
      'page': '1',
      'platform': 'console',
      'sort': 'rating_desc',
      'min_rating': '70',
      'max_rating': '99',
    };
    if (position != null && position.isNotEmpty) {
      params['position'] = position;
    }

    final players = await publicData.getFiltered(params: params);
    return players
        .take(30)
        .map((p) => _playerMap(p))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getNews() async {
    return const [];
  }

  Map<String, dynamic> _playerMap(Player p) => {
        'id': p.id,
        'player_id': p.id,
        'name': p.name,
        'rating': p.rating,
        'position': p.position,
        'club_name': p.clubName,
        'league_name': p.leagueName,
        'nation_name': p.nationName,
        'pace': p.pace,
        'shooting': p.shooting,
        'passing': p.passing,
        'dribbling': p.dribbling,
        'defending': p.defending,
        'physical': p.physical,
        'price_ps': p.pricePs,
        'price_pc': p.pricePc,
        'source': p.pricePs > 0 || p.pricePc > 0
            ? 'futbin-public'
            : 'fc26-free-catalog',
      };
}
