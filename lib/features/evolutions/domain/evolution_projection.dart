import '../../club/data/my_club_repository.dart';
import 'evolution.dart';

class EvolutionProjection {
  const EvolutionProjection({
    required this.before,
    required this.after,
    required this.changes,
  });

  final Map<String, int> before;
  final Map<String, int> after;
  final Map<String, int> changes;

  bool get hasChanges => changes.values.any((value) => value != 0);
}

class EvolutionProjectionEngine {
  const EvolutionProjectionEngine();

  EvolutionProjection? project(MyClubItem item, Evolution evolution) {
    if (evolution.upgradeData.isEmpty) return null;

    final before = <String, int>{
      'rating': item.rating,
      'pace': item.pace,
      'shooting': item.shooting,
      'passing': item.passing,
      'dribbling': item.dribbling,
      'defending': item.defending,
      'physical': item.physical,
      'skill_moves': item.skillMoves,
      'weak_foot': item.weakFoot,
    };
    final after = Map<String, int>.from(before);
    var recognized = false;

    for (final raw in evolution.upgradeData) {
      final key = _statKey(raw['stat'] ?? raw['key'] ?? raw['type'] ?? raw['name']);
      if (key == null || !after.containsKey(key)) continue;

      final operation = (raw['operation'] ?? raw['operator'] ?? raw['mode'] ?? '')
          .toString()
          .toLowerCase();
      final delta = _asInt(raw['delta'] ?? raw['boost'] ?? raw['increase']);
      final target = _asInt(raw['final'] ?? raw['target'] ?? raw['value'] ?? raw['set']);
      final max = _asInt(raw['max'] ?? raw['cap']);

      if (operation.contains('add') || operation == '+' || delta != null) {
        if (delta == null) continue;
        after[key] = (after[key]! + delta).clamp(0, 99).toInt();
        recognized = true;
        continue;
      }

      if (operation.contains('set') || operation.contains('final') || target != null) {
        if (target == null) continue;
        after[key] = target.clamp(0, 99).toInt();
        recognized = true;
        continue;
      }

      if (max != null) {
        after[key] = after[key]!.clamp(0, max).toInt();
        recognized = true;
      }
    }

    if (!recognized) return null;

    final changes = <String, int>{};
    for (final entry in after.entries) {
      changes[entry.key] = entry.value - before[entry.key]!;
    }

    return EvolutionProjection(before: before, after: after, changes: changes);
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse((value ?? '').toString());
  }

  String? _statKey(dynamic raw) {
    final value = (raw ?? '')
        .toString()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll(' ', '');
    if (value.contains('overall') || value == 'ovr' || value == 'rating') return 'rating';
    if (value.contains('pace') || value == 'pac') return 'pace';
    if (value.contains('shoot') || value == 'sho') return 'shooting';
    if (value.contains('pass') || value == 'pas') return 'passing';
    if (value.contains('drib') || value == 'dri') return 'dribbling';
    if (value.contains('defend') || value == 'def') return 'defending';
    if (value.contains('physical') || value == 'phy') return 'physical';
    if (value.contains('skillmove') || value == 'sm') return 'skill_moves';
    if (value.contains('weakfoot') || value == 'wf') return 'weak_foot';
    return null;
  }
}
