import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'player_card_theme.dart';

Path fc27CardPath(Size size, {bool ornate = false}) {
  final w = size.width;
  final h = size.height;
  final path = Path();

  if (ornate) {
    path
      ..moveTo(w * .5, h * .010)
      ..quadraticBezierTo(w * .486, h * .016, w * .474, h * .036)
      ..quadraticBezierTo(w * .462, h * .052, w * .444, h * .042)
      ..lineTo(w * .352, h * .014);
  } else {
    path
      ..moveTo(w * .5, h * .038)
      ..quadraticBezierTo(w * .478, h * .030, w * .452, h * .018)
      ..lineTo(w * .352, h * .012);
  }

  path
    ..quadraticBezierTo(w * .318, h * .006, w * .300, h * .020)
    ..lineTo(w * .218, h * .046)
    ..quadraticBezierTo(w * .168, h * .062, w * .160, h * .102)
    ..cubicTo(w * .146, h * .164, w * .156, h * .228, w * .142, h * .288)
    ..cubicTo(w * .124, h * .326, w * .060, h * .344, w * .032, h * .382)
    ..quadraticBezierTo(w * .010, h * .402, w * .018, h * .424)
    ..quadraticBezierTo(w * .026, h * .444, w * .052, h * .450)
    ..cubicTo(w * .044, h * .480, w * .050, h * .508, w * .080, h * .534)
    ..cubicTo(w * .090, h * .620, w * .094, h * .700, w * .120, h * .800)
    ..cubicTo(w * .185, h * .890, w * .405, h * .970, w * .500, h * 1.000)
    ..cubicTo(w * .595, h * .970, w * .815, h * .890, w * .880, h * .800)
    ..cubicTo(w * .906, h * .700, w * .910, h * .620, w * .920, h * .534)
    ..cubicTo(w * .950, h * .508, w * .956, h * .480, w * .948, h * .450)
    ..quadraticBezierTo(w * .974, h * .444, w * .982, h * .424)
    ..quadraticBezierTo(w * .990, h * .402, w * .968, h * .382)
    ..cubicTo(w * .940, h * .344, w * .876, h * .326, w * .858, h * .288)
    ..cubicTo(w * .844, h * .228, w * .854, h * .164, w * .840, h * .102)
    ..quadraticBezierTo(w * .832, h * .062, w * .782, h * .046)
    ..lineTo(w * .700, h * .020)
    ..quadraticBezierTo(w * .682, h * .006, w * .648, h * .012);

  if (ornate) {
    path
      ..lineTo(w * .556, h * .042)
      ..quadraticBezierTo(w * .538, h * .052, w * .526, h * .036)
      ..quadraticBezierTo(w * .514, h * .016, w * .500, h * .010);
  } else {
    path
      ..lineTo(w * .548, h * .018)
      ..quadraticBezierTo(w * .522, h * .030, w * .500, h * .038);
  }

  return path..close();
}

class FutCardClipper extends CustomClipper<Path> {
  const FutCardClipper({this.ornate = false});

  final bool ornate;

  @override
  Path getClip(Size size) => fc27CardPath(size, ornate: ornate);

  @override
  bool shouldReclip(covariant FutCardClipper oldClipper) =>
      oldClipper.ornate != ornate;
}

class CardSurfacePainter extends CustomPainter {
  const CardSurfacePainter(this.theme);

  final PlayerCardTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final path = fc27CardPath(size, ornate: theme.ornate);
    canvas.save();
    canvas.clipPath(path);

    switch (theme.finish) {
      case CardFinish.satin:
        _paintSatin(canvas, size);
      case CardFinish.marble:
        _paintMarble(canvas, size);
      case CardFinish.holo:
        _paintHolo(canvas, size);
    }

    final shadeRect = Rect.fromLTRB(
      0,
      size.height * .56,
      size.width,
      size.height,
    );
    final shadeAlpha = theme.finish == CardFinish.marble
        ? .10
        : (theme.finish == CardFinish.holo ? .16 : .22);
    canvas.drawRect(
      shadeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            theme.shadow.withValues(alpha: shadeAlpha),
          ],
        ).createShader(shadeRect),
    );

    canvas.restore();
  }

  void _paintSatin(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w * .5, h * .44);
    canvas.rotate(-.48);
    for (var i = -4; i <= 4; i++) {
      final band = Rect.fromLTWH(
        -w * 1.2,
        i * h * .115 - h * .028,
        w * 2.4,
        h * .058,
      );
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: i.isEven ? .13 : .07),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(band),
      );
    }
    canvas.restore();

    canvas.save();
    canvas.translate(w * .5, h * .46);
    canvas.rotate(-.48);
    for (var i = 0; i < 2; i++) {
      final fold = Rect.fromLTWH(
        -w * 1.2,
        -h * .18 + i * h * .24,
        w * 2.4,
        h * .27,
      );
      canvas.drawRect(
        fold,
        Paint()
          ..shader = LinearGradient(
            stops: const [0, .35, .5, .62, 1],
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: .02),
              Colors.white.withValues(alpha: .16),
              Colors.white.withValues(alpha: .04),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(fold),
      );
    }
    canvas.restore();

    final focus = Offset(w * .98, h * .03);
    final brush = Paint()
      ..strokeWidth = math.max(.5, w * .0024)
      ..color = Colors.white.withValues(alpha: .075);
    for (var i = 0; i <= 24; i++) {
      final t = i / 24;
      canvas.drawLine(focus, Offset(w * (-.02 + 1.04 * t), h), brush);
    }
    for (var i = 0; i <= 12; i++) {
      final t = i / 12;
      canvas.drawLine(focus, Offset(w * .02, h * (.42 + .56 * t)), brush);
    }

    final glowRect = Offset.zero & size;
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.5, -.9),
          radius: 1.05,
          colors: [
            Colors.white.withValues(alpha: .15),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(glowRect),
    );

    canvas.drawRect(
      Rect.fromLTRB(w * .34, h * .04, w * 1.02, h * .5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.glow.withValues(alpha: .20),
            theme.glow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTRB(w * .34, h * .04, w * 1.02, h * .5)),
    );
  }

  void _paintMarble(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final random = math.Random(27);

    for (var i = 0; i < 7; i++) {
      final center = Offset(
        w * (.1 + random.nextDouble() * .8),
        h * (.08 + random.nextDouble() * .5),
      );
      final radius = w * (.16 + random.nextDouble() * .2);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              (i.isEven ? Colors.white : theme.accent).withValues(alpha: .16),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    final veinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final shift = (random.nextDouble() - .5) * .08;
      final startX = random.nextDouble();
      final startY = -.04 + random.nextDouble() * .18;
      final vein = Path()
        ..moveTo(w * startX, h * startY)
        ..cubicTo(
          w * (startX + .12 + shift),
          h * (startY + .18),
          w * (startX - .18 + shift),
          h * (startY + .34),
          w * (startX + .04 + shift),
          h * (startY + .52),
        )
        ..cubicTo(
          w * (startX + .22 + shift),
          h * (startY + .66),
          w * (startX - .10 + shift),
          h * (startY + .78),
          w * (startX + .10 + shift),
          h * (startY + .98),
        );
      veinPaint
        ..strokeWidth = .7 + random.nextDouble() * 1.5
        ..color = theme.accent.withValues(
          alpha: .28 + random.nextDouble() * .28,
        );
      canvas.drawPath(vein, veinPaint);
      veinPaint
        ..strokeWidth = .45
        ..color = Colors.white.withValues(alpha: .36);
      canvas.translate(.7, .7);
      canvas.drawPath(vein, veinPaint);
      canvas.translate(-.7, -.7);
    }

    final mountain = Path()
      ..moveTo(w * .015, h * .865)
      ..lineTo(w * .5, h * .255)
      ..lineTo(w * .985, h * .865)
      ..close();
    canvas.drawPath(
      mountain,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .34),
            theme.glow.withValues(alpha: .08),
          ],
        ).createShader(Offset.zero & size),
    );

    for (var layer = 0; layer < 3; layer++) {
      final inset = w * (.015 + layer * .055);
      final ridge = Path()
        ..moveTo(inset, h * (.865 - layer * .022))
        ..lineTo(w * .5, h * (.255 + layer * .055))
        ..lineTo(w - inset, h * (.865 - layer * .022));
      canvas.drawPath(
        ridge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.4, w * (.025 - layer * .006))
          ..shader = LinearGradient(
            colors: [
              theme.accent.withValues(alpha: .75 - layer * .14),
              theme.glow.withValues(alpha: .95 - layer * .15),
              theme.accent.withValues(alpha: .75 - layer * .14),
            ],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(
        ridge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.5, w * (.005 - layer * .001))
          ..color = Colors.white.withValues(alpha: .55 - layer * .1),
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(w * .015, h * .865)
        ..lineTo(w * .5, h * .255)
        ..lineTo(w * .985, h * .865),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, w * .005)
        ..color = theme.line.withValues(alpha: .34),
    );

    final dust = Paint()..color = theme.accent.withValues(alpha: .3);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(
          w * (.12 + random.nextDouble() * .76),
          h * (.3 + random.nextDouble() * .56),
        ),
        .4 + random.nextDouble() * 1.1,
        dust,
      );
    }
  }

  void _paintHolo(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x3326E4FF),
            Color(0x33FF6BD6),
            Color(0x333FFFB0),
            Color(0x332C67FF),
          ],
          stops: [0, .38, .7, 1],
        ).createShader(rect),
    );

    canvas.save();
    canvas.translate(w * .5, h * .45);
    canvas.rotate(-.38);
    for (var i = -5; i <= 5; i++) {
      final band = Rect.fromLTWH(-w * 1.2, i * h * .095, w * 2.4, h * .034);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: .10),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(band),
      );
    }
    canvas.restore();

    final sparkle = Paint()..color = Colors.white.withValues(alpha: .6);
    final random = math.Random(11);
    for (var i = 0; i < 26; i++) {
      final center = Offset(
        w * (.06 + random.nextDouble() * .88),
        h * (.08 + random.nextDouble() * .74),
      );
      final radius = .4 + random.nextDouble() * 1.3;
      canvas.drawCircle(center, radius, sparkle);
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.75, -.9),
          radius: 1.1,
          colors: [
            Colors.white.withValues(alpha: .16),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CardSurfacePainter oldDelegate) =>
      oldDelegate.theme != theme;
}

class CardFramePainter extends CustomPainter {
  const CardFramePainter(this.theme);

  final PlayerCardTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final path = fc27CardPath(size, ornate: theme.ornate);
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.8, w * .015)
        ..color = theme.line.withValues(alpha: .94),
    );

    final metal = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * .0085)
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: theme.frame,
      ).createShader(rect);
    canvas.drawPath(path, metal);

    canvas.save();
    canvas.translate(w * .5, size.height * .5);
    canvas.scale(.978);
    canvas.translate(-w * .5, -size.height * .5);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, w * .0035)
        ..color = Colors.white.withValues(alpha: .34),
    );
    canvas.restore();

    if (theme.ornate) {
      canvas.save();
      canvas.translate(w * .5, size.height * .5);
      canvas.scale(.94);
      canvas.translate(-w * .5, -size.height * .5);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.6, w * .0025)
          ..color = theme.frame[1].withValues(alpha: .55),
      );
      canvas.restore();

      final leftFlourish = Path()
        ..moveTo(w * .022, h * .375)
        ..quadraticBezierTo(w * .078, h * .405, w * .052, h * .470)
        ..quadraticBezierTo(w * .044, h * .502, w * .080, h * .522);
      final flourish = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.2, w * .0055)
        ..color = theme.frame[1].withValues(alpha: .95);
      final flourishEdge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.8, w * .009)
        ..color = theme.line.withValues(alpha: .4);
      canvas.drawPath(leftFlourish, flourishEdge);
      canvas.drawPath(leftFlourish, flourish);
      canvas.save();
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
      canvas.drawPath(leftFlourish, flourishEdge);
      canvas.drawPath(leftFlourish, flourish);
      canvas.restore();

      final emblem = Offset(w * .5, size.height * .052);
      final radius = w * .033;
      canvas.drawCircle(
        emblem,
        radius,
        Paint()
          ..shader = LinearGradient(
            colors: theme.frame,
          ).createShader(Rect.fromCircle(center: emblem, radius: radius)),
      );
      canvas.drawCircle(
        emblem,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.7, w * .003)
          ..color = theme.line.withValues(alpha: .85),
      );
      canvas.drawPath(
        _starPath(emblem, radius * .62, radius * .26),
        Paint()..color = theme.line.withValues(alpha: .88),
      );
    }
  }

  Path _starPath(Offset center, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant CardFramePainter oldDelegate) =>
      oldDelegate.theme != theme;
}
