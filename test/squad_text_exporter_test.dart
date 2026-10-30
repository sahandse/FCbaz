import 'package:flutter_test/flutter_test.dart';

import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/squad/domain/squad_models.dart';
import 'package:fcbaz/features/squad/domain/squad_text_exporter.dart';

void main() {
  const exporter = SquadTextExporter();

  test(
    'exports only the players and metadata that are really in the squad',
    () {
      const squad = SquadStateModel(
        id: 's1',
        name: 'ترکیب تست',
        formationId: '433',
        playersBySlot: {
          'gk': Player(
            id: 'gk-1',
            name: 'Ali Keeper',
            rating: 88,
            position: 'GK',
            positions: [],
            clubName: 'Club',
            leagueName: 'League',
            nationName: 'Nation',
            version: 'Gold Rare',
            imageUrl: '',
            pace: 80,
            shooting: 80,
            passing: 80,
            dribbling: 80,
            defending: 80,
            physical: 80,
            skillMoves: 4,
            weakFoot: 4,
          ),
          'st': Player(
            id: 'st-1',
            name: 'Sara Striker',
            rating: 92,
            position: 'ST',
            positions: [],
            clubName: 'Club',
            leagueName: 'League',
            nationName: 'Nation',
            version: 'Gold Rare',
            imageUrl: '',
            pace: 80,
            shooting: 80,
            passing: 80,
            dribbling: 80,
            defending: 80,
            physical: 80,
            skillMoves: 4,
            weakFoot: 4,
          ),
        },
        manager: ManagerProfile(
          name: 'Coach One',
          nationName: 'Nation',
          leagueName: 'League',
        ),
        tactics: TacticProfile(
          name: 'پلن اصلی',
          buildUpStyle: 'Balanced',
          defensiveApproach: 'High',
          lineHeight: 70,
        ),
      );

      final text = exporter.export(squad);

      expect(text, contains('FCBaz • ترکیب تست'));
      expect(text, contains('FC 27 • آرایش 4-3-3'));
      expect(text, contains('ریتینگ میانگین: ۹۰'));
      expect(text, contains('شیمی:'));
      expect(text, contains('GK | Ali Keeper | ۸۸'));
      expect(text, contains('ST | Sara Striker | ۹۲'));
      expect(text, contains('جای خالی: LB'));
      expect(text, contains('جای خالی: LB، CB، CB، RB، CM، CM، CM، LW، RW'));
      expect(text, contains('سرمربی: Coach One • Nation • League'));
      expect(text, contains('تاکتیک: Balanced • High • خط ۷۰'));
      expect(text, isNot(contains('Messi')));
      expect(text, isNot(contains('Ronaldo')));
      expect(text.trimRight().endsWith('ساخته‌شده با FCBaz'), isTrue);
    },
  );

  test('never invents players for an empty squad', () {
    const squad = SquadStateModel(
      id: 's2',
      name: '',
      formationId: '433',
      playersBySlot: {},
    );

    final text = exporter.export(squad);

    expect(text, contains('FCBaz • ترکیب من'));
    expect(text, contains('هنوز بازیکنی به ترکیب اضافه نشده است.'));
    expect(text, isNot(contains('ریتینگ میانگین')));
    expect(text, isNot(contains('جای خالی')));
    expect(text, isNot(contains('|')));
  });
}
