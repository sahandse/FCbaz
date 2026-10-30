import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../src/utils/persian_formatters.dart';
import '../../players/domain/player.dart';
import '../domain/squad_models.dart';

@immutable
class ChemistryLink {
  const ChemistryLink({
    required this.from,
    required this.to,
    required this.strength,
  });

  final Offset from;
  final Offset to;

  /// 1 = soft (one shared attribute), 2+ = strong (club, or league + nation).
  final int strength;

  bool get isStrong => strength >= 2;
}

/// A link exists when two in-position players share a club, league or nation
/// and both earn chemistry, matching the rules used by the chemistry engine.
List<ChemistryLink> buildChemistryLinks({
  required FormationDefinition formation,
  required Map<String, Player> players,
  required Map<String, int> chemistryBySlot,
  required Size size,
  double slotWidth = 74,
  double slotHeight = 86,
}) {
  final centers = <String, Offset>{
    for (final slot in formation.slots)
      slot.id: Offset(
        (size.width - slotWidth) * slot.x + slotWidth / 2,
        (size.height - slotHeight) * slot.y + slotHeight / 2,
      ),
  };

  final filled = [
    for (final slot in formation.slots)
      if (players[slot.id] != null) slot,
  ];

  final links = <ChemistryLink>[];
  for (var i = 0; i < filled.length; i++) {
    final a = players[filled[i].id]!;
    if ((chemistryBySlot[filled[i].id] ?? 0) <= 0) continue;
    for (var j = i + 1; j < filled.length; j++) {
      final b = players[filled[j].id]!;
      if ((chemistryBySlot[filled[j].id] ?? 0) <= 0) continue;

      var strength = 0;
      if (_same(a.clubName, b.clubName)) strength += 2;
      if (_same(a.leagueName, b.leagueName)) strength += 1;
      if (_same(a.nationName, b.nationName)) strength += 1;
      if (strength == 0) continue;

      links.add(
        ChemistryLink(
          from: centers[filled[i].id]!,
          to: centers[filled[j].id]!,
          strength: strength,
        ),
      );
    }
  }
  return links;
}

bool _same(String a, String b) {
  final left = a.trim().toLowerCase();
  final right = b.trim().toLowerCase();
  return left.isNotEmpty && right.isNotEmpty && left == right;
}

/// Draws the live chemistry web behind the squad slots: soft links breathe
/// slowly, strong links pulse brighter, and every new link grows from its
/// anchor when the lineup changes.
class ChemistryLinks extends StatefulWidget {
  const ChemistryLinks({
    required this.links,
    required this.strongColor,
    required this.weakColor,
    super.key,
  });

  final List<ChemistryLink> links;
  final Color strongColor;
  final Color weakColor;

  @override
  State<ChemistryLinks> createState() => _ChemistryLinksState();
}

class _ChemistryLinksState extends State<ChemistryLinks>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late String _signature = _signatureOf(widget.links);

  static String _signatureOf(List<ChemistryLink> links) => links
      .map(
        (link) =>
            '${link.from.dx},${link.from.dy}>${link.to.dx},'
            '${link.to.dy}:${link.strength}',
      )
      .join('|');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _pulse.stop();
      _pulse.value = 0;
      if (!_entrance.isAnimating) _entrance.value = 1;
      return;
    }
    if (!_pulse.isAnimating) _pulse.repeat();
    if (!_entrance.isAnimating && _entrance.value == 0) _entrance.forward();
  }

  @override
  void didUpdateWidget(ChemistryLinks oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _signatureOf(widget.links);
    if (next == _signature) return;
    _signature = next;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _entrance.value = 1;
      return;
    }
    _entrance.forward(from: 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _entrance]),
          builder: (context, _) => CustomPaint(
            painter: _ChemistryLinkPainter(
              links: widget.links,
              pulse: .5 + .5 * math.sin(_pulse.value * 2 * math.pi),
              entrance: Curves.easeOutCubic.transform(_entrance.value),
              strong: widget.strongColor,
              weak: widget.weakColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChemistryLinkPainter extends CustomPainter {
  _ChemistryLinkPainter({
    required this.links,
    required this.pulse,
    required this.entrance,
    required this.strong,
    required this.weak,
  });

  final List<ChemistryLink> links;
  final double pulse;
  final double entrance;
  final Color strong;
  final Color weak;

  @override
  void paint(Canvas canvas, Size size) {
    if (entrance <= 0) return;

    for (final link in links) {
      final end = Offset.lerp(link.from, link.to, entrance)!;
      if (link.isStrong) {
        final color = strong.withValues(alpha: .22 + .34 * pulse);
        canvas.drawLine(
          link.from,
          end,
          Paint()
            ..color = color
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          end,
          2.4 + 1.4 * pulse,
          Paint()..color = strong.withValues(alpha: .16 + .28 * pulse),
        );
      } else {
        canvas.drawLine(
          link.from,
          end,
          Paint()
            ..color = weak.withValues(alpha: .12 + .08 * pulse)
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChemistryLinkPainter oldDelegate) =>
      oldDelegate.links != links ||
      oldDelegate.pulse != pulse ||
      oldDelegate.entrance != entrance ||
      oldDelegate.strong != strong ||
      oldDelegate.weak != weak;
}

/// Three diamonds per slot, matching the 0–3 chemistry a single player can
/// earn. Filled diamonds use the theme accent; empty ones stay dim.
class ChemistryDiamonds extends StatelessWidget {
  const ChemistryDiamonds({required this.value, this.size = 5, super.key});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final filled = value.clamp(0, 3);
    return Semantics(
      label: 'شیمی ${faDigits(filled)} از ۳',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : size / 2),
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  key: ValueKey(
                    i < filled ? 'chem-diamond-filled' : 'chem-diamond-empty',
                  ),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: i < filled ? color : color.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
