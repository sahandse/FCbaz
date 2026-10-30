import 'package:flutter/material.dart';

import '../../../src/theme/fcbaz_theme.dart';
import '../../../src/utils/persian_formatters.dart';
import '../domain/transfer_tax.dart';

class MarketTaxCalculatorPanel extends StatefulWidget {
  const MarketTaxCalculatorPanel({
    this.calculator = const TransferTaxCalculator(),
    super.key,
  });

  final TransferTaxCalculator calculator;

  @override
  State<MarketTaxCalculatorPanel> createState() =>
      _MarketTaxCalculatorPanelState();
}

class _MarketTaxCalculatorPanelState extends State<MarketTaxCalculatorPanel> {
  final buyController = TextEditingController();
  final sellController = TextEditingController();

  @override
  void dispose() {
    buyController.dispose();
    sellController.dispose();
    super.dispose();
  }

  int? _parse(String raw) {
    final normalized = raw
        .replaceAllMapped(
          RegExp('[۰-۹]'),
          (match) => '${match.group(0)!.codeUnitAt(0) - 0x06F0}',
        )
        .replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  bool _isInvalid(TextEditingController controller) =>
      controller.text.trim().isNotEmpty && _parse(controller.text) == null;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final buy = _parse(buyController.text);
    final sale = _parse(sellController.text);
    final hasBuy = buy != null && buy > 0;
    final result = sale == null || sale <= 0
        ? null
        : widget.calculator.evaluate(buyPrice: buy ?? 0, salePrice: sale);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Text(
          'TAX & PROFIT',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.2,
            color: palette.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'مالیات و سود خالص',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'قیمت خرید و فروش را وارد کن تا مالیات ۵٪، خالص دریافتی، سود یا ضرر و قیمت سربه‌سر را ببینی.',
          style: TextStyle(color: palette.textMuted, height: 1.6),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TextField(
                  controller: buyController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'قیمت خرید',
                    suffixText: 'سکه',
                    prefixIcon: Icon(Icons.shopping_cart_outlined),
                    border: OutlineInputBorder(),
                    errorText: null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_isInvalid(buyController))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'فقط عدد سکه پذیرفته می‌شود.',
                        style: TextStyle(fontSize: 11, color: palette.danger),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: sellController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'قیمت فروش',
                    suffixText: 'سکه',
                    prefixIcon: Icon(Icons.sell_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_isInvalid(sellController))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'فقط عدد سکه پذیرفته می‌شود.',
                        style: TextStyle(fontSize: 11, color: palette.danger),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (result == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Icon(
                    Icons.calculate_outlined,
                    color: palette.primary,
                    size: 34,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'قیمت فروش را وارد کن تا مالیات و خالص دریافتی محاسبه شود.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'بدون عدد واقعی، FCBaz نتیجه‌ای حدس نمی‌زند.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: palette.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                children: [
                  _ResultRow(
                    label: 'مالیات انتقال (۵٪)',
                    value: '${formatCoinsFa(result.tax)} سکه',
                    color: palette.warning,
                  ),
                  const Divider(height: 18),
                  _ResultRow(
                    label: 'خالص دریافتی',
                    value: '${formatCoinsFa(result.net)} سکه',
                    color: palette.text,
                    emphasized: true,
                  ),
                  if (hasBuy) ...[
                    const Divider(height: 18),
                    _ResultRow(
                      label: result.isLoss ? 'ضرر خالص' : 'سود خالص',
                      value: result.isLoss
                          ? '−${formatCoinsFa(-result.profit)} سکه'
                          : result.isProfit
                          ? '+${formatCoinsFa(result.profit)} سکه'
                          : 'بدون سود و ضرر',
                      color: result.isLoss
                          ? palette.danger
                          : result.isProfit
                          ? palette.success
                          : palette.textMuted,
                      emphasized: true,
                    ),
                    const Divider(height: 18),
                    _ResultRow(
                      label: 'بازده سرمایه',
                      value: result.roiPercent == null
                          ? '—'
                          : '${faDigits(result.roiPercent!.toStringAsFixed(1))}٪',
                      color: palette.text,
                    ),
                    const Divider(height: 18),
                    _ResultRow(
                      label: 'قیمت سربه‌سر فروش',
                      value: '${formatCoinsFa(result.breakEvenSalePrice)} سکه',
                      color: palette.secondary,
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'برای دیدن سود، بازده سرمایه و قیمت سربه‌سر، قیمت خرید را هم وارد کن.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.6,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.primary.withValues(alpha: .18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: palette.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'مالیات انتقال FC پنج درصد قیمت فروش است و به نزدیک‌ترین سکه گرد می‌شود. '
                  'قیمت سربه‌سر از تقسیم قیمت خرید بر ۰٫۹۵ و گرد کردن به بالا به دست می‌آید؛ '
                  'این ابزار فقط محاسبه می‌کند و قیمتی برای خرید پیشنهاد نمی‌دهد.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.6,
                    color: palette.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 14 : 13,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
