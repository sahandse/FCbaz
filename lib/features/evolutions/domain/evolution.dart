class EvolutionStep {
  const EvolutionStep({
    required this.title,
    required this.requirements,
    required this.upgrades,
  });

  final String title;
  final List<String> requirements;
  final List<String> upgrades;

  factory EvolutionStep.fromJson(Map<String, dynamic> json) {
    List<String> asStrings(dynamic value) =>
        value is List ? value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() : const [];

    return EvolutionStep(
      title: (json['title'] ?? json['name'] ?? '').toString(),
      requirements: asStrings(json['requirements']),
      upgrades: asStrings(json['upgrades']),
    );
  }
}

class Evolution {
  const Evolution({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.requirements,
    required this.upgrades,
    required this.expiresAt,
    required this.steps,
  });

  final String id;
  final String title;
  final String description;
  final int cost;
  final List<String> requirements;
  final List<String> upgrades;
  final DateTime? expiresAt;
  final List<EvolutionStep> steps;

  factory Evolution.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

    List<String> asStrings(dynamic value) =>
        value is List ? value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() : const [];

    final rawSteps = json['steps'] ?? json['chain'] ?? const [];

    return Evolution(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      cost: asInt(json['cost']),
      requirements: asStrings(json['requirements']),
      upgrades: asStrings(json['upgrades']),
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()),
      steps: rawSteps is List
          ? rawSteps
              .whereType<Map>()
              .map((e) => EvolutionStep.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}
