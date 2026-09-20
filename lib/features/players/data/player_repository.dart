import '../../../core/network/fcbaz_api.dart';
import '../domain/player.dart';

enum PlayerSort { ratingDesc, ratingAsc, pace, shooting, passing, dribbling, defending, physical }

class PlayerFilter {
  const PlayerFilter({
    this.position,
    this.minRating = 40,
    this.maxRating = 99,
    this.sort = PlayerSort.ratingDesc,
  });

  final String? position;
  final int minRating;
  final int maxRating;
  final PlayerSort sort;
}

class PlayerRepository {
  PlayerRepository({FCBazApi? api}) : api = api ?? FCBazApi();

  final FCBazApi api;

  Future<List<Player>> getPlayers() => api.fetchPlayers();
  Future<List<Player>> search(String query) => api.searchPlayers(query);
  Future<Player> getPlayer(String id) => api.fetchPlayer(id);

  Future<List<Player>> getVersions(String id) async {
    final json = await api.getJson(
      '/api/v1/players/' + Uri.encodeComponent(id) + '/versions',
    );
    final raw = json is Map ? (json['data'] ?? json['players'] ?? const []) : json;
    if (raw is! List) {
      throw const FCBazApiException('نسخه‌های دیگر بازیکن معتبر نیست.');
    }
    return raw
        .whereType<Map>()
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();
  }

  List<Player> applyFilter(List<Player> source, PlayerFilter filter) {
    final result = source.where((p) {
      final positionOk = filter.position == null ||
          p.position == filter.position ||
          p.positions.contains(filter.position);
      return positionOk &&
          p.rating >= filter.minRating &&
          p.rating <= filter.maxRating;
    }).toList();

    int compare(Player a, Player b) {
      switch (filter.sort) {
        case PlayerSort.ratingDesc: return b.rating.compareTo(a.rating);
        case PlayerSort.ratingAsc: return a.rating.compareTo(b.rating);
        case PlayerSort.pace: return b.pace.compareTo(a.pace);
        case PlayerSort.shooting: return b.shooting.compareTo(a.shooting);
        case PlayerSort.passing: return b.passing.compareTo(a.passing);
        case PlayerSort.dribbling: return b.dribbling.compareTo(a.dribbling);
        case PlayerSort.defending: return b.defending.compareTo(a.defending);
        case PlayerSort.physical: return b.physical.compareTo(a.physical);
      }
    }

    result.sort(compare);
    return result;
  }
}
