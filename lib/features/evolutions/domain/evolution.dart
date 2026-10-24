String _evolutionId(Map<String, dynamic> json) {
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
  final title = (json['title'] ?? json['name'] ?? '').toString();
  return title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

List<String> _positionsFrom(String raw) => raw
    .split(',')
    .map((part) => part.trim().toUpperCase())
    .where((part) => part.isNotEmpty)
    .toList();

int? _firstInt(String raw) {
  final match = RegExp(r'-?\d[\d,]*').firstMatch(raw.replaceAll('٬', ''));
  if (match == null) return null;
  return int.tryParse(match.group(0)!.replaceAll(',', ''));
}

Map<String, dynamic>? _parseRequirementLine(String line) {
  final separator = line.indexOf(':');
  if (separator <= 0) return null;
  final label = line.substring(0, separator).trim().toLowerCase();
  final value = line.substring(separator + 1).trim();
  if (value.isEmpty) return null;

  if (label.contains('excluded') && label.contains('position')) {
    final positions = _positionsFrom(value);
    return positions.isEmpty
        ? null
        : {'type': 'excluded_position', 'values': positions};
  }
  if (label.contains('max pos')) {
    final n = _firstInt(value);
    return n == null ? null : {'type': 'max_positions', 'max': n};
  }
  if (label.contains('position')) {
    final positions = _positionsFrom(value);
    return positions.isEmpty ? null : {'type': 'position', 'values': positions};
  }
  if (label.contains('overall') || label.contains('rating')) {
    final n = _firstInt(value);
    if (n == null) return null;
    if (label.contains('min')) return {'type': 'overall', 'min': n};
    return {'type': 'overall', 'max': n};
  }
  if (label.contains('skill move')) {
    final n = _firstInt(value);
    return n == null ? null : {'type': 'skill_moves', 'max': n};
  }
  if (label.contains('weak foot')) {
    final n = _firstInt(value);
    return n == null ? null : {'type': 'weak_foot', 'max': n};
  }
  if (label.contains('pace')) {
    final n = _firstInt(value);
    return n == null ? null : {'type': 'pace', 'max': n};
  }
  if (label.contains('shoot')) {
    final n = _firstInt(value);
    return n == null ? null : {'type': 'shooting', 'max': n};
  }
  if (label.contains('pass')) {
    final n = _firstInt(value);
    return n == null ? null : {'type': 'passing', 'max': n};
  }
  if (label.contains('drib')) {
    final n = _firstInt(value);
    return n == null ? null : {'type': 'dribbling', 'max': n};
  }
  if (label.contains('defend')) {
    final n = _firstInt(value);
    return n == null ? null : {'type': 'defending', 'max': n};
  }
  if (label.contains('physical')) {
    final n = _firstInt(value);
    return n == null ? null : {'type': 'physical', 'max': n};
  }
  if (label.contains('rarity')) {
    return {'type': 'rarity', 'value': value};
  }
  if (label.contains('ps+')) {
    final n = _firstInt(value);
    return n == null ? null : {'type': 'playstyles_plus', 'max': n};
  }
  if (label.contains('ps')) {
    final n = _firstInt(value);
    return n == null ? null : {'type': 'playstyles', 'max': n};
  }
  if (label.contains('born after')) {
    return {'type': 'born_after', 'value': value};
  }
  return null;
}

List<Map<String, dynamic>> _parseRequirements(List<String> lines) {
  final parsed = <Map<String, dynamic>>[];
  for (final line in lines) {
    final requirement = _parseRequirementLine(line);
    if (requirement != null) parsed.add(requirement);
  }
  return parsed;
}

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
    List<String> asStrings(dynamic value) => value is List
        ? value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const [];

    final title =
        (json['titleFA'] ??
                json['nameFA'] ??
                json['title_fa'] ??
                json['name_fa'] ??
                json['title'] ??
                json['name'] ??
                '')
            .toString();

    return EvolutionStep(
      title: title,
      requirements: asStrings(
        json['tasksFA'] ??
            json['requirementsFA'] ??
            json['requirements_fa'] ??
            json['requirements'] ??
            json['tasks'],
      ),
      upgrades: asStrings(
        json['upgradesFA'] ?? json['upgrades_fa'] ?? json['upgrades'],
      ),
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

    List<String> asStrings(dynamic value) => value is List
        ? value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const [];

    List<Map<String, dynamic>> asMaps(dynamic value) => value is List
        ? value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : const [];

    final rawSteps =
        json['levels'] ?? json['steps'] ?? json['chain'] ?? const [];
    final rawReq =
        json['requirements_raw'] ?? json['requirement_data'] ?? const [];
    final rawUpgrade =
        json['upgrades_raw'] ??
        json['upgrade_data'] ??
        json['stat_upgrades'] ??
        json['boosts'] ??
        const [];
    final structuredRequirements = asMaps(rawReq);
    final englishRequirements = asStrings(json['requirements']);

    final titleFa =
        (json['titleFA'] ??
                json['nameFA'] ??
                json['title_fa'] ??
                json['name_fa'] ??
                '')
            .toString();
    final titleEn = (json['title'] ?? json['name'] ?? '').toString();
    final title = titleFa.isNotEmpty ? titleFa : titleEn;

    final descFa = (json['descriptionFA'] ?? json['description_fa'] ?? '')
        .toString();
    final descEn = (json['description'] ?? '').toString();
    final desc = descFa.isNotEmpty ? descFa : descEn;

    return Evolution(
      id: _evolutionId(json),
      title: title,
      description: desc,
      cost: asInt(json['cost']),
      requirements: asStrings(
        json['requirements_fa'] ??
            json['requirementsFA'] ??
            json['requirements'],
      ),
      requirementData: structuredRequirements.isNotEmpty
          ? structuredRequirements
          : _parseRequirements(englishRequirements),
      upgrades: asStrings(
        json['upgrades_fa'] ?? json['upgradesFA'] ?? json['upgrades'],
      ),
      upgradeData: asMaps(rawUpgrade),
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()),
      steps: rawSteps is List
          ? rawSteps
                .whereType<Map>()
                .map(
                  (e) => EvolutionStep.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}
