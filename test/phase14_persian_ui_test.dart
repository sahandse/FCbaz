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

  test('player details uses Persian presentation labels', () {
    final source = File(
      'lib/features/players/presentation/player_details_screen.dart',
    ).readAsStringSync();

    expect(source, contains("title: 'آمار اصلی'"));
    expect(source, contains("title: 'آمار درون بازی'"));
    expect(source, contains("title: 'پیشنهاد سبک شیمی'"));
    expect(source, contains("'حرکات مهارتی'"));
    expect(source, contains("'پای ضعیف'"));
    expect(source, contains("'نرخ فعالیت'"));

    expect(source, isNot(contains("title: 'Face Stats'")));
    expect(source, isNot(contains("title: 'In‑Game Stats'")));
    expect(source, isNot(contains("title: 'Chemistry Style Advisor'")));
    expect(source, isNot(contains("('Skill Moves'")));
    expect(source, isNot(contains("('Weak Foot'")));
    expect(source, isNot(contains("('Work Rates'")));
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
