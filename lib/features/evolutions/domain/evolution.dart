class Evolution {
  const Evolution({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.requirements,
    required this.upgrades,
    required this.expiresAt,
  });

  final String id;
  final String title;
  final String description;
  final int cost;
  final List<String> requirements;
  final List<String> upgrades;
  final DateTime? expiresAt;

  factory Evolution.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

    List<String> asStrings(dynamic value) =>
        value is List ? value.map((e) => e.toString()).toList() : const [];

    return Evolution(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      cost: asInt(json['cost']),
      requirements: asStrings(json['requirements']),
      upgrades: asStrings(json['upgrades']),
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()),
    );
  }
}
