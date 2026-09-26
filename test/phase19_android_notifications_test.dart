import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest keeps notification scheduling permissions and receivers', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    expect(manifest, contains('ScheduledNotificationReceiver'));
    expect(manifest, contains('ScheduledNotificationBootReceiver'));
  });

  test('Android build enables core library desugaring', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('isCoreLibraryDesugaringEnabled = true'));
    expect(gradle, contains('desugar_jdk_libs:2.1.4'));
  });

  test('system notification service uses inexact deadline scheduling', () {
    final source = File(
      'lib/features/notifications/system_notification_service.dart',
    ).readAsStringSync();

    expect(source, contains('AndroidScheduleMode.inexactAllowWhileIdle'));
    expect(source, isNot(contains('requestExactAlarmsPermission')));
    expect(source, contains('requestNotificationsPermission'));
  });
}
