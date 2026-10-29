import 'package:fcbaz/src/ui/fade_through_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe extends StatefulWidget {
  const _Probe({required this.label, required this.onCreated});

  final String label;
  final VoidCallback onCreated;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int taps = 0;

  @override
  void initState() {
    super.initState();
    widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => setState(() => taps++),
        child: Text('${widget.label}:$taps'),
      ),
    );
  }
}

List<double> _opacities(WidgetTester tester) {
  return tester
      .widgetList<Opacity>(
        find.descendant(
          of: find.byType(FadeThroughStack),
          matching: find.byType(Opacity),
        ),
      )
      .map((widget) => widget.opacity)
      .toList();
}

void main() {
  testWidgets('keeps hidden tabs mounted and cross-fades between them', (
    tester,
  ) async {
    var index = 0;
    late StateSetter apply;
    var createdA = 0;
    var createdB = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              apply = setState;
              return FadeThroughStack(
                index: index,
                children: [
                  _Probe(label: 'A', onCreated: () => createdA++),
                  _Probe(label: 'B', onCreated: () => createdB++),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(createdA, 1);
    expect(createdB, 1);
    expect(find.byType(_Probe), findsNWidgets(2));
    expect(_opacities(tester), [1.0, 0.0]);

    await tester.tap(find.text('A:0'));
    await tester.pump();
    expect(find.text('A:1'), findsOneWidget);

    apply(() => index = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    final mid = _opacities(tester);
    expect(mid.any((value) => value > 0 && value < 1), isTrue);
    expect(mid[0], lessThan(1));
    expect(mid[1], greaterThan(0));

    await tester.pump(const Duration(milliseconds: 400));

    expect(_opacities(tester), [0.0, 1.0]);
    // Hidden tabs keep their state instead of being rebuilt from scratch.
    expect(createdA, 1);
    expect(createdB, 1);
    expect(find.text('A:1'), findsOneWidget);
  });

  testWidgets('reduced motion switches tabs without a fade', (tester) async {
    var index = 0;
    late StateSetter apply;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                apply = setState;
                return FadeThroughStack(
                  index: index,
                  children: const [
                    Center(child: Text('A')),
                    Center(child: Text('B')),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    apply(() => index = 1);
    await tester.pump();

    expect(_opacities(tester), [0.0, 1.0]);
  });
}
