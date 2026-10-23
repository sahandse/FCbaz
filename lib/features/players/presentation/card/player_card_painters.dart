import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'player_card_theme.dart';

Path futCardPath(Size size) {
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(w * .135, 0)
    ..lineTo(w * .865, 0)
    ..lineTo(w, h * .085)
    ..lineTo(w, h * .93)
    ..quadraticBezierTo(w, h, w * .92, h)
    ..lineTo(w * .08, h)
    ..quadraticBezierTo(0, h, 0, h * .93)
    ..lineTo(0, h * .085)
    ..close();
}

class FutCardClipper extends CustomClipper<Path> {
  const FutCardClipper();

  @override
  Path getClip(Size size) => futCardPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class CardSurfacePainter extends CustomPainter {
  const CardSurfacePainter(this.theme);

  final PlayerCardTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(futCardPath(size));

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.55, -.85),
          radius: 1.1,
          colors: [Colors.white.withValues(alpha: .22), Colors.white.withValues(alpha: 0)],
        ).createShader(rect),
    );

    canvas.save();
    canvas.translate(size.width * .5, size.height * .5);
    canvas.rotate(-.42);
    final band = Paint()..color = Colors.white.withValues(alpha: .055);
    canvas.drawRect(
      Rect.fromLTWH(-size.width * .9, -size.height * .18, size.width * 1.8, size.height * .12),
      band,
    );
    canvas.drawRect(
      Rect.fromLTWH(-size.width * .9, size.height * .12, size.width * 1.8, size.height * .28),
      Paint()..color = Colors.white.withValues(alpha: .035),
    );
    canvas.restore();

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.width * .006)
      ..color = theme.accent.withValues(alpha: .16);
    canvas.drawCircle(Offset(size.width * .92, size.height * .16), size.width * .42, ring);
    canvas.drawCircle(Offset(size.width * .92, size.height * .16), size.width * .58, ring);

    final dotPaint = Paint()..color = theme.ink.withValues(alpha: .08);
    final step = size.width * .085;
    final radius = math.max(.6, size.width * .0055);
    for (var y = size.height * .58; y < size.height * .95; y += step) {
      for (var x = size.width * .06; x < size.width * .42; x += step) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CardSurfacePainter oldDelegate) => oldDelegate.theme != theme;
}

class CardFramePainter extends CustomPainter {
  const CardFramePainter(this.theme);

  final PlayerCardTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final path = futCardPath(size);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.1, size.width * .007)
        ..color = Colors.white.withValues(alpha: .34),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, size.width * .004)
        ..color = theme.shadow.withValues(alpha: .28),
    );
  }

  @override
  bool shouldRepaint(covariant CardFramePainter oldDelegate) => oldDelegate.theme != theme;
}
