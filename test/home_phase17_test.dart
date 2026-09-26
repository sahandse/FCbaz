import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home dashboard is local-first and no-auth', () {
    final screen = File(
      'lib/features/home/home_dashboard_screen.dart',
    ).readAsStringSync();
    final service = File(
      'lib/features/home/home_local_dashboard_service.dart',
    ).readAsStringSync();
    final shell = File(
      'lib/features/navigation/main_shell.dart',
    ).readAsStringSync();

    expect(screen, contains('داشبورد من'));
    expect(screen, contains('باشگاه من'));
    expect(screen, contains('فهرست پیگیری'));
    expect(screen, contains('پیشرفت هدف‌ها'));
    expect(screen, contains('بدون ثبت‌نام'));
    expect(service, contains('WatchlistRepository'));
    expect(service, contains('ObjectiveProgressRepository'));
    expect(service, contains('MyClubRepository'));
    expect(shell, contains('HomeDashboardScreen'));
    expect(shell, isNot(contains('HomeScreen(')));
  });
}
