import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/squad/domain/chemistry_engine.dart';
import 'package:fcbaz/features/squad/domain/squad_insights_service.dart';
import 'package:fcbaz/features/squad/presentation/insight_explain_sheet.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/source_bundle.dart';

Player _player({
  String id = 'p-1',
  String name = 'مهدی طارمی',
  int rating = 84,
  String position = 'ST',
  List<String> playStyles = const ['Finesse Shot'],
  List<String> playStylesPlus = const ['Power Shot', 'Trivela'],
  List<String> roles = const ['Advanced Forward'],
}) {
  return Player.fromJson({
    'id': id,
    'name': name,
    'rating': rating,
    'position': position,
    'pace': 82,
    'shooting': 86,
    'passing': 74,
    'dribbling': 81,
    'defending': 38,
    'physical': 79,
    'playstyles': playStyles,
    'playstyles_plus': playStylesPlus,
    'roles': roles,
    'price_ps': 150000,
  });
}

Widget _host(VoidCallback onOpen) {
  return MaterialApp(
    theme: FCBazTheme.dark(),
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: ElevatedButton(onPressed: onOpen, child: const Text('open')),
        ),
      ),
    ),
  );
}

String _fa(double value) => faDigits(value.toStringAsFixed(1));

void main() {
  test('meta breakdown adds up to the score used by recommendations', () {
    final service = SquadInsightsService();
    final player = _player();

    final breakdown = service.explainMetaScore(
      player,
      'ST',
      chemistry: 2,
      selectedRole: 'Advanced Forward',
    );

    expect(breakdown.playStylesPlusCount, 2);
    expect(breakdown.playStylesPlusBonus, closeTo(4.4, 1e-9));
    expect(breakdown.playStylesBonus, closeTo(0.35, 1e-9));
    expect(breakdown.chemistryBonus, closeTo(3.2, 1e-9));
    expect(breakdown.roleFit, isTrue);
    expect(breakdown.roleBonus, 3.0);
    expect(
      breakdown.total,
      closeTo(
        (breakdown.base +
                breakdown.playStylesPlusBonus +
                breakdown.playStylesBonus +
                breakdown.chemistryBonus +
                breakdown.roleBonus)
            .clamp(0, 100),
        1e-9,
      ),
    );
    expect(
      service.playerMetaScore(
        player,
        'ST',
        chemistry: 2,
        selectedRole: 'Advanced Forward',
      ),
      breakdown.total,
    );
  });

  test('goalkeeper and off-role breakdowns stay data driven', () {
    final service = SquadInsightsService();
    final keeper = _player(
      name: 'دروازه‌بان',
      rating: 85,
      position: 'GK',
      playStyles: const [],
      playStylesPlus: const [],
      roles: const [],
    );

    final breakdown = service.explainMetaScore(
      keeper,
      'GK',
      chemistry: 3,
      selectedRole: '',
    );

    expect(breakdown.base, 85);
    expect(breakdown.roleFit, isFalse);
    expect(breakdown.roleBonus, 0);
    expect(breakdown.chemistryBonus, closeTo(4.8, 1e-9));
  });

  testWidgets('replacement sheet explains the score comparison honestly', (
    tester,
  ) async {
    final service = SquadInsightsService();
    final currentPlayer = _player(
      id: 'p-old',
      name: 'بازیکن فعلی',
      rating: 80,
      playStyles: const ['Finesse Shot'],
      playStylesPlus: const ['Power Shot'],
    );
    final replacement = _player(
      id: 'p-new',
      name: 'بازیکن جایگزین',
      rating: 88,
      playStyles: const ['Finesse Shot', 'Ping Pass', 'Quick Step', 'Trivela'],
      playStylesPlus: const ['Power Shot', 'Trivela', 'Finesse Shot+'],
    );
    final suggestion = SquadReplacementSuggestion(
      slotId: 'st',
      currentPlayer: currentPlayer,
      replacement: replacement,
      currentScore: 0,
      replacementScore: 0,
      price: 150000,
    );
    const slotDetail = ChemistrySlotDetail(
      slotId: 'st',
      chemistry: 1,
      inPosition: true,
      clubCount: 2,
      leagueCount: 3,
      nationCount: 4,
      managerMatch: true,
      specialCard: false,
    );
    final expectedCurrent = service.explainMetaScore(
      currentPlayer,
      'ST',
      chemistry: slotDetail.chemistry,
      selectedRole: '',
    );
    final expectedCandidate = service.explainMetaScore(
      replacement,
      'ST',
      chemistry: 0,
      selectedRole: '',
    );
    final expectedGain = expectedCandidate.total - expectedCurrent.total;
    expect(expectedGain, greaterThan(0));

    await tester.pumpWidget(
      _host(
        () => showReplacementExplanation(
          tester.element(find.text('open')),
          suggestion: suggestion,
          slotPosition: 'ST',
          platform: 'console',
          currentSlotChemistry: slotDetail,
          currentRole: '',
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('چرا این پیشنهاد؟'), findsOneWidget);
    expect(find.textContaining('بازیکن جایگزین برای پست ST'), findsOneWidget);
    expect(find.text('امتیاز فعلی'), findsOneWidget);
    expect(find.text(_fa(expectedCurrent.total)), findsOneWidget);
    expect(find.text('امتیاز جایگزین'), findsOneWidget);
    expect(find.text(_fa(expectedCandidate.total)), findsOneWidget);
    expect(find.text('افزایش متا'), findsOneWidget);
    expect(find.text('+${_fa(expectedGain)}'), findsOneWidget);
    expect(find.textContaining('شیمی صفر'), findsOneWidget);
    expect(find.textContaining('رتبه رسمی EA نیست'), findsOneWidget);
    expect(find.textContaining('۱۵۰'), findsWidgets);
  });

  testWidgets('weakness sheet shows real chemistry counts and rules', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        () => showWeaknessExplanation(
          tester.element(find.text('open')),
          issue: const SquadWeakness(
            title: 'Chemistry پایین',
            detail: 'مهدی طارمی در حال حاضر 1 Chemistry دارد.',
            severity: 3,
            slotId: 'st',
          ),
          player: _player(),
          slotPosition: 'ST',
          slotDetail: const ChemistrySlotDetail(
            slotId: 'st',
            chemistry: 1,
            inPosition: true,
            clubCount: 2,
            leagueCount: 3,
            nationCount: 4,
            managerMatch: true,
            specialCard: false,
          ),
          role: 'Advanced Forward',
          focus: 'Attack',
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('چرا این نکته؟'), findsOneWidget);
    expect(find.text('هشدار'), findsOneWidget);
    expect(find.text('شیمی این بازیکن'), findsOneWidget);
    expect(find.text('۱/۳'), findsOneWidget);
    expect(find.text('در پست معتبر'), findsOneWidget);
    expect(find.text('باشگاه هم‌نام در ترکیب'), findsOneWidget);
    expect(find.text('۲'), findsOneWidget);
    expect(find.text('سرمربی'), findsOneWidget);
    expect(find.text('کارت ویژه'), findsNothing);
    expect(find.textContaining('Icon، Hero و Hall of FUT'), findsOneWidget);
    expect(find.textContaining('پست معتبر'), findsWidgets);
  });

  testWidgets('explain sheet fits a 320px wide screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(
        () => showReplacementExplanation(
          tester.element(find.text('open')),
          suggestion: SquadReplacementSuggestion(
            slotId: 'st',
            currentPlayer: _player(id: 'p-old', name: 'بازیکن فعلی'),
            replacement: _player(id: 'p-new', name: 'بازیکن جایگزین'),
            currentScore: 0,
            replacementScore: 0,
            price: 9900000,
          ),
          slotPosition: 'ST',
          platform: 'pc',
          currentSlotChemistry: null,
          currentRole: '',
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('چرا این پیشنهاد؟'), findsOneWidget);
  });

  test('insights panel exposes the explanation entry points', () {
    final panel = readSourceBundle(
      'lib/features/squad/presentation/squad_insights_panel.dart',
    );
    expect(panel, contains('showReplacementExplanation('));
    expect(panel, contains('showWeaknessExplanation('));
    expect(panel, contains('دلیل این پیشنهاد'));
  });
}
