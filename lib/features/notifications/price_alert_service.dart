import '../market/data/market_repository.dart';
import '../market/data/watchlist_repository.dart';
import '../settings/app_settings_repository.dart';
import 'notification_repository.dart';

class PriceAlertCheckResult {
  const PriceAlertCheckResult({
    required this.checked,
    required this.triggered,
  });

  final int checked;
  final int triggered;
}

class PriceAlertService {
  PriceAlertService({
    MarketRepository? marketRepository,
    WatchlistRepository? watchlistRepository,
    NotificationRepository? notificationRepository,
    AppSettingsRepository? settingsRepository,
  })  : marketRepository = marketRepository ?? MarketRepository(),
        watchlistRepository = watchlistRepository ?? WatchlistRepository(),
        notificationRepository =
            notificationRepository ?? NotificationRepository(),
        settingsRepository = settingsRepository ?? AppSettingsRepository();

  final MarketRepository marketRepository;
  final WatchlistRepository watchlistRepository;
  final NotificationRepository notificationRepository;
  final AppSettingsRepository settingsRepository;

  Future<PriceAlertCheckResult> checkNow() async {
    final settings = await settingsRepository.load();
    if (!settings.priceAlertsEnabled) {
      return const PriceAlertCheckResult(checked: 0, triggered: 0);
    }

    final items = (await watchlistRepository.getAll())
        .where((e) => e.targetPrice != null && e.targetPrice! > 0)
        .toList();

    var checked = 0;
    var triggered = 0;
    final states = await notificationRepository.alertStates();

    for (final item in items) {
      try {
        final price = await marketRepository.getPlayerPrice(
          item.playerId,
          platform: settings.defaultPlatform,
        );

        checked++;
        final target = item.targetPrice!;
        final reached = price.current > 0 && price.current <= target;
        final stateKey = item.playerId + ':' + target.toString();
        final previous = states[stateKey] ?? 'above';

        if (reached && previous != 'reached') {
          final now = DateTime.now();
          await notificationRepository.add(
            FCBazNotification(
              id: 'price-' +
                  item.playerId +
                  '-' +
                  target.toString() +
                  '-' +
                  now.millisecondsSinceEpoch.toString(),
              type: 'price_alert',
              title: 'قیمت هدف رسید',
              body: item.playerName +
                  ' به ' +
                  price.current.toString() +
                  ' Coins رسیده است.',
              createdAt: now,
              playerId: item.playerId,
              price: price.current,
              targetPrice: target,
            ),
          );
          triggered++;
        }

        await notificationRepository.setAlertState(
          stateKey,
          reached ? 'reached' : 'above',
        );
      } catch (_) {
        // A failed market request must never create a fake alert.
      }
    }

    return PriceAlertCheckResult(
      checked: checked,
      triggered: triggered,
    );
  }
}
