import '../../../core/network/fcbaz_api.dart';
import '../../players/domain/player.dart';
import '../domain/player_price.dart';

class MarketRepository {
  MarketRepository({FCBazApi? api}) : api = api ?? FCBazApi();
  final FCBazApi api;

  Future<PlayerPrice> getPlayerPrice(
    String playerId, {
    String platform = 'console',
    bool forceRefresh = false,
  }) async {
    final path = '/api/v1/market/players/' +
        Uri.encodeComponent(playerId) +
        '?platform=' +
        Uri.encodeQueryComponent(platform);
    final json = await api.getJson(
      path,
      forceRefresh: forceRefresh,
      cacheTtl: const Duration(seconds: 30),
    );
    final raw = json is Map ? (json['data'] ?? json['price'] ?? json) : json;
    if (raw is! Map) {
      throw const FCBazApiException('اطلاعات قیمت معتبر نیست.');
    }
    return PlayerPrice.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<List<PricePoint>> getPriceHistory(
    String playerId, {
    String platform = 'console',
    String range = '7d',
    bool forceRefresh = false,
  }) async {
    final path = '/api/v1/market/players/' +
        Uri.encodeComponent(playerId) +
        '/history?platform=' +
        Uri.encodeQueryComponent(platform) +
        '&range=' +
        Uri.encodeQueryComponent(range);
    final json = await api.getJson(
      path,
      forceRefresh: forceRefresh,
      cacheTtl: const Duration(minutes: 2),
    );
    final raw = json is Map ? (json['data'] ?? json['history'] ?? []) : json;
    if (raw is! List) {
      throw const FCBazApiException('تاریخچه قیمت معتبر نیست.');
    }
    return raw
        .whereType<Map>()
        .map((e) => PricePoint.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.price > 0)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMarketFeed({
    bool forceRefresh = false,
  }) async {
    final json = await api.getJson(
      '/api/v1/market',
      forceRefresh: forceRefresh,
      cacheTtl: const Duration(seconds: 30),
    );
    final raw = json is Map ? (json['data'] ?? json['items'] ?? []) : json;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Player>> getCheapestPlayers({
    int minRating = 75,
    int maxRating = 99,
    String? position,
    String platform = 'console',
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final params = <String, String>{
      'min_rating': minRating.toString(),
      'max_rating': maxRating.toString(),
      'platform': platform,
      'page': page.toString(),
    };
    if (position != null && position.isNotEmpty) {
      params['position'] = position;
    }

    final query = params.entries
        .map((e) =>
            Uri.encodeQueryComponent(e.key) +
            '=' +
            Uri.encodeQueryComponent(e.value))
        .join('&');

    final json = await api.getJson(
      '/api/v1/market/cheapest?' + query,
      forceRefresh: forceRefresh,
      cacheTtl: const Duration(seconds: 45),
    );
    final raw = json is Map ? (json['data'] ?? json['players'] ?? []) : json;
    if (raw is! List) {
      throw const FCBazApiException('لیست ارزان‌ترین بازیکنان معتبر نیست.');
    }

    return raw
        .whereType<Map>()
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();
  }
}
