import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/home/home_dashboard_screen.dart';

void main() {
  testWidgets('FCBaz home renders the v1.2 Persian hero', (tester) async {
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
    expect(find.text('Ultimate Team companion • FC27'), findsOneWidget);
    expect(find.text('دیتای واقعی، ابزارهای سریع، بدون ثبت‌نام.'), findsOneWidget);
    expect(find.text('جستجوی بازیکن'), findsOneWidget);
    expect(find.text('بازیکنان داغ بازار'), findsOneWidget);
  });
}
