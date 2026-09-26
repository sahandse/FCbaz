import 'package:flutter/material.dart';

import '../../search/search_history_repository.dart';
import '../domain/player.dart';
import 'player_details_screen.dart';
import 'player_item_visual.dart';

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

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${player.name} ${player.rating} ${player.position}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: player)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PlayerItemVisual(
              player: player,
              compact: true,
              showPrices: true,
            ),
            Positioned(
              top: 9,
              right: 9,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleFavorite,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .18),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: .18)),
                    ),
                    child: Icon(
                      favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 17,
                      color: favorite ? const Color(0xFFFF5F72) : Colors.white.withValues(alpha: .92),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
