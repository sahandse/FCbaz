/// EA Ultimate Team sale tax helpers (5%).
class TaxCalculator {
  const TaxCalculator._();

  static const double taxRate = 0.05;

  static int taxOn(int salePrice) {
    if (salePrice <= 0) return 0;
    return (salePrice * taxRate).round();
  }

  static int netAfterTax(int salePrice) {
    if (salePrice <= 0) return 0;
    return salePrice - taxOn(salePrice);
  }

  /// Buy price needed so that after 5% tax you still profit at [sellPrice].
  static int maxBuyForProfit(int sellPrice) {
    if (sellPrice <= 0) return 0;
    return netAfterTax(sellPrice) - 1;
  }

  static int profit({
    required int buyPrice,
    required int sellPrice,
  }) {
    return netAfterTax(sellPrice) - buyPrice;
  }
}
