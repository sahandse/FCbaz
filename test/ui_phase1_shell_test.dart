import 'dart:io';

import 'package:fcbaz/features/navigation/app_navigation_repository.dart';
import 'package:fcbaz/features/players/presentation/cards_screen.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/ui/fcbaz_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('old search tab migrates to cards exactly once', () async {
    SharedPreferences.setMockInitialValues({'fcbaz_last_tab': 2});
    final repository = AppNavigationRepository();

    expect(await repository.loadTab(), 1);

    await repository.saveTab(2);
    expect(await repository.loadTab(), 2);
  });

  test('out of range persisted tabs fall back to home', () async {
    SharedPreferences.setMockInitialValues({
      'fcbaz_last_tab': 9,
      'fcbaz_tab_schema': 2,
    });
    expect(await AppNavigationRepository().loadTab(), 0);

    SharedPreferences.setMockInitialValues({
      'fcbaz_last_tab': -3,
      'fcbaz_tab_schema': 2,
    });
    expect(await AppNavigationRepository().loadTab(), 0);
  });

  test('shell exposes exactly the five approved tabs', () {
    final source = File(
      'lib/features/navigation/main_shell.dart',
    ).readAsStringSync();
    for (final label in ['اخبار', 'کارت‌ها', 'باشگاه', 'تیم', 'بیشتر']) {
      expect(source, contains("label: '$label'"));
    }
    expect(source, isNot(contains("label: 'جستجو'")));
    expect(source, contains('CardsScreen(focusRequests: searchRequests)'));
    expect(source, contains('MyClubScreen(embedded: true)'));
    expect(source, contains('FcbazTopBar'));
  });

  test('cards tab folds search discovery and filters into one screen', () {
    final source = File(
      'lib/features/players/presentation/cards_screen.dart',
    ).readAsStringSync();
    expect(source, contains('Duration(milliseconds: 250)'));
    expect(source, contains('AdvancedPlayerFilterSheet'));
    expect(source, contains('کارت‌های داغ'));
    expect(source, contains('جستجوهای اخیر'));
    expect(source, contains('نماهای ذخیره‌شده'));
    expect(source, contains('PlayerGridSkeleton'));
    expect(source, contains('searchFocus.requestFocus()'));
  });

  testWidgets('top bar shows the page title and both actions', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: FCBazTheme.dark(),
        home: Scaffold(
          appBar: FcbazTopBar(
            title: 'کارت‌ها',
            onSearch: () {},
            onNotifications: () {},
            unread: 3,
          ),
        ),
      ),
    );

    expect(find.text('کارت‌ها'), findsOneWidget);
    expect(find.text('FC27 • ULTIMATE TEAM'), findsOneWidget);
    expect(find.byTooltip('جستجوی سراسری'), findsOneWidget);
    expect(find.byTooltip('اعلان‌ها'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    final bell = tester.getRect(find.byTooltip('اعلان‌ها'));
    final label = tester.getRect(find.text('3'));
    expect(label.left, greaterThanOrEqualTo(bell.left - 8));
    expect(label.right, lessThanOrEqualTo(bell.right + 8));
    expect(label.top, greaterThanOrEqualTo(bell.top - 8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('global search request focuses the cards query field', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'fcbaz_tab_schema': 2});
    final requests = ValueNotifier<int>(0);
    addTearDown(requests.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: FCBazTheme.dark(),
        home: Scaffold(body: CardsScreen(focusRequests: requests)),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode?.hasFocus, isFalse);

    requests.value++;
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus,
      isTrue,
    );
  });
}
