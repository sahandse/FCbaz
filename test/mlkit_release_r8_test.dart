import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release R8 keeps ML Kit component registrars constructible', () {
    final rules = File('android/app/proguard-rules.pro').readAsStringSync();
    final keepRegistrar = RegExp(
      r'-keep class \* implements com\.google\.firebase\.components\.ComponentRegistrar\s*\{\s*\*;\s*\}',
    );

    expect(keepRegistrar.hasMatch(rules), isTrue);
  });

  test('release build applies the app ProGuard rules', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('"proguard-android-optimize.txt"'));
    expect(gradle, contains('"proguard-rules.pro"'));
  });
}
