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

    expect(screen, contains('StadiumHero'));
    expect(screen, contains('DeadlineChip'));
    expect(screen, contains('PriceDelta'));
    expect(screen, contains('SourceBadge'));
    expect(screen, contains("title: 'امروز'"));
    expect(screen, contains("title: 'کارت‌های داغ'"));
    expect(screen, contains('onOpenClub'));
    expect(screen, contains('جایگزین جعلی'));
    expect(screen, contains("source: 'FC27 Hub'"));
    expect(service, contains('WatchlistRepository'));
    expect(service, contains('ObjectiveProgressRepository'));
    expect(service, contains('MyClubRepository'));
    expect(shell, contains('HomeDashboardScreen'));
    expect(shell, isNot(contains('HomeScreen(')));
  });
}
