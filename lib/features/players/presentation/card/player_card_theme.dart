import 'package:flutter/material.dart';

import '../../domain/player.dart';

@immutable
class PlayerCardTheme {
  const PlayerCardTheme({
    required this.gradient,
    required this.ink,
    required this.accent,
    required this.glow,
    required this.shadow,
  });

  final List<Color> gradient;
  final Color ink;
  final Color accent;
  final Color glow;
  final Color shadow;

  static PlayerCardTheme forPlayer(Player player) =>
      forRarity('${player.version} ${player.rarity} ${player.cardType}');

  static PlayerCardTheme forRarity(String rarity) {
    final raw = rarity.toLowerCase();
    if (raw.contains('icon')) return icon;
    if (raw.contains('hero')) return hero;
    if (raw.contains('team of the week') || raw.contains('totw')) return totw;
    if (raw.contains('hall of fut') || raw.contains('hall')) return hallOfFut;
    if (raw.contains('holographic') || raw.contains('pristine') || raw.contains('holo')) {
      return holographic;
    }
    if (raw.contains('gold')) return gold;
    if (raw.contains('silver')) return silver;
    if (raw.contains('bronze')) return bronze;
    return standard;
  }

  static const gold = PlayerCardTheme(
    gradient: [Color(0xFFFFEF9F), Color(0xFFF3CF4E), Color(0xFFB98A1E)],
    ink: Color(0xFF2B2106),
    accent: Color(0xFF8A6A1E),
    glow: Color(0xFFFFD966),
    shadow: Color(0xFF7A5E18),
  );

  static const silver = PlayerCardTheme(
    gradient: [Color(0xFFF8FBFC), Color(0xFFCBD5D8), Color(0xFF8D999D)],
    ink: Color(0xFF131A1C),
    accent: Color(0xFF5C6B6F),
    glow: Color(0xFFE8F2F4),
    shadow: Color(0xFF6E7B7F),
  );

  static const bronze = PlayerCardTheme(
    gradient: [Color(0xFFF0C39B), Color(0xFFC98B5B), Color(0xFF8A5633)],
    ink: Color(0xFF241207),
    accent: Color(0xFF6B3D22),
    glow: Color(0xFFF0B080),
    shadow: Color(0xFF5E3620),
  );

  static const icon = PlayerCardTheme(
    gradient: [Color(0xFFFFF8E1), Color(0xFFF0DCA8), Color(0xFFC9A85C)],
    ink: Color(0xFF2B2210),
    accent: Color(0xFF9A7428),
    glow: Color(0xFFF5DE9A),
    shadow: Color(0xFF8A6A2A),
  );

  static const hero = PlayerCardTheme(
    gradient: [Color(0xFF2B0F3F), Color(0xFF6C1A4F), Color(0xFFD3492A)],
    ink: Color(0xFFFFF3E6),
    accent: Color(0xFFFFC757),
    glow: Color(0xFFFF7A45),
    shadow: Color(0xFF14061F),
  );

  static const totw = PlayerCardTheme(
    gradient: [Color(0xFF0A0A0A), Color(0xFF17160F), Color(0xFF3E3718)],
    ink: Color(0xFFF5E9A5),
    accent: Color(0xFFE6CE62),
    glow: Color(0xFFC7B24E),
    shadow: Color(0xFF000000),
  );

  static const hallOfFut = PlayerCardTheme(
    gradient: [Color(0xFF04222B), Color(0xFF075E63), Color(0xFF17A394)],
    ink: Color(0xFFECFFFB),
    accent: Color(0xFF8CFFF1),
    glow: Color(0xFF52F2D8),
    shadow: Color(0xFF032027),
  );

  static const holographic = PlayerCardTheme(
    gradient: [Color(0xFF17224D), Color(0xFF6F3F97), Color(0xFF1FAF9C)],
    ink: Colors.white,
    accent: Color(0xFF9BFFED),
    glow: Color(0xFF7CFFE9),
    shadow: Color(0xFF120D33),
  );

  static const standard = PlayerCardTheme(
    gradient: [Color(0xFF11170F), Color(0xFF1C4A28), Color(0xFF2A8B49)],
    ink: Color(0xFFF4FFE8),
    accent: Color(0xFFC8FF42),
    glow: Color(0xFFC8FF42),
    shadow: Color(0xFF08110B),
  );

  TextStyle text(
    double size, {
    double alpha = 1,
    double letterSpacing = 0,
    double height = .95,
  }) =>
      TextStyle(
        fontFamily: 'BarlowCondensed',
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w800,
        fontSize: size,
        height: height,
        letterSpacing: letterSpacing,
        color: ink.withValues(alpha: alpha),
      );
}
