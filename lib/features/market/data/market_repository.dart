import '../../../core/network/fcbaz_api.dart';
import '../../../core/network/public_fc_data.dart';
import '../../players/domain/player.dart';
import '../domain/player_price.dart';

class MarketRepository {
  MarketRepository({
    FCBazApi? api,
    PublicFcData? publicData,
  })  : api = api ?? FCBazApi(),
        publicData = publicData ?? PublicFcData();

  final FCBazApi api;
  final PublicFcData publicData;

  Future<PlayerPrice> getPlayerPrice(
    String playerId, {
    String platform = 'console',
    bool forceRefresh = false,
  }) async {
    try {
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
      if (raw is Map) {
        final parsed = PlayerPrice.fromJson(Map<String, dynamic>.from(raw));
        if (parsed.current > 0) return parsed;
      }
    } catch (_) {}

    final direct = await publicData.getPrice(
      playerId,
      platform: platform,
    );
    if (direct != null) {
      return PlayerPrice.fromJson(direct);
    }

    throw const FCBazApiException('قیمت زنده برای این کارت در دسترس نیست.');
  }

  Future<List<PricePoint>> getPriceHistory(
    String playerId, {
    String platform = 'console',
    String range = '7d',
    bool forceRefresh = false,
  }) async {
    try {
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
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => PricePoint.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.price > 0)
            .toList();
      }
    } catch (_) {}

    // Public free sources do not expose a reliable history series.
    return const [];
  }

  Future<List<Map<String, dynamic>>> getMarketFeed({
    bool forceRefresh = false,
  }) async {
    try {
      final json = await api.getJson(
        '/api/v1/market',
        forceRefresh: forceRefresh,
        cacheTtl: const Duration(seconds: 30),
      );
      final raw = json is Map ? (json['data'] ?? json['items'] ?? []) : json;
      if (raw is List) {
        final items = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (items.isNotEmpty) return items;
      }
    } catch (_) {}

    final players = await publicData.getTrending();
    return players
        .map((p) => {
              'player_id': p.id,
              'id': p.id,
              'name': p.name,
              'rating': p.rating,
              'price_ps': p.pricePs,
              'price_pc': p.pricePc,
              'source': 'futbin-public',
            })
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
      'sort': 'price_asc',
    };
    if (position != null && position.isNotEmpty) {
      params['position'] = position;
    }

    try {
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

      if (raw is List) {
        final players = raw
            .whereType<Map>()
            .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
            .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
            .toList();
        if (players.isNotEmpty) return players;
      }
    } catch (_) {}

    final direct = await publicData.getFiltered(params: params);
    final pc = platform == 'pc';
    final priced = direct
        .where((p) => (pc ? p.pricePc : p.pricePs) > 0)
        .toList();
    priced.sort(
      (a, b) =>
          (pc ? a.pricePc : a.pricePs).compareTo(pc ? b.pricePc : b.pricePs),
    );
    return priced;
  }

}
