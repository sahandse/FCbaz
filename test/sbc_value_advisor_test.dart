import 'package:fcbaz/features/sbc/domain/sbc.dart';
import 'package:fcbaz/features/sbc/domain/sbc_value_advisor.dart';
import 'package:fcbaz/features/sbc/presentation/sbc_value_badge.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/source_bundle.dart';

void main() {
  const advisor = SbcValueAdvisor();

  test('coin parsing only reads explicit coin amounts', () {
    expect(SbcValueAdvisor.parseCoins('۱ عدد بسته + ۵,۰۰۰ سکه'), 5000);
    expect(SbcValueAdvisor.parseCoins('Pack + 1,000 Coins'), 1000);
    expect(SbcValueAdvisor.parseCoins('۲K سکه'), 2000);
    expect(SbcValueAdvisor.parseCoins('۱ عدد بستهٔ بازیکن ۸۰+'), 0);
    expect(SbcValueAdvisor.parseCoins(''), 0);
  });

  test('pack rewards keep the value honest and unknown', () {
    final value = advisor.assess(
      cost: 5000,
      reward: '۱ عدد بستهٔ بازیکن طلایی ۵× ۸۰+',
      category: 'Upgrades',
      title: '5x 80+ Upgrade',
    );

    expect(value.kind, SbcRewardKind.packs);
    expect(value.ratio, isNull);
    expect(value.level, SbcValueLevel.unknown);
    expect(value.headlineFa, 'ارزش پاداش نامشخص');
    expect(value.detailFa, contains('۵,۰۰۰'));
  });

  test('coin-return ratio uses only the real estimated cost', () {
    final good = advisor.assess(
      cost: 5000,
      reward: '۱ عدد بسته + ۵,۰۰۰ سکه',
      category: 'Challenges',
      title: 'League & Nation Advanced',
    );
    expect(good.kind, SbcRewardKind.mixed);
    expect(good.ratio, closeTo(1, .0001));
    expect(good.level, SbcValueLevel.good);
    expect(good.headlineFa, contains('۱۰۰٪'));

    final fair = advisor.assess(
      cost: 10000,
      reward: '۵,۰۰۰ سکه',
      category: 'Challenges',
      title: 'Coins',
    );
    expect(fair.kind, SbcRewardKind.coins);
    expect(fair.level, SbcValueLevel.fair);

    final poor = advisor.assess(
      cost: 20000,
      reward: '۵,۰۰۰ سکه',
      category: 'Challenges',
      title: 'Coins',
    );
    expect(poor.level, SbcValueLevel.poor);
    expect(poor.headlineFa, contains('۲۵٪'));
  });

  test('player SBC cards are never valued against a base card', () {
    final value = advisor.assess(
      cost: 26400,
      reward: '',
      category: 'Players',
      title: 'Carlos Augusto',
    );

    expect(value.kind, SbcRewardKind.playerCard);
    expect(value.ratio, isNull);
    expect(value.headlineFa, 'قیمت کارت جایزه نامشخص');
    expect(value.detailFa, contains('Carlos Augusto'));
    expect(value.detailFa, contains('کارت پایه'));
  });

  test('a missing cost stays unknown instead of zero', () {
    final value = advisor.assess(
      cost: null,
      reward: '۵,۰۰۰ سکه',
      category: 'Challenges',
      title: 'Unknown',
    );

    expect(value.level, SbcValueLevel.unknown);
    expect(value.headlineFa, 'هزینهٔ ساخت نامشخص');
  });

  test('SBC parsing falls back to the public solution cost', () {
    final item = SbcChallenge.fromJson({
      'id': 'sbc-1',
      'title': 'Carlos Augusto',
      'category': 'Players',
      'public_solution': {'total_cost': 26400},
    });
    expect(item.estimatedCost, 26400);

    final explicit = SbcChallenge.fromJson({
      'id': 'sbc-2',
      'title': 'Explicit',
      'estimated_cost': 1200,
      'public_solution': {'total_cost': 26400},
    });
    expect(explicit.estimatedCost, 1200);
  });

  testWidgets('value badge explains itself on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final value = advisor.assess(
      cost: 4300,
      reward: '۱ عدد بسته + ۵,۰۰۰ سکه',
      category: 'Challenges',
      title: 'Marquee Matchups',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: FCBazTheme.dark(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: SbcValueBadge(assessment: value, showDetail: true),
          ),
        ),
      ),
    );

    expect(find.text(value.headlineFa), findsOneWidget);
    expect(find.text(value.detailFa), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('SBC screens use the verified value badge', () {
    final screen = readSourceBundle(
      'lib/features/sbc/presentation/sbc_screen.dart',
    );
    expect(screen, contains('SbcValueBadge'));
    expect(screen, contains('SbcValueAdvisor'));
    expect(
      readSourceBundle('lib/features/sbc/domain/sbc.dart'),
      contains('public_solution'),
    );
  });
}
