import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/ui/content_status_chips.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/source_bundle.dart';

Widget _app(Widget child) {
  return MaterialApp(
    theme: FCBazTheme.dark(),
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(child: child),
      ),
    ),
  );
}

void main() {
  final now = DateTime(2026, 10, 23, 12);

  test('content freshness follows the documented boundaries', () {
    expect(
      contentFreshness(now.subtract(const Duration(minutes: 1)), now: now),
      ContentFreshness.expired,
    );
    expect(
      contentFreshness(now.add(const Duration(hours: 2)), now: now),
      ContentFreshness.urgent,
    );
    expect(
      contentFreshness(now.add(const Duration(hours: 23)), now: now),
      ContentFreshness.closingSoon,
    );
    expect(
      contentFreshness(now.add(const Duration(hours: 25)), now: now),
      ContentFreshness.active,
    );
  });

  test('news freshness uses real parsed dates only', () {
    final published = parseFeedDate('October 22, 2026');
    expect(published, DateTime(2026, 10, 22));
    expect(isFreshContent(published, now: now), isTrue);
    expect(isFreshContent(parseFeedDate('October 1, 2026'), now: now), isFalse);
    expect(isFreshContent(null, now: now), isFalse);
    expect(parseFeedDate(''), isNull);
    expect(parseFeedDate('not a date'), isNull);
  });

  testWidgets('repeatable renders even when no deadline exists', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const ContentStatusChips(repeatable: true)));

    expect(find.text('قابل تکرار'), findsOneWidget);
    expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
  });

  testWidgets('expired deadlines are labeled as expired', (tester) async {
    await tester.pumpWidget(
      _app(
        ContentStatusChips(
          expiresAt: now.subtract(const Duration(hours: 1)),
          now: now,
        ),
      ),
    );

    expect(find.text('منقضی'), findsOneWidget);
    expect(find.byIcon(Icons.event_busy_rounded), findsOneWidget);
  });

  testWidgets('urgent deadlines keep the live countdown', (tester) async {
    await tester.pumpWidget(
      _app(
        ContentStatusChips(
          expiresAt: now.add(const Duration(hours: 2)),
          now: now,
        ),
      ),
    );

    expect(find.text('۲ ساعت مانده'), findsOneWidget);
    expect(find.byIcon(Icons.timer_rounded), findsOneWidget);
  });

  testWidgets('SBC chips can append the real Jalali deadline date', (
    tester,
  ) async {
    final expiresAt = now.add(const Duration(days: 3));
    await tester.pumpWidget(
      _app(
        ContentStatusChips(
          expiresAt: expiresAt,
          now: now,
          showJalaliDate: true,
        ),
      ),
    );

    expect(find.textContaining(formatJalaliShort(expiresAt)), findsOneWidget);
    expect(find.textContaining('مانده'), findsOneWidget);
  });

  testWidgets('fresh news gets a quiet badge and stale news gets none', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ContentStatusChips(
          publishedAt: parseFeedDate('October 22, 2026'),
          now: now,
        ),
      ),
    );
    expect(find.text('تازه'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        ContentStatusChips(
          publishedAt: parseFeedDate('September 1, 2026'),
          now: now,
        ),
      ),
    );
    expect(find.text('تازه'), findsNothing);
  });

  testWidgets('nothing is fabricated without source data', (tester) async {
    await tester.pumpWidget(_app(const ContentStatusChips()));

    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chips fit on a 320px wide screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        ContentStatusChips(
          expiresAt: now.add(const Duration(hours: 2)),
          repeatable: true,
          publishedAt: parseFeedDate('October 22, 2026'),
          now: now,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('قابل تکرار'), findsOneWidget);
    expect(find.text('تازه'), findsOneWidget);
  });

  test('SBC, Evolutions, Objectives and News share the status component', () {
    for (final path in [
      'lib/features/sbc/presentation/sbc_screen.dart',
      'lib/features/evolutions/presentation/evolutions_screen.dart',
      'lib/features/home/objectives_screen.dart',
      'lib/features/news/presentation/news_screen.dart',
    ]) {
      expect(
        readSourceBundle(path),
        contains('ContentStatusChips'),
        reason: '$path should use the unified content status chips',
      );
    }
    expect(
      readSourceBundle('lib/features/sbc/presentation/sbc_screen.dart'),
      isNot(contains("'REPEATABLE'")),
    );
    expect(
      readSourceBundle(
        'lib/features/evolutions/presentation/evolutions_screen.dart',
      ),
      isNot(contains("'EXPIRES'")),
    );
  });
}
