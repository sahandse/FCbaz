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
    return _BadgeShell(
      size: size,
      theme: theme,
      child: flag != null
          ? Text(flag, textDirection: TextDirection.ltr, style: TextStyle(fontSize: size * .6, height: 1))
          : Icon(Icons.public_rounded, size: size * .58, color: theme.ink.withValues(alpha: .75)),
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
    return _BadgeShell(
      size: size,
      theme: theme,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(size * .12),
          child: Text(
            _initials(label),
            maxLines: 1,
            textDirection: TextDirection.ltr,
            style: theme.text(size * .48, alpha: .9, letterSpacing: 0, height: 1),
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final words = value.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    String take(String source, int count) => String.fromCharCodes(source.runes.take(count)).toUpperCase();
    if (words.length == 1) return take(words.first, 2);
    return take(words.first, 1) + take(words[1], 1);
  }
}

class _BadgeShell extends StatelessWidget {
  const _BadgeShell({required this.size, required this.theme, required this.child});

  final double size;
  final PlayerCardTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.shadow.withValues(alpha: .22),
        border: Border.all(color: Colors.white.withValues(alpha: .32), width: .8),
        boxShadow: [
          BoxShadow(
            color: theme.shadow.withValues(alpha: .28),
            blurRadius: size * .18,
            offset: Offset(0, size * .06),
          ),
        ],
      ),
      child: child,
    );
  }
}
