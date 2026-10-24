import '../../core/network/fcbaz_api.dart';
import '../../core/network/live_fc27_catalog.dart';
import '../../core/network/public_fc_data.dart';
import '../evolutions/domain/evolution.dart';
import '../players/domain/player.dart';
import '../sbc/domain/sbc.dart';

const _persianDigits = '۰۱۲۳۴۵۶۷۸۹';

String _asciiDigits(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final index = _persianDigits.indexOf(String.fromCharCode(rune));
    buffer.write(index >= 0 ? '$index' : String.fromCharCode(rune));
  }
  return buffer.toString();
}

int? _countInTask(Map<String, dynamic> json) {
  for (final key in const ['name', 'title', 'nameFA', 'titleFA']) {
    final match = RegExp(
      r'\d[\d,]*',
    ).firstMatch(_asciiDigits((json[key] ?? '').toString()));
    if (match == null) continue;
    final value = int.tryParse(match.group(0)!.replaceAll(',', ''));
    if (value != null && value > 0) return value;
  }
  final match = RegExp(r'\d[\d,]*').firstMatch(
    _asciiDigits(
      (json['description'] ?? json['descriptionFA'] ?? '').toString(),
    ),
  );
  final value = match == null
      ? null
      : int.tryParse(match.group(0)!.replaceAll(',', ''));
  return value != null && value > 0 ? value : null;
}

String _objectiveId(Map<String, dynamic> json) {
  final explicit = (json['id'] ?? '').toString().trim();
  if (explicit.isNotEmpty) return explicit;
  final url = (json['url'] ?? '').toString().trim();
  if (url.isNotEmpty) {
    final segments = url.split('/').where((part) => part.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      final last = segments.last.split('?').first.trim();
      if (last.isNotEmpty) return last;
    }
  }
  final title = (json['name'] ?? json['title'] ?? '').toString();
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

String _taskId(Map<String, dynamic> json) {
  final explicit = (json['id'] ?? json['task_id'] ?? '').toString().trim();
  if (explicit.isNotEmpty) return explicit;
  final title = (json['nameFA'] ?? json['name'] ?? json['title'] ?? '')
      .toString()
      .trim();
  if (title.isNotEmpty) return title;
  final description = (json['description'] ?? '').toString().trim();
  return description;
}

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

    final titleFa =
        (json['titleFA'] ??
                json['nameFA'] ??
                json['title_fa'] ??
                json['name_fa'] ??
                '')
            .toString();
    final titleEn = (json['title'] ?? json['name'] ?? '').toString();
    final descFa = (json['descriptionFA'] ?? json['description_fa'] ?? '')
        .toString();
    final descEn = (json['description'] ?? '').toString();
    final rewardFa = (json['rewardFA'] ?? json['reward_fa'] ?? '').toString();
    final rewardEn = (json['reward'] ?? '').toString();

    final explicitTarget = asInt(
      json['target'] ?? json['required'] ?? json['count'],
    );
    return HomeObjectiveTask(
      id: _taskId(json),
      title: titleFa.isNotEmpty ? titleFa : titleEn,
      description: descFa.isNotEmpty ? descFa : descEn,
      target: explicitTarget > 0 ? explicitTarget : (_countInTask(json) ?? 0),
      reward: rewardFa.isNotEmpty ? rewardFa : rewardEn,
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
              .map(
                (e) => HomeObjectiveTask.fromJson(Map<String, dynamic>.from(e)),
              )
              .where((e) => e.title.isNotEmpty)
              .toList()
        : const <HomeObjectiveTask>[];

    final titleFa =
        (json['titleFA'] ??
                json['nameFA'] ??
                json['title_fa'] ??
                json['name_fa'] ??
                '')
            .toString();
    final titleEn = (json['title'] ?? json['name'] ?? '').toString();
    final descFa = (json['descriptionFA'] ?? json['description_fa'] ?? '')
        .toString();
    final descEn = (json['description'] ?? '').toString();
    final rewardFa = (json['rewardFA'] ?? json['reward_fa'] ?? '').toString();
    final rewardEn = (json['reward'] ?? '').toString();

    return HomeObjective(
      id: _objectiveId(json),
      title: titleFa.isNotEmpty ? titleFa : titleEn,
      description: descFa.isNotEmpty ? descFa : descEn,
      reward: rewardFa.isNotEmpty ? rewardFa : rewardEn,
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()),
      taskCount: asInt(json['task_count'] ?? tasks.length),
      category: (json['category'] ?? json['group'] ?? json['type'] ?? '')
          .toString(),
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
  }) : api = api ?? FCBazApi(),
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
      liveGeneratedAt: DateTime.tryParse(
        (live?['generated_at'] ?? '').toString(),
      ),
    );
  }

  bool _isVerifiedMarketMover(Map<String, dynamic> item) {
    final source = (item['source_url'] ?? item['source'] ?? '').toString();
    final hasPrice = item['price'] != null || item['current'] != null;
    final hasMovement =
        item['change_percent'] != null ||
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
      trendingPlayers: maps(
        data['trending_players'],
      ).map(Player.fromJson).where((e) => e.id.isNotEmpty).toList(),
      marketMovers: maps(
        data['market_movers'],
      ).where(_isVerifiedMarketMover).toList(),
      sbcs: maps(
        data['sbcs'],
      ).map(SbcChallenge.fromJson).where((e) => e.id.isNotEmpty).toList(),
      evolutions: maps(
        data['evolutions'],
      ).map(Evolution.fromJson).where((e) => e.id.isNotEmpty).toList(),
      objectives: maps(
        data['objectives'],
      ).map(HomeObjective.fromJson).where((e) => e.title.isNotEmpty).toList(),
    );
  }

  Future<List<HomeObjective>> getObjectives({bool forceRefresh = false}) async {
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
