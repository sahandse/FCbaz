part of '../squad_screen.dart';

class _Pitch extends StatelessWidget {
  const _Pitch({
    required this.formation,
    required this.playersBySlot,
    required this.playerConfigs,
    required this.chemistryBySlot,
    required this.onTapEmptySlot,
    required this.onConfigurePlayer,
    required this.onRemovePlayer,
  });

  final FormationDefinition formation;
  final Map<String, Player> playersBySlot;
  final Map<String, SquadPlayerConfig> playerConfigs;
  final Map<String, int> chemistryBySlot;
  final ValueChanged<FormationSlot> onTapEmptySlot;
  final void Function(FormationSlot slot, Player player) onConfigurePlayer;
  final ValueChanged<String> onRemovePlayer;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AspectRatio(
      aspectRatio: .72,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = (constraints.maxWidth * .175).clamp(56.0, 72.0);
          final slotHeight = slotWidth * 1.28;
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primary.withValues(alpha: .28)),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF102A18),
                  Color(0xFF07150D),
                  Color(0xFF030806),
                ],
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: _PitchLines()),
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .28),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      'FC27 • ${formation.name}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                for (final slot in formation.slots)
                  Positioned(
                    left: (constraints.maxWidth * slot.x - slotWidth / 2).clamp(
                      5.0,
                      constraints.maxWidth - slotWidth - 5,
                    ),
                    top: (constraints.maxHeight * slot.y - slotHeight / 2)
                        .clamp(24.0, constraints.maxHeight - slotHeight - 7),
                    width: slotWidth,
                    height: slotHeight,
                    child: _SlotCard(
                      slot: slot,
                      player: playersBySlot[slot.id],
                      chemistry: chemistryBySlot[slot.id] ?? 0,
                      config: playerConfigs[slot.id],
                      onTap: () {
                        final player = playersBySlot[slot.id];
                        if (player == null) {
                          onTapEmptySlot(slot);
                        } else {
                          onConfigurePlayer(slot, player);
                        }
                      },
                      onRemove: () => onRemovePlayer(slot.id),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PitchLines extends StatelessWidget {
  const _PitchLines();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _PitchPainter());
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stripe = Paint()..color = Colors.white.withValues(alpha: .018);
    final stripeHeight = size.height / 10;
    for (var i = 0; i < 10; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        stripe,
      );
    }
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;
    final rect = Rect.fromLTWH(13, 13, size.width - 26, size.height - 26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      paint,
    );
    canvas.drawLine(
      Offset(13, size.height / 2),
      Offset(size.width - 13, size.height / 2),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * .12,
      paint,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2.2, paint);
    final boxW = size.width * .55;
    final boxH = size.height * .16;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, 13),
        width: boxW,
        height: boxH,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 13),
        width: boxW,
        height: boxH,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
