import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Free community content hosted on GitHub (bundled + raw refresh).
///
/// Never invents live EA market/SBC prices. Guides are clearly sourced.
class FreeGithubContent {
  FreeGithubContent({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  static const assetPath = 'assets/data/free_content.json';
  static const githubRaw =
      'https://raw.githubusercontent.com/sahandse/FCbaz/cursor/persian-futbin-free-data-5185/assets/data/free_content.json';
  static const githubRawMain =
      'https://raw.githubusercontent.com/sahandse/FCbaz/main/assets/data/free_content.json';

  static Map<String, dynamic>? _cached;
  static DateTime? _cachedAt;

  Future<Map<String, dynamic>> load({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < const Duration(hours: 6)) {
      return _cached!;
    }

    final remote = await _downloadFirst([githubRaw, githubRawMain]);
    if (remote != null) {
      _cached = remote;
      _cachedAt = DateTime.now();
      return remote;
    }

    final bundled = await _loadBundled();
    _cached = bundled;
    _cachedAt = DateTime.now();
    return bundled;
  }

  Future<List<Map<String, dynamic>>> news({bool forceRefresh = false}) async {
    final data = await load(forceRefresh: forceRefresh);
    return _maps(data['news']);
  }

  Future<List<Map<String, dynamic>>> objectives({
    bool forceRefresh = false,
  }) async {
    final data = await load(forceRefresh: forceRefresh);
    return _maps(data['objectives']);
  }

  Future<List<Map<String, dynamic>>> sbcs({bool forceRefresh = false}) async {
    final data = await load(forceRefresh: forceRefresh);
    return _maps(data['sbcs']);
  }

  Future<List<Map<String, dynamic>>> evolutions({
    bool forceRefresh = false,
  }) async {
    final data = await load(forceRefresh: forceRefresh);
    return _maps(data['evolutions']);
  }

  Future<List<Map<String, dynamic>>> scoutLists({
    bool forceRefresh = false,
  }) async {
    final data = await load(forceRefresh: forceRefresh);
    return _maps(data['scout_lists']);
  }

  /// Downloads a free scout list from EAFC26-DataHub (or any URL in free_content).
  Future<List<Map<String, dynamic>>> fetchScoutList(String url) async {
    try {
      final request = await _client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, 'FCBaz/1.0');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response =
          await request.close().timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) return const [];
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, dynamic>> _loadBundled() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return const {};
  }

  Future<Map<String, dynamic>?> _downloadFirst(List<String> urls) async {
    for (final url in urls) {
      try {
        final request = await _client.getUrl(Uri.parse(url));
        request.headers.set(HttpHeaders.userAgentHeader, 'FCBaz/1.0');
        final response =
            await request.close().timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) continue;
        final body = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
