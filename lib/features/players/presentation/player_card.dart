import 'package:flutter/material.dart';

import '../domain/player.dart';
import 'player_details_screen.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    required this.player,
    this.pricePlatform = 'console',
    super.key,
  });

  final Player player;
  final String pricePlatform;

  int get selectedPrice =>
      pricePlatform == 'pc' ? player.pricePc : player.pricePs;

  String _coins(int value) {
    if (value <= 0) return '—';
    if (value >= 1000000) {
      final n = value / 1000000;
      return n.toStringAsFixed(n >= 10 ? 0 : 1) + 'M';
    }
    if (value >= 1000) {
      final n = value / 1000;
      return n.toStringAsFixed(n >= 100 ? 0 : 1) + 'K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tags = <String>[
      if (player.version.isNotEmpty) player.version,
      if (player.rarity.isNotEmpty &&
          player.rarity.toLowerCase() != player.version.toLowerCase())
        player.rarity,
      if (player.cardType.isNotEmpty &&
          player.cardType.toLowerCase() != player.version.toLowerCase() &&
          player.cardType.toLowerCase() != player.rarity.toLowerCase())
        player.cardType,
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerDetailsScreen(player: player),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: scheme.primary.withValues(alpha: .10),
                ),
                alignment: Alignment.center,
                child: player.imageUrl.isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: scheme.primary,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.network(
                          player.imageUrl,
                          fit: BoxFit.cover,
                          width: 70,
                          height: 88,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            size: 36,
                            color: scheme.primary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          constraints: const BoxConstraints(minWidth: 42),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            player.rating.toString(),
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            player.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (selectedPrice > 0) ...[
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _coins(selectedPrice),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                pricePlatform == 'pc' ? 'PC' : 'Console',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        player.position,
                        player.clubName,
                      ].where((e) => e.isNotEmpty).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 24,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final tag in tags.take(3)) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  tag,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Stat('PAC', player.pace),
                        _Stat('SHO', player.shooting),
                        _Stat('PAS', player.passing),
                        _Stat('DRI', player.dribbling),
                        _Stat('DEF', player.defending),
                        _Stat('PHY', player.physical),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                ),
          ),
        ],
      ),
    );
  }
}
