import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';

class StadiumHero extends StatelessWidget {
  const StadiumHero({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.metric,
    this.metricLabel,
    this.metricNote,
    this.trailing,
    this.primaryAction,
    this.secondaryAction,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final String? metric;
  final String? metricLabel;
  final String? metricNote;
  final Widget? trailing;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FcbazRadius.lg),
        border: Border.all(color: palette.primary.withValues(alpha: .28)),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.alphaBlend(
              palette.primary.withValues(alpha: .14),
              palette.surface,
            ),
            palette.surface,
            Color.alphaBlend(
              palette.secondary.withValues(alpha: .06),
              palette.surface,
            ),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FcbazRadius.lg - 1),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _StadiumRingsPainter(
                    color: palette.primary,
                    line: palette.secondary,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: -10,
              top: -18,
              child: IgnorePointer(
                child: Text(
                  'FC27',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w800,
                    fontSize: 96,
                    height: .8,
                    color: palette.primary.withValues(alpha: .06),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(FcbazSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _Eyebrow(text: eyebrow)),
                      if (trailing != null) ...[
                        const SizedBox(width: FcbazSpace.sm),
                        trailing!,
                      ],
                    ],
                  ),
                  const SizedBox(height: FcbazSpace.md),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 23,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: FcbazSpace.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        height: 1.65,
                      ),
                    ),
                  ],
                  if (metric != null && metricLabel != null) ...[
                    const SizedBox(height: FcbazSpace.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          metric!,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: 'BarlowCondensed',
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w800,
                            fontSize: 40,
                            height: .9,
                            letterSpacing: -.5,
                            color: palette.primary,
                          ),
                        ),
                        const SizedBox(width: FcbazSpace.sm),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  metricLabel!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (metricNote != null)
                                  Text(
                                    metricNote!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: palette.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (primaryAction != null || secondaryAction != null) ...[
                    const SizedBox(height: FcbazSpace.lg),
                    Row(
                      children: [
                        if (primaryAction != null)
                          Expanded(child: primaryAction!),
                        if (primaryAction != null && secondaryAction != null)
                          const SizedBox(width: FcbazSpace.sm),
                        if (secondaryAction != null)
                          Expanded(child: secondaryAction!),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: palette.primary,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          text.toUpperCase(),
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w800,
            fontSize: 10.5,
            letterSpacing: 1.1,
            color: palette.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _StadiumRingsPainter extends CustomPainter {
  _StadiumRingsPainter({required this.color, required this.line});

  final Color color;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .86, size.height * .94);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: .07);
    for (final factor in const [.38, .58, .78]) {
      canvas.drawCircle(center, size.width * factor, ring);
    }
    final diagonal = Paint()
      ..strokeWidth = 1
      ..color = line.withValues(alpha: .06);
    canvas.drawLine(
      Offset(size.width * .52, 0),
      Offset(size.width, size.height * .62),
      diagonal,
    );
  }

  @override
  bool shouldRepaint(covariant _StadiumRingsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.line != line;
}
