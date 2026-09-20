import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fcbaz/features/settings/backup_repository.dart';

void main() {
  test('backup exports and restores only FCBaz preferences', () async {
    SharedPreferences.setMockInitialValues({
      'fcbaz_theme_mode': 'dark',
      'fcbaz_default_platform': 'pc',
      'foreign_key': 'must_not_be_exported',
    });

    final repository = BackupRepository();
    final raw = await repository.exportJson();

    expect(raw, contains('fcbaz_theme_mode'));
    expect(raw, contains('fcbaz_default_platform'));
    expect(raw, isNot(contains('foreign_key')));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcbaz_theme_mode', 'light');

    final restored = await repository.restoreJson(raw);

    expect(restored, 2);
    expect(prefs.getString('fcbaz_theme_mode'), 'dark');
    expect(prefs.getString('fcbaz_default_platform'), 'pc');
  });
}
