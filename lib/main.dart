import 'dart:async';

import 'package:flutter/material.dart';

import 'features/notifications/background_price_worker.dart';
import 'features/notifications/system_notification_service.dart';
import 'src/fcbaz_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Always render the app first. Optional platform services must never block
  // startup or leave users on a black splash screen if a plugin/device setup
  // fails at runtime.
  runApp(const FCBazApp());

  unawaited(_initializeOptionalPlatformServices());
}

Future<void> _initializeOptionalPlatformServices() async {
  try {
    await SystemNotificationService.instance.initialize();
  } catch (_) {
    // Notifications are optional; the app must remain usable without them.
  }

  try {
    await BackgroundPriceWorker.initialize();
    await BackgroundPriceWorker.ensureScheduled();
  } catch (_) {
    // Background checks are optional; foreground functionality stays active.
  }
}
