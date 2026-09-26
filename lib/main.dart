import 'package:flutter/material.dart';

import 'features/notifications/background_price_worker.dart';
import 'features/notifications/system_notification_service.dart';
import 'src/fcbaz_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemNotificationService.instance.initialize();
  await BackgroundPriceWorker.initialize();
  await BackgroundPriceWorker.ensureScheduled();
  runApp(const FCBazApp());
}
