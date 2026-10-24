import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    this.size = 46,
    this.stroke = 5,
    this.label,
    this.color,
    this.semanticsLabel,
    super.key,
  });

  final double value;
  final double size;
  final double stroke;
  final String? label;
  final Color? color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final progress = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticsLabel ?? 'پیشرفت',
      value: '${(progress * 100).round()} درصد',
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _ProgressRingPainter(
                  value: progress,
                  stroke: stroke,
                  color: color ?? palette.primary,
                  track: palette.line,
                ),
              ),
              if (label != null)
                Text(
                  label!,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: math.max(11, size * .22),
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: palette.text,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.value,
    required this.stroke,
    required this.color,
    required this.track,
  });

  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (math.min(size.width, size.height) - stroke) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      paint..color = track,
    );
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        paint..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.stroke != stroke ||
      oldDelegate.color != color ||
      oldDelegate.track != track;
}
