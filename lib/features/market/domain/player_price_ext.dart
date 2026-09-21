import '../../../core/market/tax_calculator.dart';
import 'player_price.dart';

extension PlayerPriceTax on PlayerPrice {
  int get taxAmount => TaxCalculator.taxOn(current);

  int get netAfterTax => TaxCalculator.netAfterTax(current);

  List<int> get displayBins {
    final bins = lowestBins.where((e) => e > 0).toList();
    if (bins.isNotEmpty) return bins.take(3).toList();
    if (current > 0) return [current];
    return const [];
  }
}
