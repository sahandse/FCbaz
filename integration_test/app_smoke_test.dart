import 'package:fcbaz/src/fcbaz_app.dart';
import 'package:fcbaz/src/ui/fcbaz_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app launches and switches between primary tabs', (tester) async {
    await tester.pumpWidget(const FCBazApp());
    await _pumpUntil(tester, find.byType(NavigationBar));

    NavigationBar navigationBar() =>
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    FcbazTopBar topBar() => tester.widget<FcbazTopBar>(find.byType(FcbazTopBar));

    expect(navigationBar().destinations, hasLength(5));
    expect(navigationBar().selectedIndex, 0);
    expect(topBar().title, 'اخبار');

    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(navigationBar().selectedIndex, 1);
    expect(topBar().title, 'کارت‌ها');

    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(navigationBar().selectedIndex, 4);
    expect(topBar().title, 'بیشتر');
  });
}
