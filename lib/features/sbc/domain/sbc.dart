class SbcChallenge {
  const SbcChallenge({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.titleFa,
    required this.category,
    required this.description,
    required this.reward,
    required this.requirements,
    required this.repeatable,
    required this.expiresAt,
    required this.estimatedCost,
    required this.itemScore,
    required this.guideFa,
  });

  final String id;
  final String title;
  final String titleEn;
  final String titleFa;
  final String category;
  final String description;
  final String reward;
  final List<String> requirements;
  final bool repeatable;
  final DateTime? expiresAt;
  final int? estimatedCost;
  final int? itemScore;
  final List<String> guideFa;

  String get primaryTitle => titleFa.isNotEmpty ? titleFa : titleEn;
  String get secondaryTitle =>
      titleFa.isNotEmpty && titleEn.isNotEmpty && titleFa != titleEn
          ? titleEn
          : '';

  factory SbcChallenge.fromJson(Map<String, dynamic> json) {
    int? asNullableInt(dynamic value) =>
        value == null ? null : (value is int ? value : int.tryParse(value.toString()));

    List<String> asStrings(dynamic value) =>
        value is List ? value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() : const [];

    final rawTitle = (json['title'] ?? json['name'] ?? '').toString();
    final titleEn = (json['title_en'] ?? json['name_en'] ?? rawTitle).toString();
    final titleFa = (json['title_fa'] ?? json['name_fa'] ?? '').toString();
    final displayTitle = titleFa.isNotEmpty && titleEn.isNotEmpty && titleFa != titleEn
        ? '$titleFa • $titleEn'
        : (titleFa.isNotEmpty ? titleFa : titleEn);

    return SbcChallenge(
      id: (json['id'] ?? '').toString(),
      title: displayTitle,
      titleEn: titleEn,
      titleFa: titleFa,
      category: (json['category'] ?? 'SBC').toString(),
      description: (json['description_fa'] ?? json['description'] ?? '').toString(),
      reward: (json['reward_fa'] ?? json['reward'] ?? json['rewards'] ?? '').toString(),
      requirements: asStrings(json['requirements_fa'] ?? json['requirements']),
      repeatable: json['repeatable'] == true,
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()),
      estimatedCost: asNullableInt(json['estimated_cost'] ?? json['cost']),
      itemScore: asNullableInt(json['item_score'] ?? json['required_item_score']),
      guideFa: asStrings(json['guide_fa'] ?? json['persian_guide']),
    );
  }
}

class SbcSolutionPlayer {
  const SbcSolutionPlayer({
    required this.playerId,
    required this.name,
    required this.rating,
    required this.price,
  });

  final String playerId;
  final String name;
  final int rating;
  final int price;

  factory SbcSolutionPlayer.fromJson(Map<String, dynamic> json) =>
      SbcSolutionPlayer(
        playerId: (json['player_id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        rating: json['rating'] is int
            ? json['rating'] as int
            : int.tryParse((json['rating'] ?? '0').toString()) ?? 0,
        price: json['price'] is int
            ? json['price'] as int
            : int.tryParse((json['price'] ?? '0').toString()) ?? 0,
      );
}

class SbcSolution {
  const SbcSolution({
    required this.totalCost,
    required this.remainingCost,
    required this.playerIds,
    required this.players,
    required this.ownedPlayerIds,
    required this.notes,
    required this.itemScore,
  });

  final int totalCost;
  final int remainingCost;
  final List<String> playerIds;
  final List<SbcSolutionPlayer> players;
  final List<String> ownedPlayerIds;
  final List<String> notes;
  final int? itemScore;

  factory SbcSolution.fromJson(Map<String, dynamic> json) {
    final ids = json['player_ids'] ?? const [];
    final playersRaw = json['players'] ?? const [];
    final ownedRaw = json['owned_player_ids'] ?? const [];

    return SbcSolution(
      totalCost: json['total_cost'] is int
          ? json['total_cost'] as int
          : int.tryParse((json['total_cost'] ?? '0').toString()) ?? 0,
      remainingCost: json['remaining_cost'] is int
          ? json['remaining_cost'] as int
          : int.tryParse((json['remaining_cost'] ?? '0').toString()) ?? 0,
      playerIds: ids is List ? ids.map((e) => e.toString()).toList() : const [],
      players: playersRaw is List
          ? playersRaw
              .whereType<Map>()
              .map((e) => SbcSolutionPlayer.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      ownedPlayerIds:
          ownedRaw is List ? ownedRaw.map((e) => e.toString()).toList() : const [],
      notes: json['notes'] is List
          ? (json['notes'] as List).map((e) => e.toString()).toList()
          : const [],
      itemScore: json['item_score'] is int
          ? json['item_score'] as int
          : int.tryParse((json['item_score'] ?? '').toString()),
    );
  }
}
