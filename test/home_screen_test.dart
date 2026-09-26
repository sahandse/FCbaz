import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/home/home_dashboard_screen.dart';

void main() {
  testWidgets('FCBaz home renders the 1.5 FC27 club hub', (tester) async {
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

    expect(find.text('FC27'), findsOneWidget);
    expect(find.text('YOUR CLUB.\nYOUR MARKET.'), findsOneWidget);
    expect(find.text('بازیکنان'), findsOneWidget);
    expect(find.text('جستجو'), findsOneWidget);
    expect(find.text('HOT ITEMS'), findsOneWidget);
    expect(find.text('LIVE HUB'), findsOneWidget);
  });
}
