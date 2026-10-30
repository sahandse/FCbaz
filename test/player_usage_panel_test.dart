import 'package:fcbaz/features/evolutions/domain/evolution.dart';
import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/players/presentation/widgets/player_usage_panel.dart';
import 'package:fcbaz/features/sbc/domain/sbc.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const player = Player(
    id: 'p1',
    name: 'Test Player',
    rating: 80,
    position: 'RW',
    positions: ['RW'],
    clubName: 'Club',
    leagueName: 'League',
    nationName: 'Nation',
    version: 'Gold Rare',
    imageUrl: '',
    pace: 80,
    shooting: 80,
    passing: 80,
    dribbling: 80,
    defending: 40,
    physical: 70,
    skillMoves: 3,
    weakFoot: 3,
  );

  final eligibleEvo = Evolution.fromJson({
    'id': 'evo-1',
    'title': 'Evo One',
    'requirements_raw': [
      {'type': 'overall', 'max': 84},
    ],
  });

  final passingSbc = SbcChallenge.fromJson({
    'id': 'sbc-pass',
    'title': 'Passing SBC',
    'requirements': ['Rating: Min. 79', 'Min. 5 Gold players'],
  });

  final blockedSbc = SbcChallenge.fromJson({
    'id': 'sbc-block',
    'title': 'Blocked SBC',
    'requirements': ['Rating: Min. 90'],
  });

  Widget host(Widget panel) => MaterialApp(
    theme: FCBazTheme.dark(),
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(child: panel),
      ),
    ),
  );

  testWidgets('shows usage summaries for evolutions and SBCs', (tester) async {
    await tester.pumpWidget(
      host(
        PlayerUsagePanel(
          player: player,
          loading: false,
          evolutions: [eligibleEvo],
          sbcChallenges: [passingSbc, blockedSbc],
          evolutionsError: null,
          sbcError: null,
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('Evolutionها'), findsOneWidget);
    expect(find.text('SBCهای فعال'), findsOneWidget);
    expect(
      find.text('۱ قابل استفاده • ۰ نیازمند بررسی • ۰ نامناسب'),
      findsOneWidget,
    );
    expect(
      find.text('۱ شرط کارتی پاس • ۰ وابسته به ترکیب • ۱ قابل استفاده نیست'),
      findsOneWidget,
    );
    expect(find.textContaining('نتیجهٔ قطعی نمی‌سازد'), findsOneWidget);
  });

  testWidgets('expands SBC rows with honest status text', (tester) async {
    await tester.pumpWidget(
      host(
        PlayerUsagePanel(
          player: player,
          loading: false,
          evolutions: const [],
          sbcChallenges: [passingSbc, blockedSbc],
          evolutionsError: null,
          sbcError: null,
          onRetry: () {},
        ),
      ),
    );

    await tester.tap(find.text('SBCهای فعال'));
    await tester.pumpAndSettle();

    expect(find.text('شرط کارتی پاس'), findsOneWidget);
    expect(find.text('قابل استفاده نیست'), findsOneWidget);
    expect(
      find.text('شرط‌های کارتی پاس شدند؛ ۱ شرط دیگر به ترکیب بستگی دارد.'),
      findsOneWidget,
    );
    expect(
      find.text('ریتینگ ۸۰ کمتر از حداقل ۹۰ این SBC است.'),
      findsOneWidget,
    );
  });

  testWidgets('renders loading and empty states truthfully', (tester) async {
    await tester.pumpWidget(
      host(
        PlayerUsagePanel(
          player: player,
          loading: true,
          evolutions: const [],
          sbcChallenges: const [],
          evolutionsError: null,
          sbcError: null,
          onRetry: () {},
        ),
      ),
    );
    expect(find.text('در حال خواندن از منبع…'), findsNWidgets(2));

    await tester.pumpWidget(
      host(
        PlayerUsagePanel(
          player: player,
          loading: false,
          evolutions: const [],
          sbcChallenges: const [],
          evolutionsError: null,
          sbcError: null,
          onRetry: () {},
        ),
      ),
    );
    expect(
      find.text('۰ قابل استفاده • ۰ نیازمند بررسی • ۰ نامناسب'),
      findsOneWidget,
    );

    await tester.tap(find.text('SBCهای فعال'));
    await tester.pumpAndSettle();
    expect(find.text('SBC فعالی از منبع دریافت نشد.'), findsOneWidget);
  });

  testWidgets('surfaces source errors and retries on demand', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      host(
        PlayerUsagePanel(
          player: player,
          loading: false,
          evolutions: const [],
          sbcChallenges: const [],
          evolutionsError: 'خطای منبع',
          sbcError: null,
          onRetry: () => retries++,
        ),
      ),
    );

    expect(find.text('دریافت فهرست Evolution ممکن نشد'), findsOneWidget);

    await tester.tap(find.text('Evolutionها'));
    await tester.pumpAndSettle();
    expect(find.text('خطای منبع'), findsOneWidget);

    await tester.tap(find.text('تلاش دوباره'));
    await tester.pump();
    expect(retries, 1);
  });
}
