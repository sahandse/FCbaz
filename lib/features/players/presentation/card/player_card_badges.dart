import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'nation_flags.dart';
import 'player_card_theme.dart';

class NationBadge extends StatelessWidget {
  const NationBadge({
    required this.nation,
    required this.size,
    required this.theme,
    super.key,
  });

  final String nation;
  final double size;
  final PlayerCardTheme theme;

  @override
  Widget build(BuildContext context) {
    final flag = nationFlagEmoji(nation);
    return Container(
      width: size * 1.5,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(size * .12),
        border: Border.all(
          color: Colors.white.withValues(alpha: .4),
          width: .8,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadow.withValues(alpha: .35),
            blurRadius: size * .18,
            offset: Offset(0, size * .06),
          ),
        ],
      ),
      child: flag != null
          ? FittedBox(
              fit: BoxFit.contain,
              child: Text(
                flag,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: size * .92, height: 1),
              ),
            )
          : Icon(
              Icons.public_rounded,
              size: size * .62,
              color: theme.ink.withValues(alpha: .75),
            ),
    );
  }
}

class CrestBadge extends StatelessWidget {
  const CrestBadge({
    required this.label,
    required this.size,
    required this.theme,
    super.key,
  });

  final String label;
  final double size;
  final PlayerCardTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .9),
        border: Border.all(
          color: theme.frame[1].withValues(alpha: .7),
          width: .9,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadow.withValues(alpha: .32),
            blurRadius: size * .18,
            offset: Offset(0, size * .05),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(size * .18),
          child: Text(
            _initials(label),
            maxLines: 1,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w800,
              fontSize: size * .46,
              height: 1,
              color: const Color(0xFF232323).withValues(alpha: .92),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    String take(String source, int count) =>
        String.fromCharCodes(source.runes.take(count)).toUpperCase();
    if (words.length == 1) return take(words.first, 2);
    return take(words.first, 1) + take(words[1], 1);
  }
}

class CardTag extends StatelessWidget {
  const CardTag({
    required this.label,
    required this.fontSize,
    required this.theme,
    super.key,
  });

  final String label;
  final double fontSize;
  final PlayerCardTheme theme;

  @override
  Widget build(BuildContext context) {
    final fill = theme.tagFill.withValues(alpha: .94);
    final foreground = fill.computeLuminance() > .55
        ? const Color(0xFF2A220F)
        : Colors.white;
    return Container(
      height: fontSize * 1.58,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: fontSize * .5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(fontSize * .34),
        border: Border.all(
          color: theme.line.withValues(alpha: .9),
          width: math.max(1.0, fontSize * .085),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadow.withValues(alpha: .35),
            blurRadius: fontSize * .3,
            offset: Offset(0, fontSize * .1),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          textDirection: TextDirection.ltr,
          style: theme
              .text(fontSize, height: 1, letterSpacing: fontSize * .02)
              .copyWith(color: foreground),
        ),
      ),
    );
  }
}

class RoleDiamond extends StatelessWidget {
  const RoleDiamond({
    required this.position,
    required this.size,
    required this.theme,
    super.key,
  });

  final String position;
  final double size;
  final PlayerCardTheme theme;

  @override
  Widget build(BuildContext context) {
    final fill = theme.tagFill.withValues(alpha: .95);
    final foreground = fill.computeLuminance() > .55
        ? const Color(0xFF2A220F)
        : Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: size * .7,
            height: size * .7,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(size * .07),
              border: Border.all(
                color: theme.line.withValues(alpha: .92),
                width: math.max(1.0, size * .045),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadow.withValues(alpha: .4),
                  blurRadius: size * .12,
                  offset: Offset(size * .02, size * .05),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Icon(
                _roleIcon(position),
                size: size * .34,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _roleIcon(String position) {
    final p = position.toUpperCase();
    if (p == 'GK') return Icons.back_hand_rounded;
    if (const ['CB', 'LB', 'RB', 'LWB', 'RWB', 'DEF'].contains(p)) {
      return Icons.shield_rounded;
    }
    if (const ['CDM', 'CM', 'CAM', 'LM', 'RM', 'MID'].contains(p)) {
      return Icons.swap_horiz_rounded;
    }
    return Icons.sports_soccer_rounded;
  }
}
