import 'package:fcbaz/features/evolutions/data/evolution_repository.dart';
import 'package:fcbaz/features/evolutions/domain/evolution.dart';
import 'package:fcbaz/features/home/home_repository.dart';
import 'package:fcbaz/features/notifications/deadline_alert_service.dart';
import 'package:fcbaz/features/notifications/notification_repository.dart';
import 'package:fcbaz/features/sbc/data/sbc_repository.dart';
import 'package:fcbaz/features/sbc/domain/sbc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSbcRepository extends SbcRepository {
  _FakeSbcRepository(this.items);

  final List<SbcChallenge> items;

  @override
  Future<List<SbcChallenge>> getActive({bool forceRefresh = false}) async =>
      items;
}

class _EmptyEvolutionRepository extends EvolutionRepository {
  @override
  Future<List<Evolution>> getActive({bool forceRefresh = false}) async =>
      const [];
}

class _EmptyHomeRepository extends HomeRepository {
  @override
  Future<List<HomeObjective>> getObjectives({
    bool forceRefresh = false,
  }) async => const [];
}

void main() {
  final now = DateTime.now();

  SbcChallenge sbc(String id, String title, Duration remaining) =>
      SbcChallenge.fromJson({
        'id': id,
        'title': title,
        'expires_at': now.add(remaining).toIso8601String(),
      });

  DeadlineAlertService service(List<SbcChallenge> items) =>
      DeadlineAlertService(
        sbcRepository: _FakeSbcRepository(items),
        evolutionRepository: _EmptyEvolutionRepository(),
        homeRepository: _EmptyHomeRepository(),
      );

  test('SBC deadlines inside the threshold create one honest alert', () async {
    SharedPreferences.setMockInitialValues({});
    final notifications = NotificationRepository();
    final alertService = service([
      sbc('sbc-soon', 'SBC Soon', const Duration(hours: 1)),
      sbc('sbc-later', 'SBC Later', const Duration(days: 3)),
    ]);

    final result = await alertService.checkNow();

    expect(result.checkedSbcs, 2);
    expect(result.checkedObjectives, 0);
    expect(result.checkedEvolutions, 0);
    expect(result.triggered, 1);
    expect(result.scheduled, 1);

    final items = await notifications.getAll();
    expect(items, hasLength(1));
    final alert = items.single;
    expect(alert.type, 'sbc_deadline');
    expect(alert.title, 'مهلت SBC رو به پایان است');
    expect(alert.body, contains('SBC Soon'));
    expect(alert.body, contains('دقیقه دیگر فعال است'));
    expect(alert.destinationId, 'sbc-soon');
  });

  test('a repeated check does not duplicate the same SBC alert', () async {
    SharedPreferences.setMockInitialValues({});
    final notifications = NotificationRepository();
    final alertService = service([
      sbc('sbc-soon', 'SBC Soon', const Duration(hours: 1)),
    ]);

    await alertService.checkNow();
    final second = await alertService.checkNow();

    expect(second.triggered, 0);
    expect(await notifications.getAll(), hasLength(1));
  });

  test('disabling SBC deadline alerts skips the SBC source entirely', () async {
    SharedPreferences.setMockInitialValues({
      'fcbaz_notify_sbc_deadline': false,
    });
    final notifications = NotificationRepository();
    final alertService = service([
      sbc('sbc-soon', 'SBC Soon', const Duration(hours: 1)),
    ]);

    final result = await alertService.checkNow();

    expect(result.checkedSbcs, 0);
    expect(result.triggered, 0);
    expect(await notifications.getAll(), isEmpty);
  });

  test('SBCs without a real expiry never create an alert', () async {
    SharedPreferences.setMockInitialValues({});
    final notifications = NotificationRepository();
    final alertService = service([
      SbcChallenge.fromJson({'id': 'sbc-open', 'title': 'SBC Open'}),
    ]);

    final result = await alertService.checkNow();

    expect(result.checkedSbcs, 1);
    expect(result.triggered, 0);
    expect(await notifications.getAll(), isEmpty);
  });
}
