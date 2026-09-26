import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/notifications/background_sync_status_repository.dart';

void main() {
  group('Phase 21 production hardening', () {
    test('background sync status keeps real execution counters', () {
      final at = DateTime.parse('2026-09-26T10:00:00Z');
      final status = BackgroundSyncStatus.fromJson({
        'last_run_at': at.toIso8601String(),
        'last_success_at': at.toIso8601String(),
        'last_checked': 4,
        'last_triggered': 1,
      });

      expect(status.lastRunAt, at);
      expect(status.lastSuccessAt, at);
      expect(status.lastChecked, 4);
      expect(status.lastTriggered, 1);
      expect(status.lastError, isNull);
    });

    test('production release never generates a new signing key', () {
      final workflow = File('.github/workflows/flutter-android.yml').readAsStringSync();
      expect(workflow.contains('keytool -genkeypair'), isFalse);
      expect(workflow, contains('FCBAZ_KEYSTORE_BASE64'));
      expect(workflow, contains('FCBAZ_STORE_PASSWORD'));
      expect(workflow, contains('FCBAZ_KEY_PASSWORD'));
      expect(workflow, contains('FCBAZ_KEY_ALIAS'));
      expect(workflow, contains('Production API URL must use HTTPS'));
    });
  });
}
