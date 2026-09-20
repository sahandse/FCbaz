import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/network/fcbaz_api.dart';
import '../navigation/app_navigation_repository.dart';
import '../settings/auth_repository.dart';
import 'notification_repository.dart';

const _firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
const _firebaseMessagingSenderId =
    String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const _firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

FirebaseOptions? _firebaseOptions() {
  if (_firebaseApiKey.isEmpty ||
      _firebaseAppId.isEmpty ||
      _firebaseMessagingSenderId.isEmpty ||
      _firebaseProjectId.isEmpty) {
    return null;
  }

  return const FirebaseOptions(
    apiKey: _firebaseApiKey,
    appId: _firebaseAppId,
    messagingSenderId: _firebaseMessagingSenderId,
    projectId: _firebaseProjectId,
  );
}

@pragma('vm:entry-point')
Future<void> fcbazFirebaseBackgroundHandler(RemoteMessage message) async {
  final options = _firebaseOptions();
  if (options == null) return;

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: options);
  }

  final notification = message.notification;
  final now = DateTime.now();

  await NotificationRepository().add(
    FCBazNotification(
      id: message.messageId ??
          'push-' + now.microsecondsSinceEpoch.toString(),
      type: (message.data['type'] ?? 'push').toString(),
      title: notification?.title ?? 'FCBaz',
      body: notification?.body ?? '',
      createdAt: now,
      playerId: message.data['player_id']?.toString(),
      price: int.tryParse((message.data['price'] ?? '').toString()),
      targetPrice:
          int.tryParse((message.data['target_price'] ?? '').toString()),
    ),
  );
}

class FcmPushStatus {
  const FcmPushStatus({
    required this.configured,
    required this.permissionGranted,
    required this.tokenRegistered,
  });

  final bool configured;
  final bool permissionGranted;
  final bool tokenRegistered;
}

class FcmPushService {
  FcmPushService({
    FCBazApi? api,
    AuthRepository? authRepository,
    NotificationRepository? notificationRepository,
  })  : api = api ?? FCBazApi(),
        authRepository = authRepository ?? AuthRepository(),
        notificationRepository =
            notificationRepository ?? NotificationRepository();

  final FCBazApi api;
  final AuthRepository authRepository;
  final NotificationRepository notificationRepository;
  final navigationRepository = AppNavigationRepository();

  bool _initialized = false;

  bool get configured => _firebaseOptions() != null;

  Future<bool> initialize() async {
    if (!configured) return false;

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: _firebaseOptions()!);
    }

    FirebaseMessaging.onBackgroundMessage(
      fcbazFirebaseBackgroundHandler,
    );

    if (!_initialized) {
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        final playerId = message.data['player_id']?.toString() ?? '';
        if (playerId.isNotEmpty) {
          await navigationRepository.setPendingPlayer(playerId);
        }
      });
      FirebaseMessaging.instance.onTokenRefresh.listen((_) {
        registerCurrentDevice();
      });
      _initialized = true;
    }

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    final initialPlayerId = initial?.data['player_id']?.toString() ?? '';
    if (initialPlayerId.isNotEmpty) {
      await navigationRepository.setPendingPlayer(initialPlayerId);
    }

    return true;
  }

  Future<FcmPushStatus> registerCurrentDevice() async {
    final ready = await initialize();
    if (!ready) {
      return const FcmPushStatus(
        configured: false,
        permissionGranted: false,
        tokenRegistered: false,
      );
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!granted) {
      return const FcmPushStatus(
        configured: true,
        permissionGranted: false,
        tokenRegistered: false,
      );
    }

    final existing = await authRepository.currentSession();
    final session = existing != null && existing.refreshToken.isNotEmpty
        ? await authRepository.refreshSession()
        : existing;
    final token = await FirebaseMessaging.instance.getToken();

    if (session == null || token == null || token.isEmpty) {
      return FcmPushStatus(
        configured: true,
        permissionGranted: true,
        tokenRegistered: false,
      );
    }

    await api.postJson(
      '/api/v1/push/register-device',
      bearerToken: session.accessToken,
      body: {
        'token': token,
        'platform': 'android',
      },
    );

    return const FcmPushStatus(
      configured: true,
      permissionGranted: true,
      tokenRegistered: true,
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final now = DateTime.now();

    await notificationRepository.add(
      FCBazNotification(
        id: message.messageId ??
            'push-' + now.microsecondsSinceEpoch.toString(),
        type: (message.data['type'] ?? 'push').toString(),
        title: notification?.title ?? 'FCBaz',
        body: notification?.body ?? '',
        createdAt: now,
        playerId: message.data['player_id']?.toString(),
        price: int.tryParse((message.data['price'] ?? '').toString()),
        targetPrice:
            int.tryParse((message.data['target_price'] ?? '').toString()),
      ),
    );
  }
}
