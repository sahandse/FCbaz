import 'package:fcbaz/features/club/data/my_club_repository.dart';
import 'package:fcbaz/features/sbc/presentation/sbc_club_solver_card.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MyClubItem _item({
  required String id,
  required int rating,
  required bool untradeable,
  int acquisitionPrice = 0,
}) {
  return MyClubItem(
    playerId: id,
    playerName: 'Player $id',
    rating: rating,
    position: 'CM',
    positions: const ['CM'],
    clubName: 'Club',
    leagueName: 'League',
    nationName: 'Nation',
    version: 'Gold',
    imageUrl: '',
    pace: 80,
    shooting: 80,
    passing: 80,
    dribbling: 80,
    defending: 80,
    physical: 80,
    skillMoves: 4,
    weakFoot: 4,
    acquisitionPrice: acquisitionPrice,
    untradeable: untradeable,
  );
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: FCBazTheme.dark(),
    home: Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('club solver card shows the untradeable-first squad', (
    tester,
  ) async {
    final items = [
      for (var i = 0; i < 11; i++)
        _item(id: 'u$i', rating: 84, untradeable: true),
      _item(id: 't0', rating: 90, untradeable: false, acquisitionPrice: 5000),
    ];

    await tester.pumpWidget(
      _app(SbcClubSolverCard(items: items, targetRating: 84)),
    );

    expect(find.text('ساخت از کلوب من'), findsOneWidget);
    expect(find.text('ریتینگ ۸۴'), findsOneWidget);
    expect(find.text('غیرقابل‌فروش ۱۱'), findsOneWidget);
    expect(find.text('قابل‌فروش ۰'), findsOneWidget);
    expect(find.text('خرید اضافه ۰ سکه'), findsOneWidget);
    expect(find.textContaining('ریتینگ هدف ۸۴'), findsOneWidget);
    expect(find.text('۱۱× ۸۴'), findsOneWidget);
  });

  testWidgets('club solver card lists the picked cards when expanded', (
    tester,
  ) async {
    final items = [
      for (var i = 0; i < 8; i++)
        _item(id: 'u$i', rating: 75, untradeable: true),
      for (var i = 0; i < 3; i++)
        _item(
          id: 't$i',
          rating: 92,
          untradeable: false,
          acquisitionPrice: 5000,
        ),
    ];

    await tester.pumpWidget(
      _app(SbcClubSolverCard(items: items, targetRating: 83)),
    );

    expect(find.text('قابل‌فروش ۳'), findsOneWidget);
    expect(find.textContaining('۱۵,۰۰۰'), findsOneWidget);

    await tester.tap(find.text('کارت‌های انتخابی از کلوب'));
    await tester.pumpAndSettle();

    expect(find.text('Player t0'), findsOneWidget);
    expect(find.text('Player u0'), findsOneWidget);
  });

  testWidgets('club solver card explains an unreachable target honestly', (
    tester,
  ) async {
    final items = [
      for (var i = 0; i < 11; i++)
        _item(id: 'u$i', rating: 70, untradeable: true),
    ];

    await tester.pumpWidget(
      _app(SbcClubSolverCard(items: items, targetRating: 85)),
    );

    expect(find.text('ریتینگ ۷۰'), findsOneWidget);
    expect(find.textContaining('۱۵ امتیاز کمتر از هدف'), findsOneWidget);
    expect(find.textContaining('عدد ساختگی'), findsOneWidget);
  });

  testWidgets('club solver card asks for more cards below eleven', (
    tester,
  ) async {
    final items = [
      for (var i = 0; i < 10; i++)
        _item(id: 'u$i', rating: 84, untradeable: true),
    ];

    await tester.pumpWidget(
      _app(SbcClubSolverCard(items: items, targetRating: 84)),
    );

    expect(find.text('کلوب برای حل SBC کافی نیست'), findsOneWidget);
    expect(find.textContaining('الان ۱۰ کارت ثبت شده'), findsOneWidget);
  });
}
