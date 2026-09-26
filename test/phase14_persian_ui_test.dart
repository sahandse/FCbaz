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
}
