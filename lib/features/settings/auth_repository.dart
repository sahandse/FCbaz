import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/fcbaz_api.dart';

class AccountSession {
  const AccountSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;

  factory AccountSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : const <String, dynamic>{};

    return AccountSession(
      accessToken: (json['access_token'] ?? '').toString(),
      refreshToken: (json['refresh_token'] ?? '').toString(),
      userId: (user['id'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
    );
  }
}

class AuthRepository {
  AuthRepository({FCBazApi? api}) : api = api ?? FCBazApi();

  final FCBazApi api;
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessKey = 'fcbaz_auth_access_token';
  static const _refreshKey = 'fcbaz_auth_refresh_token';
  static const _userKey = 'fcbaz_auth_user_id';
  static const _emailKey = 'fcbaz_auth_email';

  Future<AccountSession?> currentSession() async {
    final access = await storage.read(key: _accessKey) ?? '';
    final refresh = await storage.read(key: _refreshKey) ?? '';
    final userId = await storage.read(key: _userKey) ?? '';
    final email = await storage.read(key: _emailKey) ?? '';

    if (access.isEmpty || userId.isEmpty) return null;
    return AccountSession(
      accessToken: access,
      refreshToken: refresh,
      userId: userId,
      email: email,
    );
  }

  Future<AccountSession> signIn({
    required String email,
    required String password,
  }) async {
    final json = await api.postJson(
      '/api/v1/account/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    final raw = json is Map ? (json['data'] ?? json) : null;
    if (raw is! Map) {
      throw const FCBazApiException('پاسخ ورود معتبر نیست.');
    }

    final session = AccountSession.fromJson(
      Map<String, dynamic>.from(raw),
    );

    if (session.accessToken.isEmpty || session.userId.isEmpty) {
      throw const FCBazApiException('ورود تکمیل نشد.');
    }

    await _save(session);
    return session;
  }

  Future<AccountSession> signUp({
    required String email,
    required String password,
  }) async {
    final json = await api.postJson(
      '/api/v1/account/register',
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    final raw = json is Map ? (json['data'] ?? json) : null;
    if (raw is! Map) {
      throw const FCBazApiException('پاسخ ثبت‌نام معتبر نیست.');
    }

    final session = AccountSession.fromJson(
      Map<String, dynamic>.from(raw),
    );

    if (session.accessToken.isNotEmpty && session.userId.isNotEmpty) {
      await _save(session);
    }

    return session;
  }

  Future<void> signOut() async {
    await Future.wait([
      storage.delete(key: _accessKey),
      storage.delete(key: _refreshKey),
      storage.delete(key: _userKey),
      storage.delete(key: _emailKey),
    ]);
  }

  Future<void> _save(AccountSession session) async {
    await Future.wait([
      storage.write(key: _accessKey, value: session.accessToken),
      storage.write(key: _refreshKey, value: session.refreshToken),
      storage.write(key: _userKey, value: session.userId),
      storage.write(key: _emailKey, value: session.email),
    ]);
  }
}
