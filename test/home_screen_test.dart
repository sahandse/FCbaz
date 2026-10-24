import 'package:fcbaz/features/home/home_dashboard_screen.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home renders the FUT Stadium hero and daily sections', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var openedPlayers = false;
    var openedClub = false;

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
        home: Scaffold(
          body: HomeDashboardScreen(
            onOpenPlayers: () => openedPlayers = true,
            onOpenClub: () => openedClub = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpAndSettle();

    expect(find.text('FC27 • ULTIMATE TEAM'), findsOneWidget);
    expect(find.text(formatJalaliDate(DateTime.now())), findsOneWidget);
    expect(find.text('باشگاهت را بساز.'), findsOneWidget);
    expect(find.text('امروز'), findsOneWidget);

    await tester.tap(find.text('افزودن کارت'));
    expect(openedPlayers, isTrue);

    await tester.tap(find.text('باشگاه'));
    expect(openedClub, isTrue);

    await tester.scrollUntilVisible(
      find.text('کارت‌های داغ'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('کارت‌های داغ'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('دسترسی سریع'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('چالش‌ها'), findsOneWidget);
    expect(find.text('ایوولوشن'), findsOneWidget);
    expect(find.text('اهداف'), findsOneWidget);
    expect(find.text('بازار'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('منبع: FC27 Hub'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('منبع: FC27 Hub'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
