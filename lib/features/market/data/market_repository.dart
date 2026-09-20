import '../../../core/network/fcbaz_api.dart';
import '../domain/player_price.dart';

class MarketRepository {
  MarketRepository({FCBazApi? api}) : api = api ?? FCBazApi();
  final FCBazApi api;

  Future<PlayerPrice> getPlayerPrice(String playerId, {String platform = 'console'}) async {
    final path = '/api/v1/market/players/' +
        Uri.encodeComponent(playerId) +
        '?platform=' +
        Uri.encodeQueryComponent(platform);
    final json = await api.getJson(path);
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
  }) async {
    final path = '/api/v1/market/players/' +
        Uri.encodeComponent(playerId) +
        '/history?platform=' +
        Uri.encodeQueryComponent(platform) +
        '&range=' +
        Uri.encodeQueryComponent(range);
    final json = await api.getJson(path);
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

  Future<List<Map<String, dynamic>>> getMarketFeed() async {
    final json = await api.getJson('/api/v1/market');
    final raw = json is Map ? (json['data'] ?? json['items'] ?? []) : json;
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
