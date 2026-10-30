import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';
import '../utils/persian_formatters.dart';

/// A compact line of real local observations. With fewer than two prices it
/// shows a dash instead of inventing a trend line.
class PriceSparkline extends StatelessWidget {
  const PriceSparkline({
    required this.prices,
    this.width = 60,
    this.height = 22,
    this.color,
    super.key,
  });

  final List<int> prices;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final values = prices.where((price) => price > 0).toList(growable: false);
    if (values.length < 2) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            '—',
            style: TextStyle(color: palette.textMuted, fontSize: 11),
          ),
        ),
      );
    }

    final rising = values.last > values.first;
    final flat = values.last == values.first;
    final resolved =
        color ??
        (flat
            ? palette.textMuted
            : rising
            ? palette.success
            : palette.danger);
    final direction = flat
        ? 'بدون تغییر'
        : rising
        ? 'افزایش'
        : 'کاهش';

    return Semantics(
      label:
          'روند محلی ${faDigits(values.length)} مشاهده، $direction '
          'از ${faDigits(values.first)} به ${faDigits(values.last)} سکه',
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparklinePainter(values: values, color: resolved),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<int> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    final stepX = size.width / (values.length - 1);
    const padding = 2.5;
    final usableHeight = size.height - padding * 2;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final fraction = range == 0 ? .5 : (values[i] - min) / range;
      final x = i * stepX;
      final y = padding + usableHeight * (1 - fraction);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    final lastFraction = range == 0 ? .5 : (values.last - min) / range;
    canvas.drawCircle(
      Offset(size.width, padding + usableHeight * (1 - lastFraction)),
      2,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    if (oldDelegate.color != color) return true;
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}
