import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../src/theme/fcbaz_theme.dart';
import '../../../src/utils/persian_formatters.dart';
import '../../market/data/watchlist_repository.dart';
import '../domain/player.dart';
import 'player_item_visual.dart';
import 'package:fcbaz/src/app_dependencies.dart';
import 'package:fcbaz/src/navigation/app_navigator.dart';

class PlayerMarketTile extends StatefulWidget {
  const PlayerMarketTile({
    required this.player,
    this.pricePlatform = 'console',
    this.heroTag,
    super.key,
  });

  final Player player;
  final String pricePlatform;

  /// Optional shared-element tag. Only the primary collection grid sets it so
  /// a player that also appears in a discovery row never registers two heroes.
  final String? heroTag;

  @override
  State<PlayerMarketTile> createState() => _PlayerMarketTileState();
}

class _PlayerMarketTileState extends State<PlayerMarketTile> {
  final history = AppDependencies.instance.history;
  final watchlist = AppDependencies.instance.watchlist;
  bool favorite = false;
  bool watchlisted = false;

  Player get player => widget.player;

  String get platform =>
      widget.pricePlatform.toLowerCase() == 'pc' ? 'pc' : 'console';

  int get price => platform == 'pc' ? player.pricePc : player.pricePs;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
    _loadWatchlist();
  }

  Future<void> _loadFavorite() async {
    try {
      final value = await history.isFavorite(player.id);
      if (!mounted) return;
      setState(() => favorite = value);
    } catch (_) {
      // Favorites are a local convenience and must not block the tile.
    }
  }

  Future<void> _toggleFavorite() async {
    unawaited(HapticFeedback.selectionClick());
    try {
      await history.toggleFavorite(player);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() => favorite = !favorite);
  }

  Future<void> _loadWatchlist() async {
    try {
      final value = await watchlist.contains(player.id);
      if (!mounted) return;
      setState(() => watchlisted = value);
    } catch (_) {
      // The watchlist is local; a read failure must not block the tile.
    }
  }

  Future<void> _toggleWatchlist() async {
    unawaited(HapticFeedback.selectionClick());
    final wasWatched = watchlisted;
    try {
      await watchlist.toggle(
        WatchlistItem(
          playerId: player.id,
          playerName: player.name,
          platform: platform,
        ),
      );
      if (!wasWatched && price > 0) {
        await watchlist.recordPrice(
          player.id,
          price: price,
          platform: platform,
        );
      }
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() => watchlisted = !wasWatched);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          watchlisted
              ? 'به دیده‌بان بازار اضافه شد؛ هشدار قیمت را از بخش بازار تنظیم کن.'
              : 'از دیده‌بان بازار حذف شد.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openCompare() {
    unawaited(HapticFeedback.selectionClick());
    AppNavigator.compare(context, player);
  }

  void _openDetails() {
    AppNavigator.playerDetails(context, player);
  }

  Widget _tileVisual() {
    final visual = PlayerItemVisual(
      player: player,
      showPrices: false,
      compact: true,
    );
    final tag = widget.heroTag;
    if (tag == null) return visual;
    return Hero(tag: tag, child: visual);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final goalkeeping = player.position.toUpperCase() == 'GK';
    final labels = goalkeeping
        ? const ['DIV', 'HAN', 'KIC', 'REF', 'SPD', 'POS']
        : const ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY'];
    final values = goalkeeping
        ? [for (final label in labels) player.inGameStats[label] ?? 0]
        : [
            player.pace,
            player.shooting,
            player.passing,
            player.dribbling,
            player.defending,
            player.physical,
          ];
    final clubLeague = [
      player.clubName.trim(),
      player.leagueName.trim(),
    ].where((part) => part.isNotEmpty).join(' · ');
    final priceLabel = formatCoinsFa(price);

    return Semantics(
      button: true,
      label:
          '${player.name}،${player.rating}،${player.position}'
          '${price > 0 ? '، قیمت ${faDigits(price)} سکه' : ''}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openDetails,
        child: Container(
          key: const ValueKey('player-market-tile-surface'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.surfaceRaised, palette.surface],
            ),
            borderRadius: BorderRadius.circular(FcbazRadius.lg),
            border: Border.all(color: palette.line.withValues(alpha: .9)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final statValueSize = (w * .105).clamp(13.0, 21.0).toDouble();
              final statLabelSize = (w * .055).clamp(8.0, 10.5).toDouble();
              final clubSize = (w * .06).clamp(8.5, 12.0).toDouble();
              final captionSize = (w * .058).clamp(8.5, 10.5).toDouble();
              final priceSize = (w * .12).clamp(16.0, 26.0).toDouble();
              final actionSize = (w * .17).clamp(24.0, 32.0).toDouble();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        w * .035,
                        w * .045,
                        w * .035,
                        0,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(child: _tileVisual()),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Row(
                              textDirection: TextDirection.ltr,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _TileAction(
                                  size: actionSize,
                                  icon: Icons.compare_arrows_rounded,
                                  semanticLabel: 'مقایسه ${player.name}',
                                  onTap: _openCompare,
                                ),
                                SizedBox(width: actionSize * .22),
                                _TileAction(
                                  size: actionSize,
                                  icon: watchlisted
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_outlined,
                                  active: watchlisted,
                                  activeColor: palette.primary,
                                  semanticLabel: watchlisted
                                      ? 'حذف از دیده‌بان بازار'
                                      : 'افزودن به دیده‌بان بازار',
                                  onTap: _toggleWatchlist,
                                ),
                                SizedBox(width: actionSize * .22),
                                _TileAction(
                                  size: actionSize,
                                  icon: favorite
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  active: favorite,
                                  semanticLabel: favorite
                                      ? 'حذف از علاقه‌مندی‌ها'
                                      : 'افزودن به علاقه‌مندی‌ها',
                                  onTap: _toggleFavorite,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: .8,
                    color: palette.line.withValues(alpha: .75),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * .035,
                      vertical: w * .045,
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        children: [
                          for (var i = 0; i < labels.length; i++)
                            Expanded(
                              child: _Stat(
                                label: labels[i],
                                value: values[i],
                                valueSize: statValueSize,
                                labelSize: statLabelSize,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: .8,
                    color: palette.line.withValues(alpha: .75),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: w * .065,
                      vertical: w * .05,
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              clubLeague.isEmpty
                                  ? 'باشگاه / لیگ نامشخص'
                                  : clubLeague,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.textMuted,
                                fontSize: clubSize,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                          SizedBox(width: w * .03),
                          Icon(
                            Icons.sports_soccer_rounded,
                            size: clubSize * 1.4,
                            color: palette.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(w * .06, 0, w * .06, w * .065),
                    child: Column(
                      children: [
                        Text(
                          price > 0
                              ? 'قیمت ثبت‌شده برای نسخه کارت و پلتفرم انتخاب‌شده'
                              : 'قیمت معتبری برای این نسخه ثبت نشده است',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textMuted.withValues(alpha: .88),
                            fontSize: captionSize,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: w * .02),
                        if (price > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  priceLabel,
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    color: palette.primary,
                                    fontSize: priceSize,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                    letterSpacing: .3,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'سکه',
                                  style: TextStyle(
                                    color: palette.primary,
                                    fontSize: priceSize * .58,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            '—',
                            style: TextStyle(
                              color: palette.textMuted,
                              fontSize: priceSize,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.valueSize,
    required this.labelSize,
  });

  final String label;
  final int value;
  final double valueSize;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Color color;
    if (value <= 0) {
      color = palette.textMuted;
    } else if (value >= 80) {
      color = palette.success;
    } else if (value >= 65) {
      color = palette.warning;
    } else {
      color = palette.danger;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value > 0 ? faDigits(value) : '—',
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontSize: valueSize,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: .2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        SizedBox(height: valueSize * .1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: labelSize,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: .5,
            ),
          ),
        ),
      ],
    );
  }
}

class _TileAction extends StatelessWidget {
  const _TileAction({
    required this.size,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  final double size;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size * .3),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFF050806).withValues(alpha: .72),
              borderRadius: BorderRadius.circular(size * .3),
              border: Border.all(color: Colors.white.withValues(alpha: .16)),
            ),
            child: Icon(
              icon,
              size: size * .6,
              color: active
                  ? (activeColor ?? palette.warning)
                  : Colors.white.withValues(alpha: .92),
            ),
          ),
        ),
      ),
    );
  }
}
