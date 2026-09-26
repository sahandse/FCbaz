import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'price_alert_service.dart';
import 'system_notification_service.dart';

const String backgroundPriceCheckUniqueName = 'fcbaz-background-price-check';
const String backgroundPriceCheckTask = 'fcbaz.price_check';
const Duration backgroundPriceCheckFrequency = Duration(minutes: 30);

@pragma('vm:entry-point')
void fcbazBackgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != backgroundPriceCheckTask) return true;

    WidgetsFlutterBinding.ensureInitialized();

    try {
      await SystemNotificationService.instance.initialize();
      await PriceAlertService().checkNow();
      return true;
    } catch (_) {
      // Returning false lets Android WorkManager retry transient failures
      // with its own backoff policy. No notification is created on failure.
      return false;
    }
  });
}

class BackgroundPriceWorker {
  const BackgroundPriceWorker._();

  static Future<void> initialize() async {
    await Workmanager().initialize(fcbazBackgroundCallbackDispatcher);
  }

  static Future<void> ensureScheduled() async {
    await Workmanager().cancelByUniqueName(backgroundPriceCheckUniqueName);
    await Workmanager().registerPeriodicTask(
      backgroundPriceCheckUniqueName,
      backgroundPriceCheckTask,
      frequency: backgroundPriceCheckFrequency,
      initialDelay: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }

  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(backgroundPriceCheckUniqueName);
  }
}
