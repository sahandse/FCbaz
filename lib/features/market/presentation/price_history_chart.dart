import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/player_price.dart';

class PriceHistoryChart extends StatelessWidget {
  const PriceHistoryChart({
    required this.points,
    required this.rangeLabel,
    super.key,
  });

  final List<PricePoint> points;
  final String rangeLabel;

  String _coins(int value) {
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
    if (points.length < 2) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text('داده کافی برای نمودار قیمت وجود ندارد'),
        ),
      );
    }

    final prices = points.map((e) => e.price).toList();
    final low = prices.reduce(math.min);
    final high = prices.reduce(math.max);
    final change = prices.last - prices.first;
    final positive = change >= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'نمودار قیمت ' + rangeLabel,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                (positive ? '+' : '') + _coins(change),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: positive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Low ' + _coins(low) + ' • High ' + _coins(high),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: _PriceChartPainter(
                points: points,
                lineColor: positive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.redAccent,
                gridColor: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  const _PriceChartPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
  });

  final List<PricePoint> points;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final values = points.map((e) => e.price.toDouble()).toList();
    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);

    if (minValue == maxValue) {
      minValue *= .98;
      maxValue *= 1.02;
      if (minValue == maxValue) {
        minValue -= 1;
        maxValue += 1;
      }
    }

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: .28)
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();

    Offset pointAt(int index) {
      final x = size.width * index / (points.length - 1);
      final normalized =
          (values[index] - minValue) / (maxValue - minValue);
      final y = size.height - normalized * size.height;
      return Offset(x, y);
    }

    final first = pointAt(0);
    path.moveTo(first.dx, first.dy);
    fillPath.moveTo(first.dx, size.height);
    fillPath.lineTo(first.dx, first.dy);

    for (var i = 1; i < points.length; i++) {
      final p = pointAt(i);
      path.lineTo(p.dx, p.dy);
      fillPath.lineTo(p.dx, p.dy);
    }

    final last = pointAt(points.length - 1);
    fillPath
      ..lineTo(last.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: .24),
          lineColor.withValues(alpha: .01),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = lineColor;
    canvas.drawCircle(last, 4.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
