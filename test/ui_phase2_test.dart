import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/players/presentation/player_details_screen.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/source_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Jalali dates and Persian digits use local formatting', () {
    expect(faDigits('1405/08/01'), '۱۴۰۵/۰۸/۰۱');
    expect(formatJalaliDate(DateTime(2026, 10, 23)), 'جمعه ۱ آبان ۱۴۰۵');
    expect(formatJalaliDate(DateTime(2024, 3, 20)), 'چهارشنبه ۱ فروردین ۱۴۰۳');
    expect(formatJalaliShort(DateTime(2026, 10, 23)), '۱ آبان');
  });

  test('relative deadlines stay Persian and truthful', () {
    final now = DateTime(2026, 10, 23, 12);
    expect(
      relativeDeadlineFa(now.add(const Duration(minutes: 30)), now: now),
      '۳۰ دقیقه مانده',
    );
    expect(
      relativeDeadlineFa(now.add(const Duration(hours: 2)), now: now),
      '۲ ساعت مانده',
    );
    expect(
      relativeDeadlineFa(now.add(const Duration(days: 2)), now: now),
      '۲ روز مانده',
    );
    expect(
      relativeDeadlineFa(now.subtract(const Duration(hours: 1)), now: now),
      'پایان یافته',
    );
    expect(
      relativeTimeFa(now.subtract(const Duration(minutes: 5)), now: now),
      '۵ دقیقه پیش',
    );
  });

  test('compact coin values never invent a price', () {
    expect(compactCoinsFa(0), '—');
    expect(compactCoinsFa(850000), '۸۵۰K');
    expect(compactCoinsFa(1200000), '۱.۲M');
  });

  test('player details source exposes the approved phase 2 structure', () {
    final source = readSourceBundle(
      'lib/features/players/presentation/player_details_screen.dart',
    );

    expect(source, contains('NestedScrollView'));
    expect(source, contains('SegmentedTabs'));
    for (final tab in ['نمای کلی', 'آمار', 'استایل‌ها', 'بازار', 'یادداشت']) {
      expect(source, contains("'$tab'"));
    }
    expect(source, contains('PlayerMarketPanel'));
    expect(source, contains("kicker: 'OTHER VERSIONS'"));
    expect(source, contains("'افزودن به باشگاه'"));
    expect(source, contains("'مقایسه'"));
    expect(source, contains('SourceBadge'));
    expect(source, contains("source: 'FC27 Catalog'"));
  });

  testWidgets('details renders sticky tabs and bottom actions at 320px', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const player = Player(
      id: 'test-player',
      name: 'Test Player',
      rating: 88,
      position: 'ST',
      positions: ['ST'],
      clubName: 'Test Club',
      leagueName: 'Test League',
      nationName: 'Testland',
      version: 'Gold',
      imageUrl: '',
      pace: 90,
      shooting: 88,
      passing: 80,
      dribbling: 85,
      defending: 40,
      physical: 75,
      skillMoves: 4,
      weakFoot: 4,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fa'),
        supportedLocales: const [Locale('fa')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: FCBazTheme.dark(),
        home: const PlayerDetailsScreen(player: player),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('PLAYER ITEM'), findsOneWidget);
    expect(find.text('نمای کلی'), findsOneWidget);
    expect(find.text('آمار'), findsOneWidget);
    expect(find.text('استایل‌ها'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'بازار'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'یادداشت'), findsOneWidget);
    expect(find.text('مقایسه'), findsOneWidget);
    expect(find.text('افزودن به باشگاه'), findsOneWidget);
    expect(find.text('جایگزین ارزان‌تر'), findsNothing);

    await tester.tap(find.widgetWithText(Tab, 'آمار'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('آمار چهره'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'نمای کلی'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('قیمت بازار'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('priced cards get a cheaper-alternative section', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const player = Player(
      id: 'priced-player',
      name: 'Priced Player',
      rating: 88,
      position: 'ST',
      positions: ['ST'],
      clubName: 'Test Club',
      leagueName: 'Test League',
      nationName: 'Testland',
      version: 'Gold',
      imageUrl: '',
      pace: 90,
      shooting: 88,
      passing: 80,
      dribbling: 85,
      defending: 40,
      physical: 75,
      skillMoves: 4,
      weakFoot: 4,
      pricePs: 100000,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fa'),
        supportedLocales: const [Locale('fa')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: FCBazTheme.dark(),
        home: const PlayerDetailsScreen(player: player),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.drag(find.text('قیمت بازار'), const Offset(0, -400));
    await tester.pump();

    expect(find.text('جایگزین ارزان‌تر'), findsOneWidget);
    expect(
      find.textContaining('کارت هم‌پستی با حداکثر ۲ ریتینگ کمتر'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
