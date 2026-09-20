import '../../core/network/fcbaz_api.dart';
import '../../core/network/public_fc_data.dart';
import '../evolutions/domain/evolution.dart';
import '../players/domain/player.dart';
import '../sbc/domain/sbc.dart';

class HomeObjective {
  const HomeObjective({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.expiresAt,
    required this.taskCount,
  });

  final String id;
  final String title;
  final String description;
  final String reward;
  final DateTime? expiresAt;
  final int taskCount;

  factory HomeObjective.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is int ? value : int.tryParse((value ?? '0').toString()) ?? 0;

    return HomeObjective(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      reward: (json['reward'] ?? '').toString(),
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()),
      taskCount: asInt(json['task_count']),
    );
  }
}

class HomeFeed {
  const HomeFeed({
    required this.trendingPlayers,
    required this.marketMovers,
    required this.sbcs,
    required this.evolutions,
    required this.objectives,
  });

  final List<Player> trendingPlayers;
  final List<Map<String, dynamic>> marketMovers;
  final List<SbcChallenge> sbcs;
  final List<Evolution> evolutions;
  final List<HomeObjective> objectives;
}

class HomeRepository {
  HomeRepository({
    FCBazApi? api,
    PublicFcData? publicData,
  })  : api = api ?? FCBazApi(),
        publicData = publicData ?? PublicFcData();

  final FCBazApi api;
  final PublicFcData publicData;

  Future<HomeFeed> getFeed({bool forceRefresh = false}) async {
    try {
      final json = await api.getJson(
        '/api/v1/home',
        forceRefresh: forceRefresh,
        cacheTtl: const Duration(seconds: 60),
      );
      final data = json is Map && json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const <String, dynamic>{};

      List<Map<String, dynamic>> maps(dynamic value) => value is List
          ? value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [];

      final feed = HomeFeed(
        trendingPlayers: maps(data['trending_players'])
            .map(Player.fromJson)
            .where((e) => e.id.isNotEmpty)
            .toList(),
        marketMovers: maps(data['market_movers']),
        sbcs: maps(data['sbcs'])
            .map(SbcChallenge.fromJson)
            .where((e) => e.id.isNotEmpty)
            .toList(),
        evolutions: maps(data['evolutions'])
            .map(Evolution.fromJson)
            .where((e) => e.id.isNotEmpty)
            .toList(),
        objectives: maps(data['objectives'])
            .map(HomeObjective.fromJson)
            .where((e) => e.title.isNotEmpty)
            .toList(),
      );

      if (feed.trendingPlayers.isNotEmpty || feed.marketMovers.isNotEmpty) {
        return feed;
      }
    } catch (_) {}

    final trending = await publicData.getTrending();
    final movers = trending
        .take(10)
        .map((p) => {
              'player_id': p.id,
              'id': p.id,
              'name': p.name,
              'rating': p.rating,
              'price_ps': p.pricePs,
              'price_pc': p.pricePc,
              'source': p.version == 'FIFA World Cup 2026'
                  ? 'github-fifa-wc2026'
                  : 'futbin-public',
            })
        .toList();

    return HomeFeed(
      trendingPlayers: trending.take(10).toList(),
      marketMovers: movers,
      sbcs: const [],
      evolutions: const [],
      objectives: const [],
    );
  }

  Future<List<HomeObjective>> getObjectives({
    bool forceRefresh = false,
  }) async {
    try {
      final json = await api.getJson(
        '/api/v1/objectives',
        forceRefresh: forceRefresh,
        cacheTtl: const Duration(seconds: 90),
      );
      final raw = json is Map ? (json['data'] ?? const []) : json;
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => HomeObjective.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .where((e) => e.title.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    return const [];
  }
}