import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/home/home_dashboard_screen.dart';

void main() {
  testWidgets('FCBaz home renders local-first Persian dashboard actions', (tester) async {
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
    expect(
      find.text('داشبورد شخصی FC27؛ بدون ثبت‌نام، با داده محلی خودت و اطلاعات زنده واقعی.'),
      findsOneWidget,
    );
    expect(find.text('جستجو'), findsOneWidget);
    expect(find.text('بازیکنان'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('دسترسی سریع'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('دسترسی سریع'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('ساخت ترکیب'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ساخت ترکیب'), findsOneWidget);
    expect(find.text('بازار'), findsOneWidget);
    expect(find.text('همه ابزارها'), findsOneWidget);
  });
}
