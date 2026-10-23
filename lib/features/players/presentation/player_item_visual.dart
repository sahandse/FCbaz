import 'package:flutter/material.dart';

import '../domain/player.dart';
import 'card/player_card_badges.dart';
import 'card/player_card_painters.dart';
import 'card/player_card_theme.dart';

class PlayerItemVisual extends StatelessWidget {
  const PlayerItemVisual({
    required this.player,
    this.showPrices = true,
    this.compact = false,
    super.key,
  });

  final Player player;
  final bool showPrices;
  final bool compact;

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
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final theme = PlayerCardTheme.forPlayer(player);
    final goalkeeping = player.position.toUpperCase() == 'GK';
    final statLabels = goalkeeping
        ? const ['DIV', 'HAN', 'KIC', 'REF', 'SPD', 'POS']
        : const ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY'];
    final statValues = goalkeeping
        ? [for (final label in statLabels) player.inGameStats[label] ?? 0]
        : [player.pace, player.shooting, player.passing, player.dribbling, player.defending, player.physical];
    final version = player.version.isNotEmpty
        ? player.version
        : (player.rarity.isNotEmpty ? player.rarity : player.cardType);

    return AspectRatio(
      aspectRatio: compact ? .72 : .70,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final badge = w * (compact ? .115 : .105);

          return PhysicalShape(
            clipper: const FutCardClipper(),
            color: theme.shadow,
            elevation: w * .02,
            shadowColor: theme.shadow.withValues(alpha: .55),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: theme.gradient,
                  stops: const [0, .55, 1],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(child: CustomPaint(painter: CardSurfacePainter(theme))),
                  Positioned.fill(
                    child: IgnorePointer(child: CustomPaint(painter: CardFramePainter(theme))),
                  ),
                  Positioned(
                    top: h * .112,
                    left: w * .185,
                    right: w * .015,
                    bottom: h * (showPrices ? .40 : .375),
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(.1, .35),
                            radius: .8,
                            colors: [
                              Colors.white.withValues(alpha: .22),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: h * .112,
                    left: w * .185,
                    right: w * .015,
                    bottom: h * (showPrices ? .40 : .375),
                    child: _PlayerImage(
                      url: player.imageUrl,
                      color: theme.ink.withValues(alpha: .22),
                      compact: compact,
                    ),
                  ),
                  Positioned(
                    top: h * .03,
                    left: w * .055,
                    width: w * .26,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            player.rating > 0 ? '${player.rating}' : '—',
                            style: theme.text(w * .215, height: .78, letterSpacing: -w * .004),
                          ),
                        ),
                        SizedBox(height: h * .005),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            player.position.isEmpty ? '—' : player.position.toUpperCase(),
                            textDirection: TextDirection.ltr,
                            style: theme.text(w * .058, alpha: .88, letterSpacing: w * .002),
                          ),
                        ),
                        if (player.playStylesPlus.isNotEmpty) ...[
                          SizedBox(height: h * .008),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: w * .025, vertical: h * .006),
                            decoration: BoxDecoration(
                              color: theme.shadow.withValues(alpha: .26),
                              borderRadius: BorderRadius.circular(w * .022),
                              border: Border.all(color: theme.accent.withValues(alpha: .8), width: .9),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: w * .042, color: theme.accent),
                                Text('${player.playStylesPlus.length}+', style: theme.text(w * .038, height: 1)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: h * (compact ? .19 : .058),
                    right: w * .05,
                    child: Column(
                      children: [
                        NationBadge(nation: player.nationName, size: badge, theme: theme),
                        SizedBox(height: w * .018),
                        CrestBadge(label: player.leagueName, size: badge, theme: theme),
                        SizedBox(height: w * .018),
                        CrestBadge(label: player.clubName, size: badge, theme: theme),
                      ],
                    ),
                  ),
                  Positioned(
                    top: h * (showPrices ? .612 : .625),
                    left: w * .065,
                    right: w * .065,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: h * .05,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              player.name.toUpperCase(),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.ltr,
                              style: theme.text(w * .092, letterSpacing: w * .0012),
                            ),
                          ),
                        ),
                        SizedBox(height: h * .008),
                        Container(width: w * .5, height: .9, color: theme.ink.withValues(alpha: .3)),
                      ],
                    ),
                  ),
                  Positioned(
                    top: h * .699,
                    left: w * .045,
                    right: w * .045,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatRow(labels: statLabels, values: statValues, start: 0, theme: theme, width: w),
                        SizedBox(height: h * .016),
                        _StatRow(labels: statLabels, values: statValues, start: 3, theme: theme, width: w),
                      ],
                    ),
                  ),
                  if (version.isNotEmpty)
                    Positioned(
                      top: h * (showPrices ? .845 : .872),
                      left: w * .1,
                      right: w * .1,
                      child: Text(
                        version.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: theme.text(w * .042, alpha: .68, letterSpacing: w * .006, height: 1),
                      ),
                    ),
                  if (showPrices)
                    Positioned(
                      left: w * .06,
                      right: w * .06,
                      bottom: h * .022,
                      height: h * .052,
                      child: Row(
                        children: [
                          Expanded(child: _Price(label: 'PS', value: _coins(player.pricePs), t: theme)),
                          SizedBox(width: w * .025),
                          Expanded(child: _Price(label: 'PC', value: _coins(player.pricePc), t: theme)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.labels,
    required this.values,
    required this.start,
    required this.theme,
    required this.width,
  });

  final List<String> labels;
  final List<int> values;
  final int start;
  final PlayerCardTheme theme;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: width * .072,
      child: Row(
        children: [
          for (var i = start; i < start + 3; i++)
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(values[i] > 0 ? '${values[i]}' : '—', style: theme.text(width * .062, height: .9)),
                    SizedBox(width: width * .012),
                    Text(labels[i], style: theme.text(width * .038, alpha: .58, height: .9, letterSpacing: width * .002)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.label, required this.value, required this.t});

  final String label;
  final String value;
  final PlayerCardTheme t;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.shadow.withValues(alpha: .24),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withValues(alpha: .18), width: .7),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            '$value $label',
            maxLines: 1,
            textDirection: TextDirection.ltr,
            style: t.text(11, height: 1),
          ),
        ),
      ),
    );
  }
}

class _PlayerImage extends StatelessWidget {
  const _PlayerImage({required this.url, required this.color, required this.compact});

  final String url;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return Image.network(
      url,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.medium,
      cacheWidth: compact ? 260 : 360,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Align(
        alignment: Alignment.bottomCenter,
        child: Icon(Icons.person_rounded, size: compact ? 84 : 104, color: color),
      );
}
