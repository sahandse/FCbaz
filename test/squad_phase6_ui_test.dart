import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/squad/domain/chemistry_engine.dart';
import 'package:fcbaz/features/squad/domain/squad_models.dart';
import 'package:fcbaz/features/squad/presentation/squad_insights_panel.dart';

void main() {
  testWidgets('Squad insights renders Persian dashboard and real-data notice', (tester) async {
    const squad = SquadStateModel(
      id: 'test',
      name: 'ترکیب تست',
      formationId: '433',
      playersBySlot: {},
      tactics: TacticProfile(
        name: 'پلن اصلی',
        buildUpStyle: 'Balanced',
        defensiveApproach: 'High',
        lineHeight: 70,
      ),
    );

    const chemistry = ChemistryResult(
      total: 0,
      bySlot: {},
      filledSlots: 0,
      inPositionSlots: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SquadInsightsPanel(
              squad: squad,
              formation: Formations.byId('433'),
              chemistry: chemistry,
              onReplace: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('تحلیل ترکیب'), findsOneWidget);
    expect(find.textContaining('ساخت بازی'), findsOneWidget);
    expect(find.textContaining('متعادل'), findsOneWidget);
    expect(find.text('جزئیات شیمی تیم'), findsOneWidget);
    expect(find.text('پیدا کردن ارتقای واقعی'), findsOneWidget);
  });
}
