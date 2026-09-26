import '../../../core/network/fcbaz_api.dart';
import '../../../core/network/futbin_public_price_service.dart';
import '../../../core/network/public_fc_data.dart';
import '../../players/domain/player.dart';
import '../domain/player_price.dart';

class MarketRepository {
  MarketRepository({
    FCBazApi? api,
    PublicFcData? publicData,
    FutbinPublicPriceService? futbinPrice,
  })  : api = api ?? FCBazApi(),
        publicData = publicData ?? PublicFcData(),
        futbinPrice = futbinPrice ?? FutbinPublicPriceService();

  final FCBazApi api;
  final PublicFcData publicData;
  final FutbinPublicPriceService futbinPrice;

  Future<PlayerPrice> getPlayerPrice(
    String playerId, {
    String platform = 'console',
    bool forceRefresh = false,
  }) async {
    if (api.isConfigured) {
      try {
        final path = '/api/v1/players/' +
            Uri.encodeComponent(playerId) +
            '/price?platform=' +
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
    }

    if (playerId.startsWith('ea-')) {
      final byResource = await futbinPrice.byResourceId(
        playerId,
        platform: platform,
      );
      if (byResource != null) {
        final parsed = PlayerPrice.fromJson(byResource);
        if (parsed.current > 0) return parsed;
      }
    }

    final direct = await publicData.getPrice(
      playerId,
      platform: platform,
    );
    if (direct != null) {
      final parsed = PlayerPrice.fromJson(direct);
      if (parsed.current > 0) return parsed;
    }

    throw const FCBazApiException('قیمت زنده برای این کارت در دسترس نیست.');
  }

  Future<List<PricePoint>> getPriceHistory(
    String playerId, {
    String platform = 'console',
    String range = '7d',
    bool forceRefresh = false,
  }) async {
    if (!api.isConfigured) {
      throw const FCBazApiException(
        'تاریخچه قیمت فقط وقتی نمایش داده می‌شود که منبع واقعی History متصل باشد.',
      );
    }

    final path = '/api/v1/players/' +
        Uri.encodeComponent(playerId) +
        '/price-history?platform=' +
        Uri.encodeQueryComponent(platform) +
        '&graph_type=' +
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
    if (api.isConfigured) {
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
              .where(_hasRealMarketValue)
              .toList();
          if (items.isNotEmpty) return items;
        }
      } catch (_) {}
    }

    final popular = await publicData.getTrending();
    final priced = <Map<String, dynamic>>[];
    for (final player in popular.take(12)) {
      Map<String, dynamic>? price;
      if (player.id.startsWith('ea-')) {
        price = await futbinPrice.byResourceId(player.id);
      }
      price ??= await publicData.getPrice(player.id);
      if (price == null || (price['current'] as int? ?? 0) <= 0) continue;
      priced.add({
        'player_id': player.id,
        'id': player.id,
        'name': player.name,
        'rating': player.rating,
        'price': price['current'],
        'current': price['current'],
        'low': price['low'],
        'high': price['high'],
        'change_24h_percent': null,
        'source': price['source'],
        'source_url': price['source_url'],
      });
    }
    return priced;
  }

  bool _hasRealMarketValue(Map<String, dynamic> item) {
    int value(dynamic raw) =>
        raw is num ? raw.round() : int.tryParse((raw ?? '').toString()) ?? 0;
    return value(item['price'] ?? item['current'] ?? item['price_ps']) > 0 ||
        value(item['price_pc']) > 0;
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

    if (api.isConfigured) {
      try {
        final query = params.entries
            .map((e) =>
                '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
            .join('&');

        final json = await api.getJson(
          '/api/v1/market/cheapest?$query',
          forceRefresh: forceRefresh,
          cacheTtl: const Duration(seconds: 45),
        );
        final raw = json is Map ? (json['data'] ?? json['players'] ?? []) : json;

        if (raw is List) {
          final players = raw
              .whereType<Map>()
              .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
              .where((p) =>
                  p.id.isNotEmpty &&
                  p.name.isNotEmpty &&
                  (platform == 'pc' ? p.pricePc : p.pricePs) > 0)
              .toList();
          if (players.isNotEmpty) return players;
        }
      } catch (_) {}
    }

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
