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

    expect(find.text('FCBaz'), findsOneWidget);
    expect(find.text('FC27 • Ultimate Team'), findsOneWidget);
    expect(find.text('بازیکنان'), findsWidgets);
    expect(find.text('تیم‌ساز'), findsOneWidget);
    expect(find.text('جستجو'), findsOneWidget);
    expect(find.text('ابزارها'), findsOneWidget);
  });
}
