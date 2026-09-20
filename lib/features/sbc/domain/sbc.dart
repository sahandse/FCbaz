class SbcChallenge {
  const SbcChallenge({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.reward,
    required this.requirements,
    required this.repeatable,
    required this.expiresAt,
    required this.estimatedCost,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final String reward;
  final List<String> requirements;
  final bool repeatable;
  final DateTime? expiresAt;
  final int? estimatedCost;

  factory SbcChallenge.fromJson(Map<String, dynamic> json) {
    int? asNullableInt(dynamic value) =>
        value == null ? null : (value is int ? value : int.tryParse(value.toString()));

    return SbcChallenge(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      category: (json['category'] ?? 'SBC').toString(),
      description: (json['description'] ?? '').toString(),
      reward: (json['reward'] ?? json['rewards'] ?? '').toString(),
      requirements: (json['requirements'] is List)
          ? (json['requirements'] as List).map((e) => e.toString()).toList()
          : const [],
      repeatable: json['repeatable'] == true,
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()),
      estimatedCost: asNullableInt(json['estimated_cost'] ?? json['cost']),
    );
  }
}

class SbcSolution {
  const SbcSolution({
    required this.totalCost,
    required this.playerIds,
    required this.notes,
  });

  final int totalCost;
  final List<String> playerIds;
  final List<String> notes;

  factory SbcSolution.fromJson(Map<String, dynamic> json) {
    final raw = json['player_ids'] ?? json['players'] ?? const [];
    return SbcSolution(
      totalCost: json['total_cost'] is int
          ? json['total_cost'] as int
          : int.tryParse((json['total_cost'] ?? '0').toString()) ?? 0,
      playerIds: raw is List ? raw.map((e) => e.toString()).toList() : const [],
      notes: json['notes'] is List
          ? (json['notes'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }
}
