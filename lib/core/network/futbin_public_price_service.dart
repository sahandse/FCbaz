import 'dart:convert';
import 'dart:io';

class FutbinPublicPriceService {
  FutbinPublicPriceService({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;
  static const _base = 'https://www.futbin.org/futbin/api/';

  Future<Map<String, dynamic>?> byResourceId(
    String resourceId, {
    String platform = 'console',
  }) async {
    final normalized = resourceId.replaceFirst(RegExp(r'^ea-'), '').trim();
    if (normalized.isEmpty || int.tryParse(normalized) == null) return null;

    final p = platform == 'pc' ? 'PC' : 'PS';
    final uri = Uri.parse('${_base}fetchPriceInformation').replace(
      queryParameters: {
        'playerresource': normalized,
        'platform': p,
      },
    );

    try {
      final request = await _client.getUrl(uri).timeout(const Duration(seconds: 8));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 FCBaz/1.5',
      );
      request.headers.set('Referer', 'https://www.futbin.com/');
      request.headers.set('Origin', 'https://www.futbin.com');
      final response = await request.close().timeout(const Duration(seconds: 12));
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300 || body.trim().isEmpty) {
        return null;
      }
      final json = jsonDecode(body);
      if (json is! Map) return null;

      int coin(dynamic value) {
        if (value is num) return value.round();
        final raw = (value ?? '').toString().trim().toUpperCase().replaceAll(',', '');
        if (raw.isEmpty) return 0;
        var multiplier = 1.0;
        var number = raw;
        if (raw.endsWith('K')) {
          multiplier = 1000;
          number = raw.substring(0, raw.length - 1);
        } else if (raw.endsWith('M')) {
          multiplier = 1000000;
          number = raw.substring(0, raw.length - 1);
        }
        return ((double.tryParse(number) ?? 0) * multiplier).round();
      }

      final current = coin(json['price'] ?? json['LCPrice']);
      if (current <= 0) return null;
      return {
        'player_id': resourceId,
        'platform': platform,
        'current': current,
        'low': coin(json['MinPrice']),
        'high': coin(json['MaxPrice']),
        'change_24h_percent': null,
        'updated_text': (json['updated'] ?? '').toString(),
        'source': 'futbin-public-resource',
        'source_url': 'https://www.futbin.com/',
      };
    } catch (_) {
      return null;
    }
  }
}
