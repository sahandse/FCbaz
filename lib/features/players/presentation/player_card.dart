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
    final theme = _FcCardTheme.fromPlayer(player);
    final version = player.version.isNotEmpty
        ? player.version
        : (player.rarity.isNotEmpty ? player.rarity : player.cardType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerDetailsScreen(player: player),
          ),
        ),
        child: AspectRatio(
          aspectRatio: .72,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.gradient,
                stops: const [0, .58, 1],
              ),
              border: Border.all(color: theme.border.withValues(alpha: .9)),
              boxShadow: [
                BoxShadow(
                  color: theme.glow.withValues(alpha: .18),
                  blurRadius: 22,
                  spreadRadius: -8,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: Stack(
                children: [
                  Positioned(
                    top: -34,
                    right: -28,
                    child: Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.glow.withValues(alpha: .12),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -45,
                    bottom: 42,
                    child: Transform.rotate(
                      angle: -.36,
                      child: Container(
                        width: 150,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          color: theme.accent.withValues(alpha: .08),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.rating > 0 ? '${player.rating}' : '—',
                                    style: TextStyle(
                                      color: theme.text,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 27,
                                      height: .95,
                                      letterSpacing: -1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    player.position.isEmpty ? '—' : player.position,
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                      color: theme.text.withValues(alpha: .82),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _toggleFavorite,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.overlay,
                                    border: Border.all(
                                      color: theme.text.withValues(alpha: .12),
                                    ),
                                  ),
                                  child: Icon(
                                    favorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 17,
                                    color: favorite
                                        ? const Color(0xFFFF566B)
                                        : theme.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
                              child: player.imageUrl.isEmpty
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 76,
                                      color: theme.text.withValues(alpha: .24),
                                    )
                                  : Image.network(
                                      player.imageUrl,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.bottomCenter,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.person_rounded,
                                        size: 76,
                                        color: theme.text.withValues(alpha: .24),
                                      ),
                                    ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                            decoration: BoxDecoration(
                              color: theme.overlay,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: theme.text.withValues(alpha: .08),
                              ),
                            ),
                            child: Column(
                              children: [
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    player.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: theme.text,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: -.25,
                                    ),
                                  ),
                                ),
                                if (version.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    version,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                      color: theme.text.withValues(alpha: .64),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _Stat('PAC', player.pace, theme.text),
                                    _Stat('SHO', player.shooting, theme.text),
                                    _Stat('PAS', player.passing, theme.text),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _Stat('DRI', player.dribbling, theme.text),
                                    _Stat('DEF', player.defending, theme.text),
                                    _Stat('PHY', player.physical, theme.text),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.toll_rounded,
                                      size: 13,
                                      color: theme.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _coins(selectedPrice),
                                      textDirection: TextDirection.ltr,
                                      style: TextStyle(
                                        color: theme.text,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      widget.pricePlatform == 'pc' ? 'PC' : 'Console',
                                      style: TextStyle(
                                        color: theme.text.withValues(alpha: .5),
                                        fontSize: 7,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value > 0 ? '$value' : '—',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: .5),
              fontSize: 7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FcCardTheme {
  const _FcCardTheme({
    required this.gradient,
    required this.text,
    required this.accent,
    required this.border,
    required this.glow,
    required this.overlay,
  });

  final List<Color> gradient;
  final Color text;
  final Color accent;
  final Color border;
  final Color glow;
  final Color overlay;

  static _FcCardTheme fromPlayer(Player player) {
    final raw = '${player.version} ${player.rarity} ${player.cardType}'.toLowerCase();

    if (raw.contains('icon')) {
      return const _FcCardTheme(
        gradient: [Color(0xFFFFF8E6), Color(0xFFEDE1BC), Color(0xFFCBB983)],
        text: Color(0xFF2D271D),
        accent: Color(0xFF9E7C2F),
        border: Color(0xFFD7C384),
        glow: Color(0xFFE6CB76),
        overlay: Color(0xCFFFF8E8),
      );
    }
    if (raw.contains('hero')) {
      return const _FcCardTheme(
        gradient: [Color(0xFF27103C), Color(0xFF5E184A), Color(0xFFB34A32)],
        text: Color(0xFFFFF4E7),
        accent: Color(0xFFFFC35A),
        border: Color(0xFFC26658),
        glow: Color(0xFFFF9D4A),
        overlay: Color(0x8A210D31),
      );
    }
    if (raw.contains('team of the week') || raw.contains('totw')) {
      return const _FcCardTheme(
        gradient: [Color(0xFF0A0B0E), Color(0xFF171A20), Color(0xFF282B2F)],
        text: Color(0xFFF6E9A8),
        accent: Color(0xFFE8D06B),
        border: Color(0xFF696144),
        glow: Color(0xFFD6BE58),
        overlay: Color(0xA3000000),
      );
    }
    if (raw.contains('hall of fut')) {
      return const _FcCardTheme(
        gradient: [Color(0xFF03262D), Color(0xFF075463), Color(0xFF0A7C79)],
        text: Color(0xFFE9FFFF),
        accent: Color(0xFF7FF4E8),
        border: Color(0xFF44BFB9),
        glow: Color(0xFF3FE1D6),
        overlay: Color(0x8A03272E),
      );
    }
    if (raw.contains('destined for glory')) {
      return const _FcCardTheme(
        gradient: [Color(0xFF061B3D), Color(0xFF153F78), Color(0xFF7A2FA4)],
        text: Color(0xFFF5F3FF),
        accent: Color(0xFFBCA7FF),
        border: Color(0xFF6C6ED4),
        glow: Color(0xFF7F65E8),
        overlay: Color(0x7A091C46),
      );
    }
    if (raw.contains('squad foundations')) {
      return const _FcCardTheme(
        gradient: [Color(0xFF2A0A14), Color(0xFF71172B), Color(0xFFBB4B39)],
        text: Color(0xFFFFF3EB),
        accent: Color(0xFFFFB378),
        border: Color(0xFFD06A55),
        glow: Color(0xFFFF805F),
        overlay: Color(0x84220A12),
      );
    }
    if (raw.contains('holographic') || raw.contains('pristine')) {
      return const _FcCardTheme(
        gradient: [Color(0xFF192452), Color(0xFF77499A), Color(0xFF2BB9A9)],
        text: Color(0xFFFFFFFF),
        accent: Color(0xFF8FFFEF),
        border: Color(0xFF9C8DFF),
        glow: Color(0xFF63F3E1),
        overlay: Color(0x70211453),
      );
    }
    if (raw.contains('gold') || raw.contains('rare')) {
      return const _FcCardTheme(
        gradient: [Color(0xFFF4E5A4), Color(0xFFCBAE59), Color(0xFF8D6E24)],
        text: Color(0xFF1C1A12),
        accent: Color(0xFF5C4610),
        border: Color(0xFFE3CF75),
        glow: Color(0xFFFFD862),
        overlay: Color(0xB8F4E7B0),
      );
    }
    return const _FcCardTheme(
      gradient: [Color(0xFF11161D), Color(0xFF18242C), Color(0xFF173A38)],
      text: Color(0xFFF4F7F8),
      accent: Color(0xFF66F08A),
      border: Color(0xFF29443D),
      glow: Color(0xFF66F08A),
      overlay: Color(0x9A0A1014),
    );
  }
}
