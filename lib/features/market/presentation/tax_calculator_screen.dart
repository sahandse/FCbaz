import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/market/tax_calculator.dart';

class TaxCalculatorScreen extends StatefulWidget {
  const TaxCalculatorScreen({super.key, this.initialPrice = 0});

  final int initialPrice;

  @override
  State<TaxCalculatorScreen> createState() => _TaxCalculatorScreenState();
}

class _TaxCalculatorScreenState extends State<TaxCalculatorScreen> {
  late final TextEditingController sell =
      TextEditingController(text: widget.initialPrice > 0 ? '${widget.initialPrice}' : '');
  late final TextEditingController buy = TextEditingController();

  int get sellPrice => int.tryParse(sell.text.replaceAll(',', '')) ?? 0;
  int get buyPrice => int.tryParse(buy.text.replaceAll(',', '')) ?? 0;

  @override
  void dispose() {
    sell.dispose();
    buy.dispose();
    super.dispose();
  }

  String _coins(int value) {
    if (value <= 0) return '0';
    if (value >= 1000000) {
      final n = value / 1000000;
      return n.toStringAsFixed(n >= 10 ? 0 : 1) + 'M';
    }
    if (value >= 1000) {
      final n = value / 1000;
      return n.toStringAsFixed(n >= 100 ? 0 : 1) + 'K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final tax = TaxCalculator.taxOn(sellPrice);
    final net = TaxCalculator.netAfterTax(sellPrice);
    final maxBuy = TaxCalculator.maxBuyForProfit(sellPrice);
    final profit = TaxCalculator.profit(buyPrice: buyPrice, sellPrice: sellPrice);

    return Scaffold(
      appBar: AppBar(title: const Text('ماشین‌حساب مالیات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'مالیات فروش بازار ۵٪ است. با این ابزار سود واقعی را حساب کنید.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: sell,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'قیمت فروش (BIN)',
              prefixIcon: Icon(Icons.sell_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: buy,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'قیمت خرید شما (اختیاری)',
              prefixIcon: Icon(Icons.shopping_cart_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          _ResultCard(label: 'مالیات ۵٪', value: _coins(tax)),
          const SizedBox(height: 8),
          _ResultCard(label: 'دریافتی بعد از مالیات', value: _coins(net)),
          const SizedBox(height: 8),
          _ResultCard(
            label: 'حداکثر خرید برای سود',
            value: _coins(maxBuy),
          ),
          if (buyPrice > 0) ...[
            const SizedBox(height: 8),
            _ResultCard(
              label: profit >= 0 ? 'سود خالص' : 'زیان خالص',
              value: _coins(profit.abs()),
              emphasis: profit >= 0,
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: emphasis ? scheme.primary.withValues(alpha: .10) : null,
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
    );
  }
}
