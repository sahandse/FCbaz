import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local profile stays Persian and no-auth', () {
    final source = File(
      'lib/features/settings/profile_screen.dart',
    ).readAsStringSync();

    expect(source, contains('بدون ثبت‌نام و ورود'));
    expect(source, contains('علاقه‌مندی‌ها'));
    expect(source, contains('باشگاه من'));
    expect(source, contains('ترکیب‌ها'));
    expect(source, contains('واچ‌لیست'));

    expect(source, isNot(contains("label: 'Favorites'")));
    expect(source, isNot(contains("label: 'My Club'")));
    expect(source, isNot(contains("label: 'Squads'")));
    expect(source, isNot(contains("label: 'Watchlist'")));
    expect(source, isNot(contains('اکانت آنلاین هنوز فعال نیست')));
    expect(source, isNot(contains('اضافه‌شدن Login')));
  });

  test('player details keeps Persian UX around FC-style modules', () {
    final source = File(
      'lib/features/players/presentation/player_details_screen.dart',
    ).readAsStringSync();

    expect(source, contains('PlayerItemVisual'));
    expect(source, contains("const _SectionLabel('FACE STATS')"));
    expect(source, contains("const _SectionLabel('CHEMISTRY STYLE')"));
    expect(source, contains("'مقایسه'"));
    expect(source, contains("'یادداشت شخصی'"));
    expect(source, contains("'هنوز نظری ثبت نشده'"));
    expect(source, contains("('SKILLS'"));
    expect(source, contains("('WEAK FOOT'"));
  });

  test('search discovery and price labels stay Persian', () {
    final source = File(
      'lib/features/search/search_screen.dart',
    ).readAsStringSync();

    expect(source, contains('بازیکنان ترند'));
    expect(source, contains('جستجوهای محبوب'));
    expect(source, contains('قیمت رایانه'));
    expect(source, contains('قیمت کنسول'));

    expect(source, isNot(contains('Trending Players')));
    expect(source, isNot(contains('Popular Searches')));
    expect(source, isNot(contains('PC Price')));
    expect(source, isNot(contains('Console Price')));
  });
}
