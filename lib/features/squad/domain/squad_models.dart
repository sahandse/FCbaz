import '../../players/domain/player.dart';

class FormationSlot {
  const FormationSlot({
    required this.id,
    required this.position,
    required this.x,
    required this.y,
  });

  final String id;
  final String position;
  final double x;
  final double y;
}

class FormationDefinition {
  const FormationDefinition({
    required this.id,
    required this.name,
    required this.slots,
  });

  final String id;
  final String name;
  final List<FormationSlot> slots;
}

class ManagerProfile {
  const ManagerProfile({
    required this.name,
    required this.nationName,
    required this.leagueName,
  });

  final String name;
  final String nationName;
  final String leagueName;

  bool get isEmpty =>
      name.trim().isEmpty &&
      nationName.trim().isEmpty &&
      leagueName.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'nation_name': nationName,
        'league_name': leagueName,
      };

  factory ManagerProfile.fromJson(Map<String, dynamic> json) => ManagerProfile(
        name: (json['name'] ?? '').toString(),
        nationName: (json['nation_name'] ?? '').toString(),
        leagueName: (json['league_name'] ?? '').toString(),
      );
}

class SquadPlayerConfig {
  const SquadPlayerConfig({
    this.chemistryStyle = 'Basic',
    this.role = '',
    this.focus = '',
  });

  final String chemistryStyle;
  final String role;
  final String focus;

  Map<String, dynamic> toJson() => {
        'chemistry_style': chemistryStyle,
        'role': role,
        'focus': focus,
      };

  factory SquadPlayerConfig.fromJson(Map<String, dynamic> json) =>
      SquadPlayerConfig(
        chemistryStyle: (json['chemistry_style'] ?? 'Basic').toString(),
        role: (json['role'] ?? '').toString(),
        focus: (json['focus'] ?? '').toString(),
      );
}

class SquadStateModel {
  const SquadStateModel({
    required this.id,
    required this.name,
    required this.formationId,
    required this.playersBySlot,
    this.playerConfigs = const {},
    this.bench = const [],
    this.manager,
  });

  final String id;
  final String name;
  final String formationId;
  final Map<String, Player> playersBySlot;
  final Map<String, SquadPlayerConfig> playerConfigs;
  final List<Player> bench;
  final ManagerProfile? manager;

  SquadStateModel copyWith({
    String? name,
    String? formationId,
    Map<String, Player>? playersBySlot,
    Map<String, SquadPlayerConfig>? playerConfigs,
    List<Player>? bench,
    ManagerProfile? manager,
    bool clearManager = false,
  }) {
    return SquadStateModel(
      id: id,
      name: name ?? this.name,
      formationId: formationId ?? this.formationId,
      playersBySlot: playersBySlot ?? this.playersBySlot,
      playerConfigs: playerConfigs ?? this.playerConfigs,
      bench: bench ?? this.bench,
      manager: clearManager ? null : (manager ?? this.manager),
    );
  }

  Map<String, dynamic> toJson() => {
        'schema_version': 2,
        'id': id,
        'name': name,
        'formation_id': formationId,
        'players': playersBySlot.map(
          (slot, player) => MapEntry(slot, player.toJson()),
        ),
        'player_configs': playerConfigs.map(
          (slot, config) => MapEntry(slot, config.toJson()),
        ),
        'bench': bench.map((p) => p.toJson()).toList(),
        'manager': manager?.toJson(),
      };

  factory SquadStateModel.fromJson(Map<String, dynamic> map) {
    final players = <String, Player>{};
    final rawPlayers = map['players'];
    if (rawPlayers is Map) {
      for (final item in rawPlayers.entries) {
        if (item.value is Map) {
          players[item.key.toString()] = Player.fromJson(
            Map<String, dynamic>.from(item.value as Map),
          );
        }
      }
    }

    final configs = <String, SquadPlayerConfig>{};
    final rawConfigs = map['player_configs'];
    if (rawConfigs is Map) {
      for (final item in rawConfigs.entries) {
        if (item.value is Map) {
          configs[item.key.toString()] = SquadPlayerConfig.fromJson(
            Map<String, dynamic>.from(item.value as Map),
          );
        }
      }
    }

    final rawBench = map['bench'];
    final bench = rawBench is List
        ? rawBench
            .whereType<Map>()
            .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id.isNotEmpty)
            .take(7)
            .toList()
        : const <Player>[];

    ManagerProfile? manager;
    if (map['manager'] is Map) {
      final parsed = ManagerProfile.fromJson(
        Map<String, dynamic>.from(map['manager'] as Map),
      );
      if (!parsed.isEmpty) manager = parsed;
    }

    return SquadStateModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'ترکیب من').toString(),
      formationId: (map['formation_id'] ?? '433').toString(),
      playersBySlot: players,
      playerConfigs: configs,
      bench: bench,
      manager: manager,
    );
  }
}

class Formations {
  static const all = <FormationDefinition>[
    FormationDefinition(
      id: '433',
      name: '4-3-3',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lb', position: 'LB', x: .14, y: .70),
        FormationSlot(id: 'lcb', position: 'CB', x: .38, y: .75),
        FormationSlot(id: 'rcb', position: 'CB', x: .62, y: .75),
        FormationSlot(id: 'rb', position: 'RB', x: .86, y: .70),
        FormationSlot(id: 'lcm', position: 'CM', x: .25, y: .50),
        FormationSlot(id: 'cm', position: 'CM', x: .50, y: .56),
        FormationSlot(id: 'rcm', position: 'CM', x: .75, y: .50),
        FormationSlot(id: 'lw', position: 'LW', x: .18, y: .23),
        FormationSlot(id: 'st', position: 'ST', x: .50, y: .16),
        FormationSlot(id: 'rw', position: 'RW', x: .82, y: .23),
      ],
    ),
    FormationDefinition(
      id: '442',
      name: '4-4-2',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lb', position: 'LB', x: .14, y: .70),
        FormationSlot(id: 'lcb', position: 'CB', x: .38, y: .75),
        FormationSlot(id: 'rcb', position: 'CB', x: .62, y: .75),
        FormationSlot(id: 'rb', position: 'RB', x: .86, y: .70),
        FormationSlot(id: 'lm', position: 'LM', x: .14, y: .48),
        FormationSlot(id: 'lcm', position: 'CM', x: .40, y: .53),
        FormationSlot(id: 'rcm', position: 'CM', x: .60, y: .53),
        FormationSlot(id: 'rm', position: 'RM', x: .86, y: .48),
        FormationSlot(id: 'lst', position: 'ST', x: .38, y: .20),
        FormationSlot(id: 'rst', position: 'ST', x: .62, y: .20),
      ],
    ),
    FormationDefinition(
      id: '4231',
      name: '4-2-3-1',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lb', position: 'LB', x: .14, y: .70),
        FormationSlot(id: 'lcb', position: 'CB', x: .38, y: .75),
        FormationSlot(id: 'rcb', position: 'CB', x: .62, y: .75),
        FormationSlot(id: 'rb', position: 'RB', x: .86, y: .70),
        FormationSlot(id: 'lcdm', position: 'CDM', x: .36, y: .55),
        FormationSlot(id: 'rcdm', position: 'CDM', x: .64, y: .55),
        FormationSlot(id: 'lam', position: 'CAM', x: .22, y: .34),
        FormationSlot(id: 'cam', position: 'CAM', x: .50, y: .38),
        FormationSlot(id: 'ram', position: 'CAM', x: .78, y: .34),
        FormationSlot(id: 'st', position: 'ST', x: .50, y: .15),
      ],
    ),
    FormationDefinition(
      id: '41212',
      name: '4-1-2-1-2',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lb', position: 'LB', x: .14, y: .70),
        FormationSlot(id: 'lcb', position: 'CB', x: .38, y: .75),
        FormationSlot(id: 'rcb', position: 'CB', x: .62, y: .75),
        FormationSlot(id: 'rb', position: 'RB', x: .86, y: .70),
        FormationSlot(id: 'cdm', position: 'CDM', x: .50, y: .58),
        FormationSlot(id: 'lcm', position: 'CM', x: .28, y: .46),
        FormationSlot(id: 'rcm', position: 'CM', x: .72, y: .46),
        FormationSlot(id: 'cam', position: 'CAM', x: .50, y: .34),
        FormationSlot(id: 'lst', position: 'ST', x: .37, y: .16),
        FormationSlot(id: 'rst', position: 'ST', x: .63, y: .16),
      ],
    ),
  ];

  static FormationDefinition byId(String id) {
    return all.firstWhere((f) => f.id == id, orElse: () => all.first);
  }
}
