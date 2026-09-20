import 'dart:convert';
import 'dart:io';

import '../../features/players/domain/player.dart';

class FCBazApiException implements Exception {
  const FCBazApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class FCBazApi {
  FCBazApi({HttpClient? client}) : _client = client ?? HttpClient();

  static const baseUrl = String.fromEnvironment('FCBAZ_API_BASE_URL');
  final HttpClient _client;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  Future<List<Player>> fetchPlayers() async {
    final json = await getJson('/api/v1/players');
    final raw = json is Map ? (json['data'] ?? json['players']) : json;
    if (raw is! List) {
      throw const FCBazApiException('پاسخ بازیکنان معتبر نیست.');
    }
    return raw
        .whereType<Map>()
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();
  }

  Future<List<Player>> searchPlayers(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final json = await getJson('/api/v1/players/search?q=$encoded');
    final raw = json is Map ? (json['data'] ?? json['players']) : json;
    if (raw is! List) {
      throw const FCBazApiException('پاسخ جستجو معتبر نیست.');
    }
    return raw
        .whereType<Map>()
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();
  }

  Future<Player> fetchPlayer(String id) async {
    final json = await getJson('/api/v1/players/' + Uri.encodeComponent(id));
    final raw = json is Map ? (json['data'] ?? json['player'] ?? json) : json;
    if (raw is! Map) {
      throw const FCBazApiException('جزئیات بازیکن معتبر نیست.');
    }
    return Player.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<dynamic> getJson(
    String path, {
    String? bearerToken,
  }) =>
      _requestJson(
        method: 'GET',
        path: path,
        bearerToken: bearerToken,
      );

  Future<dynamic> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? bearerToken,
  }) =>
      _requestJson(
        method: 'POST',
        path: path,
        body: body,
        bearerToken: bearerToken,
      );

  Future<dynamic> _requestJson({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    if (!isConfigured) {
      throw const FCBazApiException('Backend FCBaz هنوز متصل نشده است.');
    }

    final uri = Uri.parse(baseUrl).resolve(path);
    final request = await (method == 'POST'
            ? _client.postUrl(uri)
            : _client.getUrl(uri))
        .timeout(const Duration(seconds: 8));

    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set('X-FCBaz-Game-Year', '27');

    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

    if (bearerToken != null && bearerToken.trim().isNotEmpty) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ' + bearerToken.trim(),
      );
    }

    final response =
        await request.close().timeout(const Duration(seconds: 15));
    final responseBody = await utf8.decoder.bind(response).join();

    dynamic decoded;
    if (responseBody.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(responseBody);
      } on FormatException {
        throw const FCBazApiException('پاسخ سرور قابل خواندن نیست.');
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? (decoded['message'] ?? decoded['error'])?.toString()
          : null;
      throw FCBazApiException(
        message?.isNotEmpty == true
            ? message!
            : 'خطای سرور (' + response.statusCode.toString() + ')',
      );
    }

    return decoded;
  }
}
