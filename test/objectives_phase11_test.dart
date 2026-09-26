import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/home/home_repository.dart';

void main() {
  group('Objectives Phase 11', () {
    test('parses real category and structured tasks', () {
      final objective = HomeObjective.fromJson({
        'id': 'obj-1',
        'title': 'Weekly Objective',
        'category': 'Weekly',
        'task_count': 1,
        'tasks': [
          {
            'id': 'task-1',
            'title': 'Win matches',
            'target': 5,
            'reward': 'Pack',
          }
        ],
      });

      expect(objective.category, 'Weekly');
      expect(objective.tasks, hasLength(1));
      expect(objective.tasks.first.target, 5);
      expect(objective.tasks.first.reward, 'Pack');
    });

    test('does not invent tasks when backend only gives task count', () {
      final objective = HomeObjective.fromJson({
        'id': 'obj-2',
        'title': 'Season Objective',
        'task_count': 4,
      });

      expect(objective.taskCount, 4);
      expect(objective.tasks, isEmpty);
    });

    test('task count falls back to actual structured task length', () {
      final objective = HomeObjective.fromJson({
        'id': 'obj-3',
        'title': 'Objective',
        'tasks': [
          {'id': 'a', 'title': 'A'},
          {'id': 'b', 'title': 'B'},
        ],
      });

      expect(objective.taskCount, 2);
    });
  });
}
