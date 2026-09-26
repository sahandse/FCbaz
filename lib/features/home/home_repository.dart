import '../../core/network/fcbaz_api.dart';
import '../../core/network/live_fc27_catalog.dart';
import '../../core/network/public_fc_data.dart';
import '../evolutions/domain/evolution.dart';
import '../players/domain/player.dart';
import '../sbc/domain/sbc.dart';

class HomeObjectiveTask {
  const HomeObjectiveTask({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.reward,
  });

  final String id;
  final String title;
  final String description;
  final int target;
  final String reward;

  factory HomeObjectiveTask.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is int ? value : int.tryParse((value ?? '0').toString()) ?? 0;

    return HomeObjectiveTask(
      id: (json['id'] ?? json['task_id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      target: asInt(json['target'] ?? json['required'] ?? json['count']),
      reward: (json['reward'] ?? '').toString(),
    );
  }
}

class HomeObjective {
  const HomeObjective({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.expiresAt,
    required this.taskCount,
    this.category = '',
    this.tasks = const [],
  });

  final String id;
  final String title;
  final String description;
  final String reward;
  final DateTime? expiresAt;
  final int taskCount;
  final String category;
  final List<HomeObjectiveTask> tasks;

  factory HomeObjective.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is int ? value : int.tryParse((value ?? '0').toString()) ?? 0;

    final rawTasks = json['tasks'] ?? json['objectives'] ?? const [];
    final tasks = rawTasks is List
        ? rawTasks
            .whereType<Map>()
            .map((e) => HomeObjectiveTask.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.title.isNotEmpty)
            .toList()
        : const <HomeObjectiveTask>[];

    return HomeObjective(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      reward: (json['reward'] ?? '').toString(),
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()),
      taskCount: asInt(json['task_count'] ?? tasks.length),
      category: (json['category'] ?? json['group'] ?? json['type'] ?? '').toString(),
      tasks: tasks,
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
    this.liveGeneratedAt,
  });

  final List<Player> trendingPlayers;
  final List<Map<String, dynamic>> marketMovers;
  final List<SbcChallenge> sbcs;
  final List<Evolution> evolutions;
  final List<HomeObjective> objectives;
  final DateTime? liveGeneratedAt;
}

class HomeRepository {
  HomeRepository({
    FCBazApi? api,
    PublicFcData? publicData,
    LiveFc27Catalog? liveCatalog,
  })  : api = api ?? FCBazApi(),
        publicData = publicData ?? PublicFcData(),
        liveCatalog = liveCatalog ?? LiveFc27Catalog();

  final FCBazApi api;
  final PublicFcData publicData;
  final LiveFc27Catalog liveCatalog;

  Future<HomeFeed> getFeed({bool forceRefresh = false}) async {
    HomeFeed? backendFeed;
    if (api.isConfigured) {
      try {
        final json = await api.getJson(
          '/api/v1/home',
          forceRefresh: forceRefresh,
          cacheTtl: const Duration(seconds: 60),
        );
        final data = json is Map && json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : const <String, dynamic>{};
        backendFeed = _fromMaps(data);
      } catch (_) {}
    }

    final trendingFuture = publicData.getTrending();
    Map<String, dynamic>? live;
    try {
      live = await liveCatalog.load(forceRefresh: forceRefresh);
    } catch (_) {}
    final trending = await trendingFuture;

    List<Map<String, dynamic>> maps(dynamic value) => value is List
        ? value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : const [];

    final liveSbcs = maps(live?['sbcs'])
        .map(SbcChallenge.fromJson)
        .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
        .toList();
    final liveEvos = maps(live?['evolutions'])
        .map(Evolution.fromJson)
        .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
        .toList();
    final liveObjectives = maps(live?['objectives'])
        .map(HomeObjective.fromJson)
        .where((e) => e.id.isNotEmpty && e.title.isNotEmpty)
        .toList();

    final preferredPlayers = backendFeed?.trendingPlayers.isNotEmpty == true
        ? backendFeed!.trendingPlayers
        : trending.take(12).toList();

    // Market Movers are only shown when a provider supplies an actual market
    // movement payload. Never manufacture a mover from an ordinary player row.
    final movers = backendFeed?.marketMovers.isNotEmpty == true
        ? backendFeed!.marketMovers
        : maps(live?['market_movers']).where(_isVerifiedMarketMover).toList();

    return HomeFeed(
      trendingPlayers: preferredPlayers,
      marketMovers: movers,
      sbcs: backendFeed?.sbcs.isNotEmpty == true ? backendFeed!.sbcs : liveSbcs,
      evolutions: backendFeed?.evolutions.isNotEmpty == true
          ? backendFeed!.evolutions
          : liveEvos,
      objectives: backendFeed?.objectives.isNotEmpty == true
          ? backendFeed!.objectives
          : liveObjectives,
      liveGeneratedAt: DateTime.tryParse((live?['generated_at'] ?? '').toString()),
    );
  }

  bool _isVerifiedMarketMover(Map<String, dynamic> item) {
    final source = (item['source_url'] ?? item['source'] ?? '').toString();
    final hasPrice = item['price'] != null || item['current'] != null;
    final hasMovement = item['change_percent'] != null ||
        item['change_24h_percent'] != null ||
        item['change'] != null;
    return source.startsWith('https://') && hasPrice && hasMovement;
  }

  HomeFeed _fromMaps(Map<String, dynamic> data) {
    List<Map<String, dynamic>> maps(dynamic value) => value is List
        ? value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : const [];

    return HomeFeed(
      trendingPlayers: maps(data['trending_players'])
          .map(Player.fromJson)
          .where((e) => e.id.isNotEmpty)
          .toList(),
      marketMovers: maps(data['market_movers']).where(_isVerifiedMarketMover).toList(),
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

  Future<List<HomeObjective>> getObjectives({
    bool forceRefresh = false,
  }) async {
    if (api.isConfigured) {
      try {
        final json = await api.getJson(
          '/api/v1/objectives',
          forceRefresh: forceRefresh,
          cacheTtl: const Duration(seconds: 90),
        );
        final raw = json is Map ? (json['data'] ?? const []) : json;
        if (raw is List) {
          final items = raw
              .whereType<Map>()
              .map((e) => HomeObjective.fromJson(Map<String, dynamic>.from(e)))
              .where((e) => e.title.isNotEmpty)
              .toList();
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    final raw = await liveCatalog.list(
      'objectives',
      forceRefresh: forceRefresh,
    );
    return raw
        .map(HomeObjective.fromJson)
        .where((e) => e.title.isNotEmpty)
        .toList();
  }
}
