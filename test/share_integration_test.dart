import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/source_bundle.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('squad and draft screens offer a rendered image share action', () {
    final squad = readSourceBundle('lib/features/squad/squad_screen_pro.dart');
    expect(
      squad,
      contains("import 'package:fcbaz/src/share/share_card.dart';"),
    );
    expect(squad, contains('ShareCardRenderer().renderPng'));
    expect(squad, contains('shareService.shareImage'));
    expect(squad, contains('Icons.ios_share_rounded'));
    expect(squad, contains('shareOutcomeMessage'));

    final draft = readSourceBundle(
      'lib/features/draft/presentation/draft_screen.dart',
    );
    expect(draft, contains('ShareCardRenderer().renderPng'));
    expect(draft, contains('_shareService.shareImage'));
    expect(draft, contains('اشتراک‌گذاری کارت درافت'));
    expect(draft, contains('shareOutcomeMessage'));
  });

  test('android app registers the share channel and FileProvider', () {
    final activity = _read(
      'android/app/src/main/kotlin/ir/fcbaz/app/MainActivity.kt',
    );
    expect(activity, contains('"ir.fcbaz.app/share"'));
    expect(activity, contains('"shareImage"'));
    expect(activity, contains('FileProvider.getUriForFile'));
    expect(activity, contains('Intent.ACTION_SEND'));
    expect(activity, contains('Intent.EXTRA_STREAM'));
    expect(activity, contains('FLAG_GRANT_READ_URI_PERMISSION'));
    expect(activity, contains('cacheDir, "shares"'));

    final manifest = _read('android/app/src/main/AndroidManifest.xml');
    expect(manifest, contains('androidx.core.content.FileProvider'));
    expect(manifest, contains(r'${applicationId}.fileprovider'));
    expect(manifest, contains('android.support.FILE_PROVIDER_PATHS'));
    expect(manifest, contains('@xml/file_paths'));

    final paths = _read('android/app/src/main/res/xml/file_paths.xml');
    expect(paths, contains('<cache-path'));
    expect(paths, contains('path="shares/"'));
  });

  test('share implementation adds no new Flutter package dependency', () {
    final pubspec = _read('pubspec.yaml');
    expect(pubspec, isNot(contains('share_plus')));
    expect(pubspec, isNot(contains('path_provider:')));
  });
}
