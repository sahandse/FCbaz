import 'package:flutter_test/flutter_test.dart';

import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/squad/domain/chemistry_engine.dart';
import 'package:fcbaz/features/squad/domain/squad_insights_service.dart';
import 'package:fcbaz/features/squad/domain/squad_models.dart';

Player player({
  required String id,
  required String name,
  required String position,
  int rating = 88,
  int pace = 85,
  int shooting = 85,
  int passing = 85,
  int dribbling = 85,
  int defending = 70,
  int physical = 80,
  List<String> playStylesPlus = const [],
  List<String> roles = const [],
}) {
  return Player(
    id: id,
    name: name,
    rating: rating,
    position: position,
    positions: const [],
    clubName: 'Club',
    leagueName: 'League',
    nationName: 'Nation',
    version: 'Gold Rare',
    imageUrl: '',
    pace: pace,
    shooting: shooting,
    passing: passing,
    dribbling: dribbling,
    defending: defending,
    physical: physical,
    skillMoves: 4,
    weakFoot: 4,
    playStylesPlus: playStylesPlus,
    roles: roles,
  );
}

void main() {
  test('FCBaz squad meta score increases with chemistry and playstyle plus', () {
    final formation = Formations.byId('433');
    final p = player(
      id: '1',
      name: 'Meta ST',
      position: 'ST',
      playStylesPlus: const ['Quick Step+'],
      roles: const ['Advanced Forward++'],
    );

    final squad = SquadStateModel(
      id: 's1',
      name: 'Meta',
      formationId: '433',
      playersBySlot: {'st': p},
      playerConfigs: const {
        'st': SquadPlayerConfig(role: 'Advanced Forward++'),
      },
    );

    const chemistry = ChemistryResult(total: 3, bySlot: {'st': 3});
    final insights = SquadInsightsService().analyze(
      squad: squad,
      formation: formation,
      chemistry: chemistry,
    );

    expect(insights.metaScore, greaterThan(0));
    expect(insights.playStylesPlusCount, 1);
    expect(insights.roleConfiguredCount, 1);
  });

  test('insights flags out of position cards', () {
    final formation = Formations.byId('433');
    final squad = SquadStateModel(
      id: 's1',
      name: 'Weak',
      formationId: '433',
      playersBySlot: {
        'st': player(
          id: '1',
          name: 'Wrong',
          position: 'CB',
        ),
      },
    );

    const chemistry = ChemistryResult(total: 0, bySlot: {'st': 0});
    final insights = SquadInsightsService().analyze(
      squad: squad,
      formation: formation,
      chemistry: chemistry,
    );

    expect(
      insights.weaknesses.any((e) => e.title == 'Out of Position'),
      isTrue,
    );
  });

  test('tactic profile serializes user-entered real settings', () {
    const tactics = TacticProfile(
      name: 'پلن اصلی',
      code: 'ABC123',
      defensivePlan: 'تنظیم دفاعی من',
      buildUpPlan: 'Build-up من',
      attackingPlan: 'پلن حمله من',
      notes: 'یادداشت',
    );

    final parsed = TacticProfile.fromJson(tactics.toJson());

    expect(parsed.code, 'ABC123');
    expect(parsed.defensivePlan, 'تنظیم دفاعی من');
    expect(parsed.buildUpPlan, 'Build-up من');
    expect(parsed.attackingPlan, 'پلن حمله من');
  });
}
