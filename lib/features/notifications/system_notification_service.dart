import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class SystemNotificationService {
  SystemNotificationService._();

  static final SystemNotificationService instance = SystemNotificationService._();

  static const _pendingPayloadKey = 'fcbaz_pending_system_notification_payload';
  static const _priceChannelId = 'fcbaz_price_alerts';
  static const _deadlineChannelId = 'fcbaz_deadlines';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || !Platform.isAndroid) return;

    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // timezone defaults to UTC if the device identifier cannot be resolved.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_fcbaz'),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _priceChannelId,
        'هشدار قیمت',
        description: 'هشدار رسیدن قیمت واقعی کارت‌های فهرست پیگیری به قیمت هدف',
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _deadlineChannelId,
        'مهلت‌ها',
        description: 'یادآوری پایان Objective و Evolutionهای واقعی FC27',
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    unawaited(_savePendingPayload(payload));
  }

  Future<void> _savePendingPayload(String payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingPayloadKey, payload);
  }

  Future<String?> consumePendingPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(_pendingPayloadKey);
    if (payload != null) await prefs.remove(_pendingPayloadKey);
    return payload;
  }

  Future<bool> notificationsEnabled() async {
    if (!Platform.isAndroid) return false;
    await initialize();
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;
  }

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    await initialize();
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
  }

  Future<void> showPriceAlert({
    required String playerId,
    required String playerName,
    required int currentPrice,
    required int targetPrice,
  }) async {
    if (!Platform.isAndroid || !await notificationsEnabled()) return;

    await _plugin.show(
      id: _stableId('price:$playerId:$targetPrice'),
      title: 'قیمت هدف رسید',
      body: '$playerName به $currentPrice سکه رسیده است.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _priceChannelId,
          'هشدار قیمت',
          channelDescription: 'هشدار قیمت واقعی کارت‌های فهرست پیگیری',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_fcbaz',
        ),
      ),
      payload: 'player:$playerId',
    );
  }

  Future<void> scheduleDeadline({
    required String type,
    required String sourceId,
    required String title,
    required DateTime expiresAt,
    required Duration before,
  }) async {
    if (!Platform.isAndroid || !await notificationsEnabled()) return;

    final scheduled = expiresAt.toLocal().subtract(before);
    if (!scheduled.isAfter(DateTime.now())) return;

    final when = tz.TZDateTime.from(scheduled, tz.local);
    final label = type == 'objective' ? 'Objective' : 'Evolution';

    await _plugin.zonedSchedule(
      id: _stableId('$type:$sourceId:${expiresAt.toIso8601String()}'),
      title: 'مهلت $label نزدیک است',
      body: '$title تا ${_relativeHours(before)} دیگر به پایان می‌رسد.',
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _deadlineChannelId,
          'مهلت‌ها',
          channelDescription: 'یادآوری پایان Objective و Evolutionهای واقعی',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_fcbaz',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '$type:$sourceId',
    );
  }

  Future<void> cancelDeadline({
    required String type,
    required String sourceId,
    required DateTime expiresAt,
  }) async {
    if (!Platform.isAndroid) return;
    await initialize();
    await _plugin.cancel(
      id: _stableId('$type:$sourceId:${expiresAt.toIso8601String()}'),
    );
  }

  Future<int> pendingCount() async {
    if (!Platform.isAndroid) return 0;
    await initialize();
    return (await _plugin.pendingNotificationRequests()).length;
  }

  int _stableId(String input) {
    var hash = 0x811c9dc5;
    for (final code in input.codeUnits) {
      hash ^= code;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  String _relativeHours(Duration value) {
    final hours = value.inHours;
    if (hours >= 24 && hours % 24 == 0) {
      return '${hours ~/ 24} روز';
    }
    return '$hours ساعت';
  }
}
