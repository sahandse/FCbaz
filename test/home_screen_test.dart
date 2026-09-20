import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/home/home_screen.dart';

void main() {
  testWidgets('FCBaz home renders Persian dashboard', (tester) async {
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
    expect(find.text('دسترسی سریع'), findsOneWidget);
    expect(find.text('بازیکنان'), findsOneWidget);
    expect(find.text('تیم‌ساز'), findsOneWidget);
  });
}
