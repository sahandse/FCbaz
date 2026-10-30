import 'package:fcbaz/features/squad/presentation/chemistry_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, int value) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(child: ChemistryDiamonds(value: value)),
      ),
    ),
  );
}

void main() {
  testWidgets('diamonds fill exactly up to the earned chemistry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, 2);

    expect(find.byKey(const ValueKey('chem-diamond-filled')), findsNWidgets(2));
    expect(find.byKey(const ValueKey('chem-diamond-empty')), findsOneWidget);
    expect(find.bySemanticsLabel('شیمی ۲ از ۳'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('diamonds stay empty at zero and clamp above three', (
    tester,
  ) async {
    await _pump(tester, 0);
    expect(find.byKey(const ValueKey('chem-diamond-filled')), findsNothing);
    expect(find.byKey(const ValueKey('chem-diamond-empty')), findsNWidgets(3));

    await _pump(tester, 9);
    expect(find.byKey(const ValueKey('chem-diamond-filled')), findsNWidgets(3));
    expect(find.byKey(const ValueKey('chem-diamond-empty')), findsNothing);
  });
}
