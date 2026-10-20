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

    final title = (json['titleFA'] ?? json['nameFA'] ?? json['title_fa'] ?? json['name_fa'] ?? json['title'] ?? json['name'] ?? '').toString();

    return EvolutionStep(
      title: title,
      requirements: asStrings(json['tasksFA'] ?? json['requirementsFA'] ?? json['requirements_fa'] ?? json['requirements'] ?? json['tasks']),
      upgrades: asStrings(json['upgradesFA'] ?? json['upgrades_fa'] ?? json['upgrades']),
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
    required this.requirementData,
    required this.upgrades,
    this.upgradeData = const [],
    required this.expiresAt,
    required this.steps,
  });

  final String id;
  final String title;
  final String description;
  final int cost;
  final List<String> requirements;
  final List<Map<String, dynamic>> requirementData;
  final List<String> upgrades;
  final List<Map<String, dynamic>> upgradeData;
  final DateTime? expiresAt;
  final List<EvolutionStep> steps;

  factory Evolution.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

    List<String> asStrings(dynamic value) =>
        value is List ? value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() : const [];

    List<Map<String, dynamic>> asMaps(dynamic value) => value is List
        ? value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : const [];

    final rawSteps = json['levels'] ?? json['steps'] ?? json['chain'] ?? const [];
    final rawReq = json['requirements_raw'] ?? json['requirement_data'] ?? const [];
    final rawUpgrade = json['upgrades_raw'] ??
        json['upgrade_data'] ??
        json['stat_upgrades'] ??
        json['boosts'] ??
        const [];

    final titleFa = (json['titleFA'] ?? json['nameFA'] ?? json['title_fa'] ?? json['name_fa'] ?? '').toString();
    final titleEn = (json['title'] ?? json['name'] ?? '').toString();
    final title = titleFa.isNotEmpty ? titleFa : titleEn;

    final descFa = (json['descriptionFA'] ?? json['description_fa'] ?? '').toString();
    final descEn = (json['description'] ?? '').toString();
    final desc = descFa.isNotEmpty ? descFa : descEn;

    return Evolution(
      id: (json['id'] ?? '').toString(),
      title: title,
      description: desc,
      cost: asInt(json['cost']),
      requirements: asStrings(json['requirements_fa'] ?? json['requirementsFA'] ?? json['requirements']),
      requirementData: asMaps(rawReq),
      upgrades: asStrings(json['upgrades_fa'] ?? json['upgradesFA'] ?? json['upgrades']),
      upgradeData: asMaps(rawUpgrade),
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
