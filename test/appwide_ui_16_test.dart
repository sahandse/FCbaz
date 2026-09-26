import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('1.6 theme styles shared FC27 controls app-wide', () {
    final source = File('lib/src/theme/fcbaz_theme.dart').readAsStringSync();
    for (final token in [
      'segmentedButtonTheme',
      'tabBarTheme',
      'expansionTileTheme',
      'floatingActionButtonTheme',
      'popupMenuTheme',
      'badgeTheme',
      'tooltipTheme',
    ]) {
      expect(source, contains(token));
    }
  });

  test('SBC center uses live FC27 hub language and verified states', () {
    final source = File('lib/features/sbc/presentation/sbc_screen.dart').readAsStringSync();
    expect(source, contains('SBC HUB'));
    expect(source, contains('FC27 • LIVE'));
    expect(source, contains('SQUAD BUILDING'));
    expect(source, contains('REQUIREMENTS'));
    expect(source, contains('بررسی راه‌حل واقعی Backend'));
  });
}
