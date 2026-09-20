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

    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();

    expect(find.text('دسترسی سریع'), findsOneWidget);
  });
}
