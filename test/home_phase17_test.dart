import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home dashboard is local-first and live-data aware', () {
    final screen = File(
      'lib/features/home/home_dashboard_screen.dart',
    ).readAsStringSync();
    final service = File(
      'lib/features/home/home_local_dashboard_service.dart',
    ).readAsStringSync();
    final shell = File(
      'lib/features/navigation/main_shell.dart',
    ).readAsStringSync();

    expect(screen, contains('YOUR CLUB.'));
    expect(screen, contains('HOT ITEMS'));
    expect(screen, contains('LIVE HUB'));
    expect(screen, contains("label: 'SBC'"));
    expect(screen, contains("label: 'EVOLUTIONS'"));
    expect(screen, contains("label: 'OBJECTIVES'"));
    expect(screen, contains('فقط داده معتبر'));
    expect(service, contains('WatchlistRepository'));
    expect(service, contains('ObjectiveProgressRepository'));
    expect(service, contains('MyClubRepository'));
    expect(shell, contains('HomeDashboardScreen'));
    expect(shell, isNot(contains('HomeScreen(')));
  });
}
