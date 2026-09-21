import '../../../core/network/fcbaz_api.dart';
import '../../../core/network/free_github_content.dart';
import '../../../core/network/public_fc_data.dart';
import '../../players/domain/player.dart';

class MetaRepository {
  MetaRepository({
    FCBazApi? api,
    PublicFcData? publicData,
    FreeGithubContent? freeContent,
  })  : api = api ?? FCBazApi(),
        publicData = publicData ?? PublicFcData(),
        freeContent = freeContent ?? FreeGithubContent();

  final FCBazApi api;
  final PublicFcData publicData;
  final FreeGithubContent freeContent;

  Future<List<Map<String, dynamic>>> getBestPlayers({
    String? position,
  }) async {
    try {
      final suffix = position == null || position.isEmpty
          ? ''
          : '?position=' + Uri.encodeQueryComponent(position);
      final json = await api.getJson('/api/v1/meta/players' + suffix);
      final raw =
          json is Map ? (json['data'] ?? json['items'] ?? const []) : json;
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
    return players.take(30).map(_playerMap).toList();
  }

  Future<List<Map<String, dynamic>>> getNews() async {
    return freeContent.news();
  }

  /// Free GitHub scout lists (EAFC26-DataHub) mapped onto the local catalog.
  Future<List<Player>> getScoutHighlight({
    String listId = 'fastest',
    int limit = 24,
  }) async {
    final lists = await freeContent.scoutLists();
    Map<String, dynamic>? selected;
    for (final item in lists) {
      if ((item['id'] ?? '').toString() == listId) {
        selected = item;
        break;
      }
    }
    selected ??= lists.isEmpty ? null : lists.first;
    if (selected == null) return const [];

    final url = (selected['url'] ?? '').toString();
    if (url.isEmpty) return const [];

    final rows = await freeContent.fetchScoutList(url);
    if (rows.isEmpty) return const [];

    final wanted = <String>[];
    final seen = <String>{};
    for (final row in rows) {
      final id = (row['player_id'] ?? row['id'] ?? '').toString();
      if (id.isEmpty || !seen.add(id)) continue;
      wanted.add(id);
      if (wanted.length >= limit * 3) break;
    }
    if (wanted.isEmpty) return const [];

    return publicData.getPlayersByIds(wanted, limit: limit);
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
            ? 'live-market'
            : 'fc26-free-catalog',
      };
}
