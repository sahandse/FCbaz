class PlayerPrice {
  const PlayerPrice({
    required this.playerId,
    required this.platform,
    required this.current,
    required this.low,
    required this.high,
    required this.change24hPercent,
    required this.updatedAt,
    this.lowestBins = const [],
  });

  final String playerId;
  final String platform;
  final int current;
  final int low;
  final int high;
  final double change24hPercent;
  final DateTime? updatedAt;
  final List<int> lowestBins;

  factory PlayerPrice.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
    double asDouble(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    DateTime? asDate(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString());

    List<int> bins = const [];
    final rawBins = json['lowest_bins'] ?? json['bins'];
    if (rawBins is List) {
      bins = rawBins
          .map(asInt)
          .where((e) => e > 0)
          .toList();
    }

    return PlayerPrice(
      playerId: (json['player_id'] ?? json['playerId'] ?? '').toString(),
      platform: (json['platform'] ?? 'console').toString(),
      current: asInt(json['current'] ?? json['price']),
      low: asInt(json['low']),
      high: asInt(json['high']),
      change24hPercent:
          asDouble(json['change_24h_percent'] ?? json['change24h']),
      updatedAt: asDate(json['updated_at'] ?? json['updatedAt']),
      lowestBins: bins,
    );
  }
}

class PricePoint {
  const PricePoint({required this.time, required this.price});

  final DateTime time;
  final int price;

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    return PricePoint(
      time: DateTime.tryParse((json['time'] ?? json['timestamp'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      price: rawPrice is int ? rawPrice : int.tryParse(rawPrice?.toString() ?? '') ?? 0,
    );
  }
}
