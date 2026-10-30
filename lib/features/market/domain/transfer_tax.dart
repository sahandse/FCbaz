/// FC transfer market takes a 5% tax on every completed sale. The tax is
/// rounded to the nearest coin and the seller receives the rest.
const double kTransferTaxRate = 0.05;

class TransferTaxResult {
  const TransferTaxResult({
    required this.buyPrice,
    required this.salePrice,
    required this.tax,
    required this.net,
    required this.profit,
    required this.roiPercent,
    required this.breakEvenSalePrice,
  });

  final int buyPrice;
  final int salePrice;
  final int tax;
  final int net;
  final int profit;
  final double? roiPercent;
  final int breakEvenSalePrice;

  bool get isProfit => profit > 0;
  bool get isLoss => profit < 0;
}

class TransferTaxCalculator {
  const TransferTaxCalculator({this.rate = kTransferTaxRate});

  final double rate;

  int taxFor(int salePrice) => salePrice <= 0 ? 0 : (salePrice * rate).round();

  /// Returns null when the inputs cannot describe a real sale, so callers never
  /// display a made-up result.
  TransferTaxResult? evaluate({required int buyPrice, required int salePrice}) {
    if (buyPrice < 0 || salePrice <= 0) return null;
    final tax = taxFor(salePrice);
    final net = salePrice - tax;
    final profit = net - buyPrice;
    final double? roi = buyPrice > 0 ? profit / buyPrice * 100 : null;
    final breakEven = (buyPrice / (1 - rate)).ceil();
    return TransferTaxResult(
      buyPrice: buyPrice,
      salePrice: salePrice,
      tax: tax,
      net: net,
      profit: profit,
      roiPercent: roi,
      breakEvenSalePrice: breakEven,
    );
  }
}
