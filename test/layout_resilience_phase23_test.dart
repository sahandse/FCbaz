import 'package:fcbaz/features/more/more_screen.dart';
import 'package:fcbaz/features/news/presentation/news_screen.dart';
import 'package:fcbaz/features/settings/app_settings_repository.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('more tools grid fits a 320px screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: FCBazTheme.dark(),
        locale: const Locale('fa'),
        home: Scaffold(
          body: MoreScreen(
            settings: const AppSettings(),
            onSettingsChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ابزارهای اصلی'), findsOneWidget);
    expect(find.text('بازار'), findsOneWidget);
    expect(find.text('چالش‌های ساخت ترکیب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('embedded news feed renders its sourced content at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: FCBazTheme.dark(),
        locale: const Locale('fa'),
        home: const Scaffold(body: NewsScreen(embedded: true)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('اخبار و رویدادهای FC 27'), findsOneWidget);
    expect(find.text('پایگاه رسمی اخبار EA SPORTS FC 27'), findsOneWidget);
    expect(find.text('آخرین اطلاعیه‌ها'), findsOneWidget);
    expect(find.text('اخبار در دسترس نیست'), findsNothing);
    expect(find.byType(FilterChip), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
