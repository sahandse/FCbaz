import 'package:flutter/material.dart';

import '../../domain/player.dart';

enum CardFinish { satin, marble, holo }

@immutable
class PlayerCardTheme {
  const PlayerCardTheme({
    required this.gradient,
    required this.ink,
    required this.accent,
    required this.glow,
    required this.shadow,
    required this.frame,
    required this.band,
    required this.line,
    this.finish = CardFinish.satin,
    this.ornate = false,
    this.shine = false,
  });

  final List<Color> gradient;
  final Color ink;
  final Color accent;
  final Color glow;
  final Color shadow;
  final List<Color> frame;
  final Color band;
  final Color line;
  final CardFinish finish;
  final bool ornate;

  /// Premium finishes get an animated specular sweep on top of the card.
  final bool shine;

  static PlayerCardTheme forPlayer(Player player) =>
      forRarity('${player.version} ${player.rarity} ${player.cardType}');

  static PlayerCardTheme forRarity(String rarity) {
    final raw = rarity.toLowerCase();
    if (raw.contains('icon')) return icon;
    if (raw.contains('hero')) return hero;
    if (raw.contains('team of the week') || raw.contains('totw')) return totw;
    if (raw.contains('hall of fut')) return hallOfFut;
    if (raw.contains('holographic') ||
        raw.contains('pristine') ||
        raw.contains('holo')) {
      return holographic;
    }
    if (raw.contains('gold')) return gold;
    if (raw.contains('silver')) return silver;
    if (raw.contains('bronze')) return bronze;
    return standard;
  }

  static const gold = PlayerCardTheme(
    gradient: [Color(0xFFF9E079), Color(0xFFE7C145), Color(0xFFBD8E20)],
    ink: Color(0xFF3B2A07),
    accent: Color(0xFF7C5B12),
    glow: Color(0xFFFFE58A),
    shadow: Color(0xFF7A5C13),
    frame: [
      Color(0xFF5B3E08),
      Color(0xFFFFF3B8),
      Color(0xFFC9972A),
      Color(0xFF7E5A10),
    ],
    band: Color(0x24FFFFFF),
    line: Color(0xFF4D3607),
  );

  static const silver = PlayerCardTheme(
    gradient: [Color(0xFFFBFEFF), Color(0xFFDCE7EA), Color(0xFFB4C3C8)],
    ink: Color(0xFF1B262B),
    accent: Color(0xFF5B6E75),
    glow: Color(0xFFF1FBFD),
    shadow: Color(0xFF6E7E84),
    frame: [
      Color(0xFF53656B),
      Color(0xFFFFFFFF),
      Color(0xFFA9BAC0),
      Color(0xFF73858B),
    ],
    band: Color(0x24FFFFFF),
    line: Color(0xFF3E5056),
  );

  static const bronze = PlayerCardTheme(
    gradient: [Color(0xFFF6CFA9), Color(0xFFDFA36D), Color(0xFFB77443)],
    ink: Color(0xFF33200F),
    accent: Color(0xFF6E4425),
    glow: Color(0xFFFFD2A8),
    shadow: Color(0xFF6B3D20),
    frame: [
      Color(0xFF5D3518),
      Color(0xFFFFE3C0),
      Color(0xFFBE814C),
      Color(0xFF7E4A25),
    ],
    band: Color(0x22FFFFFF),
    line: Color(0xFF43260F),
  );

  static const icon = PlayerCardTheme(
    gradient: [Color(0xFFFFFFFF), Color(0xFFFBF4E3), Color(0xFFEFE0C2)],
    ink: Color(0xFF3A2B0D),
    accent: Color(0xFF9A7720),
    glow: Color(0xFFFFF0BE),
    shadow: Color(0xFF8A6A2A),
    frame: [
      Color(0xFF5A3D08),
      Color(0xFFFFF6C2),
      Color(0xFFC79A34),
      Color(0xFF7A5612),
    ],
    band: Color(0x33FFFFFF),
    line: Color(0xFF5A3F0A),
    finish: CardFinish.marble,
    ornate: true,
    shine: true,
  );

  static const hero = PlayerCardTheme(
    gradient: [Color(0xFF2B0F3F), Color(0xFF6C1A4F), Color(0xFFD3492A)],
    ink: Color(0xFFFFF3E6),
    accent: Color(0xFFFFC757),
    glow: Color(0xFFFF7A45),
    shadow: Color(0xFF14061F),
    frame: [
      Color(0xFF3D1224),
      Color(0xFFFFD98A),
      Color(0xFFB4472E),
      Color(0xFF6A1A2A),
    ],
    band: Color(0x33000000),
    line: Color(0xFFFFCF7A),
    shine: true,
  );

  static const totw = PlayerCardTheme(
    gradient: [Color(0xFF0B0B0B), Color(0xFF1D1A0E), Color(0xFF4B401A)],
    ink: Color(0xFFF7EEB0),
    accent: Color(0xFFE9D36B),
    glow: Color(0xFFC7B24E),
    shadow: Color(0xFF000000),
    frame: [
      Color(0xFF46390F),
      Color(0xFFFFF3B0),
      Color(0xFF9E8A35),
      Color(0xFF2E2708),
    ],
    band: Color(0x4D000000),
    line: Color(0xFFC9B14A),
    finish: CardFinish.holo,
    shine: true,
  );

  static const hallOfFut = PlayerCardTheme(
    gradient: [Color(0xFF04222B), Color(0xFF0A6C6C), Color(0xFF1CB5A1)],
    ink: Color(0xFFECFFFB),
    accent: Color(0xFF8CFFF1),
    glow: Color(0xFF52F2D8),
    shadow: Color(0xFF032027),
    frame: [
      Color(0xFF0A4C4B),
      Color(0xFFB6FFF3),
      Color(0xFF179185),
      Color(0xFF073B3A),
    ],
    band: Color(0x33000000),
    line: Color(0xFF8CFFF1),
    shine: true,
  );

  static const holographic = PlayerCardTheme(
    gradient: [Color(0xFF1A2350), Color(0xFF6F3F97), Color(0xFF1FAF9C)],
    ink: Colors.white,
    accent: Color(0xFF9BFFED),
    glow: Color(0xFF7CFFE9),
    shadow: Color(0xFF120D33),
    frame: [
      Color(0xFF4B3A86),
      Color(0xFFB6A5FF),
      Color(0xFF5DF2D7),
      Color(0xFF8C4FA8),
    ],
    band: Color(0x33000000),
    line: Color(0xFFC9FFF5),
    finish: CardFinish.holo,
    shine: true,
  );

  static const standard = PlayerCardTheme(
    gradient: [Color(0xFF11170F), Color(0xFF1C4A28), Color(0xFF2A8B49)],
    ink: Color(0xFFF4FFE8),
    accent: Color(0xFFC8FF42),
    glow: Color(0xFFC8FF42),
    shadow: Color(0xFF08110B),
    frame: [
      Color(0xFF1B4627),
      Color(0xFFD4FF8A),
      Color(0xFF2F7B43),
      Color(0xFF0B2212),
    ],
    band: Color(0x2E000000),
    line: Color(0xFFA8E06A),
  );

  Color get tagFill => Color.lerp(gradient.first, Colors.white, .55)!;

  TextStyle text(
    double size, {
    double alpha = 1,
    double letterSpacing = 0,
    double height = .95,
    FontWeight weight = FontWeight.w800,
  }) => TextStyle(
    fontFamily: 'Vazirmatn',
    fontWeight: weight,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    color: ink.withValues(alpha: alpha),
  );
}
