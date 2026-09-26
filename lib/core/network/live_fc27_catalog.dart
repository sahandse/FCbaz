import 'dart:convert';
import 'dart:io';

class LiveFc27Catalog {
  LiveFc27Catalog({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  static const _url =
      'https://raw.githubusercontent.com/sahandse/FCbaz/main/data/live/catalog.json';

  static Map<String, dynamic>? _memory;
  static DateTime? _loadedAt;

  Future<Map<String, dynamic>> load({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _memory != null &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < const Duration(minutes: 10)) {
      return _memory!;
    }

    final request = await _client.getUrl(Uri.parse(_url)).timeout(
          const Duration(seconds: 8),
        );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'FCBaz/1.2 Android FC27 companion',
    );

    final response = await request.close().timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Live catalog HTTP ${response.statusCode}');
    }

    final text = await utf8.decoder.bind(response).join();
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('Live FC27 catalog is not a JSON object');
    }

    final data = Map<String, dynamic>.from(decoded);
    if ((data['game_year'] ?? '').toString() != '27') {
      throw const FormatException('Live catalog is not FC27 data');
    }

    _memory = data;
    _loadedAt = DateTime.now();
    return data;
  }

  Future<List<Map<String, dynamic>>> list(
    String key, {
    bool forceRefresh = false,
  }) async {
    final data = await load(forceRefresh: forceRefresh);
    final raw = data[key];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<DateTime?> generatedAt() async {
    final data = await load();
    return DateTime.tryParse((data['generated_at'] ?? '').toString());
  }
}
