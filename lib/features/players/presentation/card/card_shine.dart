import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A slow specular sweep for premium card finishes. It sits on its own layer,
/// pauses while the surrounding [TickerMode] is off, and paints a single static
/// frame when the platform asks for reduced motion.
class CardShine extends StatefulWidget {
  const CardShine({required this.glow, super.key});

  final Color glow;

  @override
  State<CardShine> createState() => _CardShineState();
}

class _CardShineState extends State<CardShine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _CardShinePainter(
              progress: _controller.value,
              glow: widget.glow,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardShinePainter extends CustomPainter {
  _CardShinePainter({required this.progress, required this.glow});

  final double progress;
  final Color glow;

  /// The sweep travels during the first 58% of the cycle, then the card rests
  /// so the effect reads as a glint rather than a constant animation.
  static const _sweepWindow = .58;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress >= _sweepWindow) return;

    final t = Curves.easeInOutCubic.transform(progress / _sweepWindow);
    final diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final band = Rect.fromCenter(
      center: Offset(-diagonal * .8 + diagonal * 1.6 * t, 0),
      width: diagonal * .42,
      height: diagonal * 1.6,
    );

    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..shader = LinearGradient(
        colors: [
          glow.withValues(alpha: 0),
          glow.withValues(alpha: .16),
          Colors.white.withValues(alpha: .24),
          glow.withValues(alpha: .1),
          glow.withValues(alpha: 0),
        ],
        stops: const [0, .32, .5, .68, 1],
      ).createShader(band);

    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(-math.pi / 5)
      ..drawRect(band, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _CardShinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.glow != glow;
}
