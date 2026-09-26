import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/squad/domain/squad_models.dart';

void main() {
  group('Phase 5 squad formations', () {
    test('exposes expanded FC27 formation catalog', () {
      final ids = Formations.all.map((e) => e.id).toSet();

      expect(ids, containsAll(<String>{
        '4411',
        '4213',
        '4231',
        '442',
        '433a',
        '41212',
        '433h',
        '4312',
        '433',
        '4321',
        '4222',
        '4141',
        '352',
        '5212',
      }));

      for (final formation in Formations.all) {
        expect(formation.slots.length, 11);
        expect(formation.slots.map((e) => e.id).toSet().length, 11);
      }
    });

    test('structured tactics serialize without demo defaults', () {
      const tactics = TacticProfile(
        name: 'پلن من',
        code: 'ABC123',
        buildUpStyle: 'Short Passing',
        defensiveApproach: 'Balanced',
        lineHeight: 55,
      );

      final json = tactics.toJson();
      final restored = TacticProfile.fromJson(json);

      expect(restored.name, 'پلن من');
      expect(restored.code, 'ABC123');
      expect(restored.buildUpStyle, 'Short Passing');
      expect(restored.defensiveApproach, 'Balanced');
      expect(restored.lineHeight, 55);
      expect(restored.hasStructuredTactics, isTrue);
    });

    test('old tactics payload remains backwards compatible', () {
      final restored = TacticProfile.fromJson({
        'name': 'قدیمی',
        'defensive_plan': 'custom',
      });

      expect(restored.name, 'قدیمی');
      expect(restored.defensivePlan, 'custom');
      expect(restored.buildUpStyle, isEmpty);
      expect(restored.defensiveApproach, isEmpty);
      expect(restored.lineHeight, isNull);
    });

    test('line height is clamped to in-game range', () {
      expect(TacticProfile.fromJson({'line_height': 130}).lineHeight, 100);
      expect(TacticProfile.fromJson({'line_height': -10}).lineHeight, 1);
    });
  });
}
