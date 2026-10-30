import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';

class StatRadarSeries {
  const StatRadarSeries({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<double> values;
}

/// A small six-axis radar used to compare real card face stats. Values are
/// expected on the 0–100 FC face-stat scale.
class StatRadarChart extends StatelessWidget {
  const StatRadarChart({
    required this.labels,
    required this.series,
    this.size = 244,
    super.key,
  });

  final List<String> labels;
  final List<StatRadarSeries> series;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final names = series.map((item) => item.label).join('، ');
    return Semantics(
      label: 'نمودار رادار ${labels.join('، ')} برای $names',
      child: Column(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RadarPainter(
                labels: labels,
                series: series,
                gridColor: palette.line,
                labelColor: palette.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final item in series)
                _Legend(color: item.color, label: item.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.labels,
    required this.series,
    required this.gridColor,
    required this.labelColor,
  });

  final List<String> labels;
  final List<StatRadarSeries> series;
  final Color gridColor;
  final Color labelColor;

  static const _rings = 4;

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.length < 3) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 30;
    if (radius <= 0) return;
    final step = 2 * math.pi / labels.length;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridColor.withValues(alpha: .55);

    for (var ring = 1; ring <= _rings; ring++) {
      final ringRadius = radius * ring / _rings;
      final path = Path();
      for (var i = 0; i < labels.length; i++) {
        final point = _point(center, -math.pi / 2 + step * i, ringRadius);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var i = 0; i < labels.length; i++) {
      final point = _point(center, -math.pi / 2 + step * i, radius);
      canvas.drawLine(center, point, gridPaint);
      _paintLabel(
        canvas,
        labels[i],
        _point(center, -math.pi / 2 + step * i, radius + 17),
      );
    }

    for (final item in series) {
      if (item.values.length != labels.length) continue;
      final path = Path();
      for (var i = 0; i < labels.length; i++) {
        final value = item.values[i].clamp(0, 100) / 100;
        final point = _point(center, -math.pi / 2 + step * i, radius * value);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = item.color.withValues(alpha: .14),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = item.color,
      );
      for (var i = 0; i < labels.length; i++) {
        final value = item.values[i].clamp(0, 100) / 100;
        canvas.drawCircle(
          _point(center, -math.pi / 2 + step * i, radius * value),
          2.4,
          Paint()..color = item.color,
        );
      }
    }
  }

  Offset _point(Offset center, double angle, double distance) => Offset(
    center.dx + math.cos(angle) * distance,
    center.dy + math.sin(angle) * distance,
  );

  void _paintLabel(Canvas canvas, String text, Offset anchor) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: labelColor,
        ),
      ),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      Offset(anchor.dx - painter.width / 2, anchor.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    if (oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.labels.length != labels.length ||
        oldDelegate.series.length != series.length) {
      return true;
    }
    for (var i = 0; i < series.length; i++) {
      final a = series[i];
      final b = oldDelegate.series[i];
      if (a.color != b.color || a.label != b.label) return true;
      if (a.values.length != b.values.length) return true;
      for (var j = 0; j < a.values.length; j++) {
        if (a.values[j] != b.values[j]) return true;
      }
    }
    return false;
  }
}
