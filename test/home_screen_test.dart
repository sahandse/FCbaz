import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/home/home_screen.dart';

void main() {
  testWidgets('FCBaz home renders main Persian dashboard actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          onOpenPlayers: () {},
          onOpenSearch: () {},
          onOpenSquad: () {},
          onOpenMore: () {},
        ),
      ),
    );

    await tester.pump();

    expect(find.text('FCBaz'), findsOneWidget);
    expect(find.text('FC27 • Ultimate Team'), findsOneWidget);
    expect(find.text('بازیکنان'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('تیم‌ساز'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('تیم‌ساز'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('جستجو'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('جستجو'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('ابزارها'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ابزارها'), findsOneWidget);
  });
}
