import 'dart:math' as math;

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

  static const _shieldHeightPerWidth = 1.397;

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

  String _titleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '—';
    final buffer = StringBuffer();
    var upper = true;
    for (final rune in trimmed.runes) {
      final char = String.fromCharCode(rune);
      if (RegExp(r"[\s\-']").hasMatch(char)) {
        buffer.write(char);
        upper = true;
      } else if (upper) {
        buffer.write(char.toUpperCase());
        upper = false;
      } else {
        buffer.write(char.toLowerCase());
      }
    }
    return buffer.toString();
  }

  String _alternatePosition() {
    final primary = player.position.toUpperCase();
    for (final position in player.positions) {
      final candidate = position.toUpperCase();
      if (candidate.isNotEmpty && candidate != primary) return candidate;
    }
    return '';
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
        : [
            player.pace,
            player.shooting,
            player.passing,
            player.dribbling,
            player.defending,
            player.physical,
          ];
    final alternate = _alternatePosition();
    final skills = player.skillMoves > 0 && player.weakFoot > 0
        ? '${player.skillMoves}★${player.weakFoot}'
        : null;
    // EA publishes the complete FC27 item card (rating, position, stats, name,
    // nation, league and club). When that artwork is available it *is* the card,
    // so it is shown as-is instead of being clipped and re-annotated.
    final officialCard =
        player.cardImageUrl.contains('/FC27/components/items/');
    // Hall of FUT items are outside EA's public ratings roster; FUT.GG publishes
    // the same complete item artwork for them, so both render as a full card.
    final fullCardArt = officialCard || player.cardArtUrl.isNotEmpty;
    final artworkUrl = officialCard ? player.cardImageUrl : player.cardArtUrl;
    // EA items are 440x548; FUT.GG item cards are 300x419, which is the same
    // ratio the drawn FCBaz shield uses.
    final artworkHeightPerWidth = officialCard ? 548 / 440 : _shieldHeightPerWidth;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AspectRatio(
        aspectRatio: compact ? .72 : .70,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final double footerHeight = showPrices
                ? (h * .062).clamp(11.0, 19.0).toDouble()
                : 0;
            final double footerGap = showPrices
                ? (h * .014).clamp(2.0, 4.0).toDouble()
                : 0;
            final bodyHeight = h - footerHeight - footerGap;
            // Full-card artwork keeps its own canvas ratio; the drawn fallback
            // uses the FCBaz shield ratio.
            final double heightPerWidth =
                fullCardArt ? artworkHeightPerWidth : _shieldHeightPerWidth;
            final double shieldWidth = math.min(
              w * (fullCardArt ? 1.0 : showPrices ? .96 : .98),
              bodyHeight / heightPerWidth,
            );
            final double shieldHeight = shieldWidth * heightPerWidth;
            final double left = (w - shieldWidth) / 2;
            final double top = showPrices
                ? (fullCardArt ? (bodyHeight - shieldHeight) / 2 : 0.0)
                : (h - shieldHeight) / 2;
            final tagFont = shieldWidth * .05;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: left,
                  top: top,
                  width: shieldWidth,
                  height: shieldHeight,
                  child: fullCardArt
                      ? Image.network(
                          artworkUrl,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) =>
                              _CardBody(
                            player: player,
                            theme: theme,
                            compact: compact,
                            statLabels: statLabels,
                            statValues: statValues,
                            displayName: _titleCase(player.name),
                          ),
                        )
                      : player.cardImageUrl.isNotEmpty
                          ? ClipPath(
                              clipper: FutCardClipper(ornate: theme.ornate),
                              child: Image.network(
                                player.cardImageUrl,
                                fit: BoxFit.fill,
                                errorBuilder: (context, error, stackTrace) =>
                                    _CardBody(
                                  player: player,
                                  theme: theme,
                                  compact: compact,
                                  statLabels: statLabels,
                                  statValues: statValues,
                                  displayName: _titleCase(player.name),
                                ),
                              ),
                            )
                          : _CardBody(
                              player: player,
                              theme: theme,
                              compact: compact,
                              statLabels: statLabels,
                              statValues: statValues,
                              displayName: _titleCase(player.name),
                            ),
                ),
                if (!fullCardArt && alternate.isNotEmpty)
                  Positioned(
                    left: left + shieldWidth * .78,
                    width: shieldWidth * .26,
                    top: top + shieldHeight * .292,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: CardTag(
                        label: alternate,
                        fontSize: tagFont,
                        theme: theme,
                      ),
                    ),
                  ),
                if (!fullCardArt && skills != null)
                  Positioned(
                    left: left + shieldWidth * .78,
                    width: shieldWidth * .26,
                    top: top + shieldHeight * .566,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: CardTag(
                        label: skills,
                        fontSize: tagFont,
                        theme: theme,
                      ),
                    ),
                  ),
                if (!fullCardArt)
                  Positioned(
                    left: left + shieldWidth * .075 - shieldWidth * .068,
                    top: top + shieldHeight * .525,
                    width: shieldWidth * .136,
                    height: shieldWidth * .136,
                    child: RoleDiamond(
                      position: player.position,
                      size: shieldWidth * .136,
                      theme: theme,
                    ),
                  ),
                if (showPrices)
                  Positioned(
                    left: left + shieldWidth * .015,
                    right: left + shieldWidth * .015,
                    bottom: 0,
                    height: footerHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: _Price(
                            label: 'PS',
                            value: _coins(player.pricePs),
                            t: theme,
                          ),
                        ),
                        SizedBox(width: w * .022),
                        Expanded(
                          child: _Price(
                            label: 'PC',
                            value: _coins(player.pricePc),
                            t: theme,
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
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.player,
    required this.theme,
    required this.compact,
    required this.statLabels,
    required this.statValues,
    required this.displayName,
  });

  final Player player;
  final PlayerCardTheme theme;
  final bool compact;
  final List<String> statLabels;
  final List<int> statValues;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        Widget portrait = _PlayerImage(
          url: compact ? player.imageUrl : player.highResImageUrl,
          fallbackUrl: compact ? player.highResImageUrl : player.imageUrl,
          color: theme.ink.withValues(alpha: .22),
          compact: compact,
        );
        if (theme.finish == CardFinish.marble) {
          portrait = ColorFiltered(
            colorFilter: ColorFilter.mode(
              const Color(0xFFB49A6A).withValues(alpha: .45),
              BlendMode.color,
            ),
            child: portrait,
          );
        }

        return PhysicalShape(
          clipper: FutCardClipper(ornate: theme.ornate),
          color: theme.shadow,
          elevation: w * .022,
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
                Positioned.fill(
                  child: CustomPaint(painter: CardSurfacePainter(theme)),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: CardFramePainter(theme)),
                  ),
                ),
                Positioned(
                  top: h * .075,
                  left: w * .105,
                  right: w * .105,
                  height: h * .56,
                  child: portrait,
                ),
                Positioned(
                  top: h * .132,
                  left: w * .185,
                  width: w * .27,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          player.rating > 0 ? '${player.rating}' : '—',
                          maxLines: 1,
                          style: theme.text(
                            w * .158,
                            height: .84,
                            letterSpacing: -w * .004,
                          ),
                        ),
                      ),
                      SizedBox(height: h * .004),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          player.position.isEmpty
                              ? '—'
                              : player.position.toUpperCase(),
                          maxLines: 1,
                          style: theme.text(
                            w * .06,
                            height: 1,
                            letterSpacing: w * .002,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: h * .628,
                  left: 0,
                  right: 0,
                  height: h * .074,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.band,
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: .16),
                          width: .7,
                        ),
                        bottom: BorderSide(
                          color: theme.line.withValues(alpha: .14),
                          width: .7,
                        ),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: w * .12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        displayName,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: theme.text(
                          w * .088,
                          height: 1,
                          letterSpacing: -w * .0015,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: h * .724,
                  left: w * .13,
                  right: w * .13,
                  height: h * .036,
                  child: _StatLabels(
                    labels: statLabels,
                    theme: theme,
                    width: w,
                  ),
                ),
                Positioned(
                  top: h * .762,
                  left: w * .13,
                  right: w * .13,
                  height: h * .066,
                  child: _StatValues(
                    values: statValues,
                    theme: theme,
                    width: w,
                  ),
                ),
                Positioned(
                  top: h * .842,
                  left: 0,
                  right: 0,
                  height: h * .06,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NationBadge(
                        nation: player.nationName,
                        size: w * .062,
                        theme: theme,
                      ),
                      SizedBox(width: w * .022),
                      CrestBadge(
                        label: player.leagueName,
                        size: w * .056,
                        theme: theme,
                      ),
                      SizedBox(width: w * .022),
                      CrestBadge(
                        label: player.clubName,
                        size: w * .062,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatLabels extends StatelessWidget {
  const _StatLabels({
    required this.labels,
    required this.theme,
    required this.width,
  });

  final List<String> labels;
  final PlayerCardTheme theme;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.text(
                    width * .038,
                    alpha: .82,
                    height: 1,
                    letterSpacing: width * .0015,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatValues extends StatelessWidget {
  const _StatValues({
    required this.values,
    required this.theme,
    required this.width,
  });

  final List<int> values;
  final PlayerCardTheme theme;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final value in values)
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value > 0 ? '$value' : '—',
                  maxLines: 1,
                  style: theme.text(width * .078, height: 1),
                ),
              ),
            ),
          ),
      ],
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
        color: const Color(0xFF0B100C).withValues(alpha: .92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: .16),
          width: .7,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            '$value $label',
            maxLines: 1,
            textDirection: TextDirection.ltr,
            style: t
                .text(11, height: 1)
                .copyWith(
                  color: Colors.white.withValues(alpha: .94),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _PlayerImage extends StatelessWidget {
  const _PlayerImage({
    required this.url,
    required this.color,
    required this.compact,
    this.fallbackUrl = '',
  });

  final String url;
  final Color color;
  final bool compact;
  final String fallbackUrl;

  @override
  Widget build(BuildContext context) => _network(url);

  Widget _network(String target, {int depth = 0}) {
    if (target.isEmpty) return _placeholder();
    return Image.network(
      target,
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
      errorBuilder: (_, __, ___) {
        if (depth == 0 && fallbackUrl.isNotEmpty && fallbackUrl != target) {
          return _network(fallbackUrl, depth: 1);
        }
        return _placeholder();
      },
    );
  }

  Widget _placeholder() => Align(
    alignment: Alignment.bottomCenter,
    child: Icon(Icons.person_rounded, size: compact ? 84 : 104, color: color),
  );
}
