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

class SquadStateModel {
  const SquadStateModel({
    required this.id,
    required this.name,
    required this.formationId,
    required this.playersBySlot,
  });

  final String id;
  final String name;
  final String formationId;
  final Map<String, Player> playersBySlot;

  SquadStateModel copyWith({
    String? name,
    String? formationId,
    Map<String, Player>? playersBySlot,
  }) {
    return SquadStateModel(
      id: id,
      name: name ?? this.name,
      formationId: formationId ?? this.formationId,
      playersBySlot: playersBySlot ?? this.playersBySlot,
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
