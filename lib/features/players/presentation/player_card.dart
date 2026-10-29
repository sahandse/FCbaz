import 'package:flutter/material.dart';

import '../domain/player.dart';
import 'player_item_visual.dart';
import 'package:fcbaz/src/app_dependencies.dart';
import 'package:fcbaz/src/navigation/app_navigator.dart';

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
  final history = AppDependencies.instance.history;
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
        onTap: () => AppNavigator.playerDetails(context, player),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heart = (constraints.maxWidth * .18).clamp(22.0, 32.0);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                PlayerItemVisual(
                  player: player,
                  compact: true,
                  showPrices: true,
                ),
                Positioned.fill(
                  child: Align(
                    alignment: const Alignment(.52, -.8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleFavorite,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: heart,
                          height: heart,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .34),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .18),
                            ),
                          ),
                          child: Icon(
                            favorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: heart * .53,
                            color: favorite
                                ? const Color(0xFFFF5F72)
                                : Colors.white.withValues(alpha: .92),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
