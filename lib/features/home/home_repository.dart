import '../../core/network/fcbaz_api.dart';
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
  HomeRepository({FCBazApi? api}) : api = api ?? FCBazApi();
  final FCBazApi api;

  Future<HomeFeed> getFeed({bool forceRefresh = false}) async {
    final json = await api.getJson(
      '/api/v1/home',
      forceRefresh: forceRefresh,
      cacheTtl: const Duration(seconds: 60),
    );
    final data = json is Map && json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : const <String, dynamic>{};

    List<Map<String, dynamic>> maps(dynamic value) => value is List
        ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const [];

    return HomeFeed(
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
  }

  Future<List<HomeObjective>> getObjectives({bool forceRefresh = false}) async {
    final json = await api.getJson(
      '/api/v1/objectives',
      forceRefresh: forceRefresh,
      cacheTtl: const Duration(seconds: 90),
    );
    final raw = json is Map ? (json['data'] ?? const []) : json;
    if (raw is! List) {
      throw const FCBazApiException('پاسخ Objectives معتبر نیست.');
    }
    return raw
        .whereType<Map>()
        .map((e) => HomeObjective.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.title.isNotEmpty)
        .toList();
  }
}