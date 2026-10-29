part of '../squad_screen.dart';

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.player,
    required this.chemistry,
    required this.config,
    required this.onTap,
    required this.onRemove,
  });

  final FormationSlot slot;
  final Player? player;
  final int chemistry;
  final SquadPlayerConfig? config;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final filled = player != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: filled ? onRemove : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
          decoration: BoxDecoration(
            color: filled ? const Color(0xED0A100C) : const Color(0xB30B100D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled
                  ? primary.withValues(alpha: .62)
                  : Colors.white.withValues(alpha: .20),
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                color: Color(0x44000000),
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: filled ? _filled(primary) : _empty(),
        ),
      ),
    );
  }

  Widget _empty() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.add_rounded, color: Colors.white70, size: 20),
      const SizedBox(height: 3),
      Text(
        slot.position,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );

  Widget _filled(Color primary) => Column(
    children: [
      Row(
        children: [
          Text(
            player!.rating > 0 ? '${player!.rating}' : '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            player!.position,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      Expanded(
        child: player!.imageUrl.isEmpty
            ? const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white54,
                  size: 28,
                ),
              )
            : Image.network(
                player!.imageUrl,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white54,
                    size: 28,
                  ),
                ),
              ),
      ),
      SizedBox(
        height: 12,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            player!.name,
            maxLines: 1,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
      if (config != null &&
          (config!.role.isNotEmpty || config!.chemistryStyle != 'Basic'))
        Text(
          [
            if (config!.role.isNotEmpty) config!.role,
            if (config!.chemistryStyle != 'Basic') config!.chemistryStyle,
          ].join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
          style: const TextStyle(color: Colors.white54, fontSize: 5.5),
        ),
      const SizedBox(height: 2),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (i) => Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < chemistry ? primary : Colors.white24,
            ),
          ),
        ),
      ),
    ],
  );
}
