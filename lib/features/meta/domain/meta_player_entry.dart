import '../../players/domain/player.dart';

enum MetaDataSource { backendMeta, publicHighestRated }

class MetaPlayerEntry {
  const MetaPlayerEntry({
    required this.player,
    required this.source,
    this.rank,
    this.tier = '',
    this.reason = '',
    this.role = '',
    this.score,
  });

  final Player player;
  final MetaDataSource source;
  final int? rank;
  final String tier;
  final String reason;
  final String role;
  final double? score;

  bool get isVerifiedMeta => source == MetaDataSource.backendMeta;

  factory MetaPlayerEntry.fromBackend(Map<String, dynamic> json) {
    int? asNullableInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    }

    double? asNullableDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '');
    }

    final rawPlayer = json['player'];
    final playerMap = rawPlayer is Map
        ? Map<String, dynamic>.from(rawPlayer)
        : Map<String, dynamic>.from(json);

    return MetaPlayerEntry(
      player: Player.fromJson(playerMap),
      source: MetaDataSource.backendMeta,
      rank: asNullableInt(json['rank'] ?? json['position_rank']),
      tier: (json['tier'] ?? '').toString(),
      reason: (json['reason'] ?? json['meta_reason'] ?? '').toString(),
      role: (json['role'] ?? json['best_role'] ?? '').toString(),
      score: asNullableDouble(json['score'] ?? json['meta_score']),
    );
  }

  factory MetaPlayerEntry.fromPublic(Player player) => MetaPlayerEntry(
        player: player,
        source: MetaDataSource.publicHighestRated,
      );
}
