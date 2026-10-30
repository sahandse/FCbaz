import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fcbaz/features/notifications/notification_repository.dart';
import 'package:fcbaz/features/notifications/price_alert_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'foreground evaluation stores one real alert and never duplicates it',
    () async {
      final notifications = NotificationRepository();
      final service = PriceAlertService(notificationRepository: notifications);

      final first = await service.evaluateObservedPrice(
        playerId: 'p1',
        playerName: 'Player One',
        currentPrice: 90000,
        targetPrice: 95000,
      );
      expect(first, isTrue);

      final stored = await notifications.getAll();
      expect(stored.length, 1);
      expect(stored.single.type, 'price_alert');
      expect(stored.single.price, 90000);
      expect(stored.single.targetPrice, 95000);
      expect(stored.single.body, contains('۹۰۰۰۰'));

      final second = await service.evaluateObservedPrice(
        playerId: 'p1',
        playerName: 'Player One',
        currentPrice: 89000,
        targetPrice: 95000,
      );
      expect(second, isFalse);
      expect((await notifications.getAll()).length, 1);
    },
  );

  test('a price above the target creates no alert', () async {
    final notifications = NotificationRepository();
    final service = PriceAlertService(notificationRepository: notifications);

    final hit = await service.evaluateObservedPrice(
      playerId: 'p1',
      playerName: 'Player One',
      currentPrice: 100000,
      targetPrice: 95000,
    );

    expect(hit, isFalse);
    expect(await notifications.getAll(), isEmpty);
  });

  test('zero prices or missing targets are ignored', () async {
    final notifications = NotificationRepository();
    final service = PriceAlertService(notificationRepository: notifications);

    expect(
      await service.evaluateObservedPrice(
        playerId: 'p1',
        playerName: 'Player One',
        currentPrice: 0,
        targetPrice: 95000,
      ),
      isFalse,
    );
    expect(
      await service.evaluateObservedPrice(
        playerId: 'p1',
        playerName: 'Player One',
        currentPrice: 90000,
        targetPrice: null,
      ),
      isFalse,
    );
    expect(await notifications.getAll(), isEmpty);
  });

  test('disabled alerts stay disabled in the foreground', () async {
    SharedPreferences.setMockInitialValues({
      'fcbaz_price_alerts_enabled': false,
    });
    final notifications = NotificationRepository();
    final service = PriceAlertService(notificationRepository: notifications);

    final hit = await service.evaluateObservedPrice(
      playerId: 'p1',
      playerName: 'Player One',
      currentPrice: 90000,
      targetPrice: 95000,
    );

    expect(hit, isFalse);
    expect(await notifications.getAll(), isEmpty);
  });
}
