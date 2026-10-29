import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';

/// Paper Pitch: a warm paper background with faint pitch markings, used behind
/// the tab content in the light theme. Dark mode keeps its flat arena look.
class PaperPitchBackground extends StatelessWidget {
  const PaperPitchBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.light) return child;
    final palette = context.palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: IgnorePointer(
            child: CustomPaint(
              key: const ValueKey('paper-pitch-lines'),
              painter: _PaperPitchPainter(
                lineColor: palette.lineStrong.withValues(alpha: .26),
                grainColor: palette.lineStrong.withValues(alpha: .08),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PaperPitchPainter extends CustomPainter {
  const _PaperPitchPainter({required this.lineColor, required this.grainColor});

  final Color lineColor;
  final Color grainColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = lineColor;

    final field = RRect.fromRectAndRadius(
      Rect.fromLTWH(18, 28, size.width - 36, size.height - 56),
      const Radius.circular(22),
    );
    canvas.drawRRect(field, stroke);

    final rect = field.outerRect;
    final center = rect.center;
    final halfwayY = center.dy;
    canvas.drawLine(
      Offset(rect.left, halfwayY),
      Offset(rect.right, halfwayY),
      stroke,
    );
    canvas.drawCircle(center, math.min(rect.width, rect.height) * .1, stroke);
    canvas.drawCircle(center, 1.8, Paint()..color = lineColor);

    final boxWidth = rect.width * .54;
    final boxHeight = rect.height * .13;
    final sixWidth = rect.width * .27;
    final sixHeight = rect.height * .055;
    for (final atTop in [true, false]) {
      final top = atTop ? rect.top : rect.bottom - boxHeight;
      final box = Rect.fromLTWH(
        center.dx - boxWidth / 2,
        top,
        boxWidth,
        boxHeight,
      );
      canvas.drawRect(box, stroke);
      final sixTop = atTop ? rect.top : rect.bottom - sixHeight;
      final six = Rect.fromLTWH(
        center.dx - sixWidth / 2,
        sixTop,
        sixWidth,
        sixHeight,
      );
      canvas.drawRect(six, stroke);
    }

    final random = math.Random(27);
    final dot = Paint()
      ..style = PaintingStyle.fill
      ..color = grainColor;
    for (var i = 0; i < 160; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), .45 + random.nextDouble() * .85, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPitchPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.grainColor != grainColor;
}
