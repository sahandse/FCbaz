import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backend has no account or authentication stack', () {
    final backend = File('backend/server.mjs').readAsStringSync().toLowerCase();
    final package = File('backend/package.json').readAsStringSync().toLowerCase();

    for (final forbidden in [
      'supabase',
      'firebase',
      '/api/v1/account/',
      'bearer ',
      'requireuser',
      'registerdevice',
      'cloud_sync',
      'google-auth-library',
    ]) {
      expect(backend.contains(forbidden), isFalse, reason: forbidden);
      expect(package.contains(forbidden), isFalse, reason: forbidden);
    }
  });

  test('flutter api client does not support bearer tokens or private routes', () {
    final client = File('lib/core/network/fcbaz_api.dart')
        .readAsStringSync()
        .toLowerCase();

    expect(client.contains('bearertoken'), isFalse);
    expect(client.contains('authorizationheader'), isFalse);
    expect(client.contains('/api/v1/account/'), isFalse);
    expect(client.contains('/api/v1/push/'), isFalse);
  });
}
