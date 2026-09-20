import 'dart:convert';

import '../../core/network/fcbaz_api.dart';
import '../settings/auth_repository.dart';
import '../settings/backup_repository.dart';

class CloudSyncResult {
  const CloudSyncResult({
    required this.updatedAt,
    required this.itemCount,
  });

  final DateTime? updatedAt;
  final int itemCount;
}

class CloudSyncRepository {
  CloudSyncRepository({
    FCBazApi? api,
    AuthRepository? authRepository,
    BackupRepository? backupRepository,
  })  : api = api ?? FCBazApi(),
        authRepository = authRepository ?? AuthRepository(),
        backupRepository = backupRepository ?? BackupRepository();

  final FCBazApi api;
  final AuthRepository authRepository;
  final BackupRepository backupRepository;

  Future<CloudSyncResult> upload() async {
    final session = await authRepository.currentSession();
    if (session == null) {
      throw const FCBazApiException('برای Cloud Sync ابتدا وارد حساب شو.');
    }

    final snapshot = await backupRepository.exportData();
    final json = await api.postJson(
      '/api/v1/account/sync',
      bearerToken: session.accessToken,
      body: {'snapshot': snapshot},
    );

    return _result(json);
  }

  Future<CloudSyncResult> download({
    bool replaceExisting = true,
  }) async {
    final session = await authRepository.currentSession();
    if (session == null) {
      throw const FCBazApiException('برای Cloud Sync ابتدا وارد حساب شو.');
    }

    final json = await api.getJson(
      '/api/v1/account/sync',
      bearerToken: session.accessToken,
    );

    final raw = json is Map ? (json['data'] ?? json) : null;
    if (raw is! Map || raw['snapshot'] is! Map) {
      throw const FCBazApiException('بکاپ Cloud هنوز وجود ندارد.');
    }

    final snapshot = Map<String, dynamic>.from(raw['snapshot'] as Map);
    final restored = await backupRepository.restoreJson(
      snapshotToJson(snapshot),
      replaceExisting: replaceExisting,
    );

    return CloudSyncResult(
      updatedAt: DateTime.tryParse((raw['updated_at'] ?? '').toString()),
      itemCount: restored,
    );
  }

  String snapshotToJson(Map<String, dynamic> snapshot) =>
      _encode(snapshot);

  String _encode(Map<String, dynamic> value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  CloudSyncResult _result(dynamic json) {
    final raw = json is Map ? (json['data'] ?? json) : null;
    if (raw is! Map) {
      throw const FCBazApiException('پاسخ Cloud Sync معتبر نیست.');
    }

    return CloudSyncResult(
      updatedAt: DateTime.tryParse((raw['updated_at'] ?? '').toString()),
      itemCount: int.tryParse((raw['item_count'] ?? '0').toString()) ?? 0,
    );
  }
}
