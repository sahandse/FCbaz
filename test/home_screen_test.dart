import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/home/home_dashboard_screen.dart';

void main() {
  testWidgets('FCBaz home renders the v1.2 Persian live dashboard', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeDashboardScreen(
          onOpenPlayers: () {},
          onOpenSearch: () {},
          onOpenSquad: () {},
          onOpenMore: () {},
        ),
      ),
    );

    await tester.pump();

    expect(find.text('FCBaz'), findsOneWidget);
    expect(find.text('بازیکنان داغ بازار'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Live Hub'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Live Hub'), findsOneWidget);
    expect(find.textContaining('بدون داده ساختگی'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('SBC'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('SBC'), findsOneWidget);
    expect(find.text('Evolutions'), findsOneWidget);
    expect(find.text('Objectives'), findsOneWidget);
  });
}
