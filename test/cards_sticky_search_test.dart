import 'package:fcbaz/features/players/presentation/cards_screen.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('cards search stays pinned with filter chips at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'fcbaz_tab_schema': 2});

    await tester.pumpWidget(
      MaterialApp(
        theme: FCBazTheme.dark(),
        home: const Scaffold(body: CardsScreen()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SliverPersistentHeader), findsOneWidget);

    final searchBefore = tester.getRect(find.byType(TextField).first);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -260));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final searchAfter = tester.getRect(find.byType(TextField).first);

    expect(tester.takeException(), isNull);
    expect(searchAfter.top, lessThanOrEqualTo(96));
    expect(searchAfter.top, greaterThanOrEqualTo(0));
    expect(searchAfter.left, searchBefore.left);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 260));
    await tester.pump();
    await tester.tap(find.text('Gold'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(tester.takeException(), isNull);
    expect(find.text('کمیابی Gold'), findsOneWidget);
    final pinned = tester.getRect(find.byType(TextField).first);
    expect(pinned.top, lessThanOrEqualTo(96));
  });
}
