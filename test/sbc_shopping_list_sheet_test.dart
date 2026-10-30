import 'package:fcbaz/features/sbc/domain/sbc_rating_tools.dart';
import 'package:fcbaz/features/sbc/domain/sbc_shopping_list.dart';
import 'package:fcbaz/features/sbc/presentation/sbc_shopping_list_sheet.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _combination = SbcRatingCombination(
  counts: {84: 5, 83: 6},
  squadRating: 84,
);

Map<int, SbcShoppingCandidate> _candidates({bool include83 = true}) {
  return {
    84: const SbcShoppingCandidate(
      playerId: 'p84',
      playerName: 'Player 84',
      price: 12000,
    ),
    if (include83)
      83: const SbcShoppingCandidate(
        playerId: 'p83',
        playerName: 'Player 83',
        price: 10000,
      ),
  };
}

SbcShoppingList _list({
  int? budget,
  Map<int, int> owned = const {},
  bool include83 = true,
}) {
  return SbcShoppingList.build(
    targetRating: 84,
    combination: _combination,
    candidates: _candidates(include83: include83),
    ownedCountByRating: owned,
    budget: budget,
  );
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: FCBazTheme.dark(),
    home: Scaffold(
      body: Directionality(textDirection: TextDirection.rtl, child: child),
    ),
  );
}

void main() {
  testWidgets('shows priced rows, remaining budget and the tax note', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SbcShoppingListSheet(
          list: _list(budget: 50000, owned: const {84: 5, 83: 2}),
          title: 'لیست خرید ترکیب ۱',
        ),
      ),
    );

    expect(find.text('لیست خرید ترکیب ۱'), findsOneWidget);
    expect(find.text('۴ کارت'), findsOneWidget);
    expect(find.text('۴۰,۰۰۰ سکه'), findsWidgets);
    expect(find.text('باقی ۱۰,۰۰۰'), findsOneWidget);
    expect(find.textContaining('مالیات ۵٪'), findsOneWidget);
    expect(find.text('کپی متن'), findsOneWidget);
    expect(find.text('اشتراک تصویر'), findsOneWidget);
  });

  testWidgets('refuses a budget verdict while a rating has no real price', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SbcShoppingListSheet(
          list: _list(budget: 50000, owned: const {84: 5}, include83: false),
        ),
      ),
    );

    expect(find.text('جمع شناخته‌شده'), findsOneWidget);
    expect(find.text('نامشخص'), findsOneWidget);
    expect(
      find.textContaining('قیمت واقعی برای این ریتینگ در دسترس نیست'),
      findsOneWidget,
    );
    expect(find.textContaining('مالیات ۵٪'), findsOneWidget);
  });

  testWidgets('shows the honest empty state when the club covers it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(SbcShoppingListSheet(list: _list(owned: const {84: 5, 83: 6}))),
    );

    expect(find.textContaining('خرید لازم نیست'), findsOneWidget);
    expect(find.text('بدون سقف'), findsOneWidget);
    expect(find.text('۰ کارت'), findsOneWidget);
  });
}
