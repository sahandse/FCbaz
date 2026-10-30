import '../market/data/market_repository.dart';
import '../market/data/watchlist_repository.dart';
import '../settings/app_settings_repository.dart';
import 'notification_repository.dart';
import 'system_notification_service.dart';
import '../../src/utils/persian_formatters.dart';

class PriceAlertCheckResult {
  const PriceAlertCheckResult({required this.checked, required this.triggered});

  final int checked;
  final int triggered;
}

class PriceAlertService {
  PriceAlertService({
    MarketRepository? marketRepository,
    WatchlistRepository? watchlistRepository,
    NotificationRepository? notificationRepository,
    AppSettingsRepository? settingsRepository,
  }) : marketRepository = marketRepository ?? MarketRepository(),
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

    for (final item in items) {
      try {
        final price = await marketRepository.getPlayerPrice(
          item.playerId,
          platform: settings.defaultPlatform,
        );

        checked++;
        await watchlistRepository.recordPrice(
          item.playerId,
          price: price.current,
          platform: settings.defaultPlatform,
          checkedAt: price.updatedAt ?? DateTime.now(),
        );

        final hit = await _evaluate(
          playerId: item.playerId,
          playerName: item.playerName,
          currentPrice: price.current,
          targetPrice: item.targetPrice,
        );
        if (hit) triggered++;
      } catch (_) {
        // A failed market request must never create a fake alert or snapshot.
      }
    }

    return PriceAlertCheckResult(checked: checked, triggered: triggered);
  }

  /// Evaluates a real price that a screen already fetched. The market screen
  /// calls this so a watched card that is already at its target alerts during
  /// the same visit instead of waiting for the background worker.
  Future<bool> evaluateObservedPrice({
    required String playerId,
    required String playerName,
    required int currentPrice,
    required int? targetPrice,
  }) async {
    final settings = await settingsRepository.load();
    if (!settings.priceAlertsEnabled) return false;
    return _evaluate(
      playerId: playerId,
      playerName: playerName,
      currentPrice: currentPrice,
      targetPrice: targetPrice,
    );
  }

  /// Returns true only when this observation crossed the target and a real
  /// notification was stored. A price of zero never produces an alert.
  Future<bool> _evaluate({
    required String playerId,
    required String playerName,
    required int currentPrice,
    required int? targetPrice,
  }) async {
    if (currentPrice <= 0 || targetPrice == null || targetPrice <= 0) {
      return false;
    }

    final reached = currentPrice <= targetPrice;
    final stateKey = '$playerId:$targetPrice';
    final states = await notificationRepository.alertStates();
    final previous = states[stateKey] ?? 'above';

    if (reached && previous != 'reached') {
      final now = DateTime.now();
      await notificationRepository.add(
        FCBazNotification(
          id: 'price-$playerId-$targetPrice-${now.millisecondsSinceEpoch}',
          type: 'price_alert',
          title: 'قیمت هدف رسید',
          body:
              '$playerName به ${faDigits(currentPrice)} سکه رسیده است '
              '(هدف: ${faDigits(targetPrice)}).',
          createdAt: now,
          playerId: playerId,
          price: currentPrice,
          targetPrice: targetPrice,
        ),
      );

      try {
        await SystemNotificationService.instance.showPriceAlert(
          playerId: playerId,
          playerName: playerName,
          currentPrice: currentPrice,
          targetPrice: targetPrice,
        );
      } catch (_) {
        // The in-app notification is already stored; a system banner failure
        // must not block the alert state or create duplicates.
      }
    }

    await notificationRepository.setAlertState(
      stateKey,
      reached ? 'reached' : 'above',
    );
    return reached && previous != 'reached';
  }
}
