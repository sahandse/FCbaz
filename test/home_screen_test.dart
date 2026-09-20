import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/home/home_screen.dart';

void main() {
  testWidgets('FCBaz home renders Persian content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(onOpenPlayers: () {}),
      ),
    );

    expect(find.text('همه چیز درباره FC27'), findsOneWidget);
    expect(find.text('دسترسی سریع'), findsOneWidget);
  });
}
