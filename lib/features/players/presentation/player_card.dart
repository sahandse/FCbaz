import 'package:flutter/material.dart';

import '../../search/search_history_repository.dart';
import '../domain/player.dart';
import 'player_details_screen.dart';

class PlayerCard extends StatefulWidget {
  const PlayerCard({
    required this.player,
    this.pricePlatform = 'console',
    super.key,
  });

  final Player player;
  final String pricePlatform;

  @override
  State<PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<PlayerCard> {
  final history = SearchHistoryRepository();
  bool favorite = false;

  Player get player => widget.player;
  int get selectedPrice =>
      widget.pricePlatform == 'pc' ? player.pricePc : player.pricePs;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final value = await history.isFavorite(player.id);
    if (!mounted) return;
    setState(() => favorite = value);
  }

  Future<void> _toggleFavorite() async {
    await history.toggleFavorite(player);
    if (!mounted) return;
    setState(() => favorite = !favorite);
  }

  String _coins(int value) {
    if (value <= 0) return '—';
    if (value >= 1000000) {
      final n = value / 1000000;
      return '${n.toStringAsFixed(n >= 10 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final n = value / 1000;
      return '${n.toStringAsFixed(n >= 100 ? 0 : 1)}K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final secondary = [
      player.clubName,
      player.leagueName,
    ].where((e) => e.isNotEmpty).join(' • ');
    final version = player.version.isNotEmpty
        ? player.version
        : (player.rarity.isNotEmpty ? player.rarity : player.cardType);

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerDetailsScreen(player: player),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outline.withValues(alpha: .52)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 92,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              scheme.primary.withValues(alpha: .18),
                              scheme.surfaceContainerHighest.withValues(alpha: .55),
                            ],
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: player.imageUrl.isEmpty
                            ? Icon(Icons.person_rounded, size: 48, color: scheme.primary)
                            : Image.network(
                                player.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  size: 48,
                                  color: scheme.primary,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: .92),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '${player.rating}',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: .9),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          player.position,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
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
                        ),
                        IconButton(
                          onPressed: _toggleFavorite,
                          visualDensity: VisualDensity.compact,
                          tooltip: favorite
                              ? 'حذف از علاقه‌مندی‌ها'
                              : 'افزودن به علاقه‌مندی‌ها',
                          icon: Icon(
                            favorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: favorite ? Colors.redAccent : scheme.onSurfaceVariant,
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                    if (secondary.isNotEmpty)
                      Text(
                        secondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        if (version.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                version,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _coins(selectedPrice),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                color: selectedPrice > 0 ? scheme.primary : scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              widget.pricePlatform == 'pc' ? 'PC' : 'Console',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value > 0 ? '$value' : '—',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
          ),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
