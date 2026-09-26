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

class TacticProfile {
  const TacticProfile({
    this.name = 'پلن اصلی',
    this.code = '',
    this.buildUpStyle = '',
    this.defensiveApproach = '',
    this.lineHeight,
    this.defensivePlan = '',
    this.buildUpPlan = '',
    this.attackingPlan = '',
    this.notes = '',
  });

  static const buildUpStyles = <String>[
    'Balanced',
    'Counter',
    'Short Passing',
  ];

  static const defensiveApproaches = <String>[
    'Deep',
    'Balanced',
    'High',
    'Aggressive',
  ];

  final String name;
  final String code;
  final String buildUpStyle;
  final String defensiveApproach;
  final int? lineHeight;
  final String defensivePlan;
  final String buildUpPlan;
  final String attackingPlan;
  final String notes;

  bool get isEmpty =>
      code.trim().isEmpty &&
      buildUpStyle.trim().isEmpty &&
      defensiveApproach.trim().isEmpty &&
      lineHeight == null &&
      defensivePlan.trim().isEmpty &&
      buildUpPlan.trim().isEmpty &&
      attackingPlan.trim().isEmpty &&
      notes.trim().isEmpty;

  bool get hasStructuredTactics =>
      buildUpStyle.isNotEmpty || defensiveApproach.isNotEmpty || lineHeight != null;

  TacticProfile copyWith({
    String? name,
    String? code,
    String? buildUpStyle,
    String? defensiveApproach,
    int? lineHeight,
    bool clearLineHeight = false,
    String? defensivePlan,
    String? buildUpPlan,
    String? attackingPlan,
    String? notes,
  }) {
    return TacticProfile(
      name: name ?? this.name,
      code: code ?? this.code,
      buildUpStyle: buildUpStyle ?? this.buildUpStyle,
      defensiveApproach: defensiveApproach ?? this.defensiveApproach,
      lineHeight: clearLineHeight ? null : (lineHeight ?? this.lineHeight),
      defensivePlan: defensivePlan ?? this.defensivePlan,
      buildUpPlan: buildUpPlan ?? this.buildUpPlan,
      attackingPlan: attackingPlan ?? this.attackingPlan,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'build_up_style': buildUpStyle,
        'defensive_approach': defensiveApproach,
        'line_height': lineHeight,
        'defensive_plan': defensivePlan,
        'build_up_plan': buildUpPlan,
        'attacking_plan': attackingPlan,
        'notes': notes,
      };

  factory TacticProfile.fromJson(Map<String, dynamic> json) {
    final rawLineHeight = json['line_height'];
    final parsedLineHeight = rawLineHeight is int
        ? rawLineHeight
        : int.tryParse((rawLineHeight ?? '').toString());

    return TacticProfile(
      name: (json['name'] ?? 'پلن اصلی').toString(),
      code: (json['code'] ?? '').toString(),
      buildUpStyle: (json['build_up_style'] ?? '').toString(),
      defensiveApproach: (json['defensive_approach'] ?? '').toString(),
      lineHeight: parsedLineHeight?.clamp(1, 100),
      defensivePlan: (json['defensive_plan'] ?? '').toString(),
      buildUpPlan: (json['build_up_plan'] ?? '').toString(),
      attackingPlan: (json['attacking_plan'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
    );
  }
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
    this.tactics = const TacticProfile(),
  });

  final String id;
  final String name;
  final String formationId;
  final Map<String, Player> playersBySlot;
  final Map<String, SquadPlayerConfig> playerConfigs;
  final List<Player> bench;
  final ManagerProfile? manager;
  final TacticProfile tactics;

  SquadStateModel copyWith({
    String? name,
    String? formationId,
    Map<String, Player>? playersBySlot,
    Map<String, SquadPlayerConfig>? playerConfigs,
    List<Player>? bench,
    ManagerProfile? manager,
    bool clearManager = false,
    TacticProfile? tactics,
  }) {
    return SquadStateModel(
      id: id,
      name: name ?? this.name,
      formationId: formationId ?? this.formationId,
      playersBySlot: playersBySlot ?? this.playersBySlot,
      playerConfigs: playerConfigs ?? this.playerConfigs,
      bench: bench ?? this.bench,
      manager: clearManager ? null : (manager ?? this.manager),
      tactics: tactics ?? this.tactics,
    );
  }

  Map<String, dynamic> toJson() => {
        'schema_version': 3,
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
        'tactics': tactics.toJson(),
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

    final tactics = map['tactics'] is Map
        ? TacticProfile.fromJson(
            Map<String, dynamic>.from(map['tactics'] as Map),
          )
        : const TacticProfile();

    return SquadStateModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'ترکیب من').toString(),
      formationId: (map['formation_id'] ?? '433').toString(),
      playersBySlot: players,
      playerConfigs: configs,
      bench: bench,
      manager: manager,
      tactics: tactics,
    );
  }
}

class Formations {
  static const all = <FormationDefinition>[
    FormationDefinition(
      id: '4411',
      name: '4-4-1-1',
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
        FormationSlot(id: 'cam', position: 'CAM', x: .50, y: .31),
        FormationSlot(id: 'st', position: 'ST', x: .50, y: .15),
      ],
    ),
    FormationDefinition(
      id: '4213',
      name: '4-2-1-3',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lb', position: 'LB', x: .14, y: .70),
        FormationSlot(id: 'lcb', position: 'CB', x: .38, y: .75),
        FormationSlot(id: 'rcb', position: 'CB', x: .62, y: .75),
        FormationSlot(id: 'rb', position: 'RB', x: .86, y: .70),
        FormationSlot(id: 'lcdm', position: 'CDM', x: .36, y: .56),
        FormationSlot(id: 'rcdm', position: 'CDM', x: .64, y: .56),
        FormationSlot(id: 'cam', position: 'CAM', x: .50, y: .38),
        FormationSlot(id: 'lw', position: 'LW', x: .18, y: .22),
        FormationSlot(id: 'st', position: 'ST', x: .50, y: .14),
        FormationSlot(id: 'rw', position: 'RW', x: .82, y: .22),
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
      id: '433a',
      name: '4-3-3 Attack',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lb', position: 'LB', x: .14, y: .70),
        FormationSlot(id: 'lcb', position: 'CB', x: .38, y: .75),
        FormationSlot(id: 'rcb', position: 'CB', x: .62, y: .75),
        FormationSlot(id: 'rb', position: 'RB', x: .86, y: .70),
        FormationSlot(id: 'lcm', position: 'CM', x: .31, y: .52),
        FormationSlot(id: 'rcm', position: 'CM', x: .69, y: .52),
        FormationSlot(id: 'cam', position: 'CAM', x: .50, y: .39),
        FormationSlot(id: 'lw', position: 'LW', x: .18, y: .22),
        FormationSlot(id: 'st', position: 'ST', x: .50, y: .14),
        FormationSlot(id: 'rw', position: 'RW', x: .82, y: .22),
      ],
    ),
    FormationDefinition(
      id: '41212',
      name: '4-1-2-1-2 Narrow',
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
    FormationDefinition(
      id: '433h',
      name: '4-3-3 Holding',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lb', position: 'LB', x: .14, y: .70),
        FormationSlot(id: 'lcb', position: 'CB', x: .38, y: .75),
        FormationSlot(id: 'rcb', position: 'CB', x: .62, y: .75),
        FormationSlot(id: 'rb', position: 'RB', x: .86, y: .70),
        FormationSlot(id: 'cdm', position: 'CDM', x: .50, y: .59),
        FormationSlot(id: 'lcm', position: 'CM', x: .30, y: .47),
        FormationSlot(id: 'rcm', position: 'CM', x: .70, y: .47),
        FormationSlot(id: 'lw', position: 'LW', x: .18, y: .22),
        FormationSlot(id: 'st', position: 'ST', x: .50, y: .14),
        FormationSlot(id: 'rw', position: 'RW', x: .82, y: .22),
      ],
    ),
    FormationDefinition(
      id: '4312',
      name: '4-3-1-2',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lb', position: 'LB', x: .14, y: .70),
        FormationSlot(id: 'lcb', position: 'CB', x: .38, y: .75),
        FormationSlot(id: 'rcb', position: 'CB', x: .62, y: .75),
        FormationSlot(id: 'rb', position: 'RB', x: .86, y: .70),
        FormationSlot(id: 'lcm', position: 'CM', x: .25, y: .52),
        FormationSlot(id: 'cm', position: 'CM', x: .50, y: .58),
        FormationSlot(id: 'rcm', position: 'CM', x: .75, y: .52),
        FormationSlot(id: 'cam', position: 'CAM', x: .50, y: .36),
        FormationSlot(id: 'lst', position: 'ST', x: .37, y: .16),
        FormationSlot(id: 'rst', position: 'ST', x: .63, y: .16),
      ],
    ),
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
      id: '4321',
      name: '4-3-2-1',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lb', position: 'LB', x: .14, y: .70),
        FormationSlot(id: 'lcb', position: 'CB', x: .38, y: .75),
        FormationSlot(id: 'rcb', position: 'CB', x: .62, y: .75),
        FormationSlot(id: 'rb', position: 'RB', x: .86, y: .70),
        FormationSlot(id: 'lcm', position: 'CM', x: .25, y: .52),
        FormationSlot(id: 'cm', position: 'CM', x: .50, y: .57),
        FormationSlot(id: 'rcm', position: 'CM', x: .75, y: .52),
        FormationSlot(id: 'lf', position: 'LW', x: .28, y: .25),
        FormationSlot(id: 'st', position: 'ST', x: .50, y: .14),
        FormationSlot(id: 'rf', position: 'RW', x: .72, y: .25),
      ],
    ),
    FormationDefinition(
      id: '4222',
      name: '4-2-2-2',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lb', position: 'LB', x: .14, y: .70),
        FormationSlot(id: 'lcb', position: 'CB', x: .38, y: .75),
        FormationSlot(id: 'rcb', position: 'CB', x: .62, y: .75),
        FormationSlot(id: 'rb', position: 'RB', x: .86, y: .70),
        FormationSlot(id: 'lcdm', position: 'CDM', x: .36, y: .55),
        FormationSlot(id: 'rcdm', position: 'CDM', x: .64, y: .55),
        FormationSlot(id: 'lcam', position: 'CAM', x: .25, y: .35),
        FormationSlot(id: 'rcam', position: 'CAM', x: .75, y: .35),
        FormationSlot(id: 'lst', position: 'ST', x: .38, y: .17),
        FormationSlot(id: 'rst', position: 'ST', x: .62, y: .17),
      ],
    ),
    FormationDefinition(
      id: '4141',
      name: '4-1-4-1',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lb', position: 'LB', x: .14, y: .70),
        FormationSlot(id: 'lcb', position: 'CB', x: .38, y: .75),
        FormationSlot(id: 'rcb', position: 'CB', x: .62, y: .75),
        FormationSlot(id: 'rb', position: 'RB', x: .86, y: .70),
        FormationSlot(id: 'cdm', position: 'CDM', x: .50, y: .60),
        FormationSlot(id: 'lm', position: 'LM', x: .14, y: .44),
        FormationSlot(id: 'lcm', position: 'CM', x: .38, y: .48),
        FormationSlot(id: 'rcm', position: 'CM', x: .62, y: .48),
        FormationSlot(id: 'rm', position: 'RM', x: .86, y: .44),
        FormationSlot(id: 'st', position: 'ST', x: .50, y: .16),
      ],
    ),
    FormationDefinition(
      id: '352',
      name: '3-5-2',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lcb', position: 'CB', x: .25, y: .72),
        FormationSlot(id: 'cb', position: 'CB', x: .50, y: .77),
        FormationSlot(id: 'rcb', position: 'CB', x: .75, y: .72),
        FormationSlot(id: 'lm', position: 'LM', x: .12, y: .48),
        FormationSlot(id: 'lcdm', position: 'CDM', x: .36, y: .56),
        FormationSlot(id: 'rcdm', position: 'CDM', x: .64, y: .56),
        FormationSlot(id: 'rm', position: 'RM', x: .88, y: .48),
        FormationSlot(id: 'cam', position: 'CAM', x: .50, y: .35),
        FormationSlot(id: 'lst', position: 'ST', x: .38, y: .16),
        FormationSlot(id: 'rst', position: 'ST', x: .62, y: .16),
      ],
    ),
    FormationDefinition(
      id: '5212',
      name: '5-2-1-2',
      slots: [
        FormationSlot(id: 'gk', position: 'GK', x: .50, y: .91),
        FormationSlot(id: 'lwb', position: 'LWB', x: .10, y: .62),
        FormationSlot(id: 'lcb', position: 'CB', x: .31, y: .73),
        FormationSlot(id: 'cb', position: 'CB', x: .50, y: .77),
        FormationSlot(id: 'rcb', position: 'CB', x: .69, y: .73),
        FormationSlot(id: 'rwb', position: 'RWB', x: .90, y: .62),
        FormationSlot(id: 'lcm', position: 'CM', x: .34, y: .49),
        FormationSlot(id: 'rcm', position: 'CM', x: .66, y: .49),
        FormationSlot(id: 'cam', position: 'CAM', x: .50, y: .34),
        FormationSlot(id: 'lst', position: 'ST', x: .38, y: .16),
        FormationSlot(id: 'rst', position: 'ST', x: .62, y: .16),
      ],
    ),
  ];

  static FormationDefinition byId(String id) {
    return all.firstWhere((f) => f.id == id, orElse: () => all.first);
  }
}