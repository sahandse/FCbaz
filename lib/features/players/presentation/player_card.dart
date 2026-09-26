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
    final t = _ItemTheme.fromPlayer(player);
    final version = player.version.isNotEmpty
        ? player.version
        : (player.rarity.isNotEmpty ? player.rarity : player.cardType);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: player)),
      ),
      child: AspectRatio(
        aspectRatio: .69,
        child: ClipPath(
          clipper: const _PlayerItemClipper(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: t.gradient,
                stops: const [0, .54, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: t.glow.withValues(alpha: .22),
                  blurRadius: 24,
                  spreadRadius: -8,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _ItemPattern(t))),
                Positioned(
                  top: 10,
                  left: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        player.rating > 0 ? '${player.rating}' : '—',
                        style: TextStyle(
                          color: t.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 29,
                          height: .92,
                          letterSpacing: -1.6,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        player.position.isEmpty ? '—' : player.position,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: t.text.withValues(alpha: .9),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: t.panel.withValues(alpha: .72),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: t.text.withValues(alpha: .12)),
                      ),
                      child: Icon(
                        favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 16,
                        color: favorite ? const Color(0xFFFF5F72) : t.text,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 31,
                  left: 32,
                  right: 16,
                  height: 126,
                  child: player.imageUrl.isEmpty
                      ? Icon(Icons.person_rounded, size: 92, color: t.text.withValues(alpha: .25))
                      : Image.network(
                          player.imageUrl,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            size: 92,
                            color: t.text.withValues(alpha: .25),
                          ),
                        ),
                ),
                Positioned(
                  left: 11,
                  right: 11,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                    decoration: BoxDecoration(
                      color: t.panel.withValues(alpha: .78),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.text.withValues(alpha: .10)),
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
                              color: t.text,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: -.25,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (player.clubName.isNotEmpty) player.clubName,
                            if (player.nationName.isNotEmpty) player.nationName,
                          ].take(2).join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: t.text.withValues(alpha: .60),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            _Stat('PAC', player.pace, t.text),
                            _Stat('SHO', player.shooting, t.text),
                            _Stat('PAS', player.passing, t.text),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _Stat('DRI', player.dribbling, t.text),
                            _Stat('DEF', player.defending, t.text),
                            _Stat('PHY', player.physical, t.text),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Expanded(child: _PriceChip(label: 'Console', value: _coins(player.pricePs), theme: t)),
                            const SizedBox(width: 5),
                            Expanded(child: _PriceChip(label: 'PC', value: _coins(player.pricePc), theme: t)),
                          ],
                        ),
                        if (version.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: t.accent.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              version,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                color: t.text.withValues(alpha: .84),
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.label, required this.value, required this.theme});
  final String label;
  final String value;
  final _ItemTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: theme.text.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.toll_rounded, size: 9, color: theme.accent),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              '$value $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: theme.text, fontSize: 7.5, fontWeight: FontWeight.w900),
            ),
          ),
        ],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value > 0 ? '$value' : '—',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9.5),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: .48), fontSize: 6.5, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PlayerItemClipper extends CustomClipper<Path> {
  const _PlayerItemClipper();

  @override
  Path getClip(Size s) {
    return Path()
      ..moveTo(s.width * .17, 0)
      ..lineTo(s.width * .83, 0)
      ..lineTo(s.width, s.height * .10)
      ..lineTo(s.width * .96, s.height * .88)
      ..lineTo(s.width * .79, s.height)
      ..lineTo(s.width * .21, s.height)
      ..lineTo(s.width * .04, s.height * .88)
      ..lineTo(0, s.height * .10)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ItemPattern extends CustomPainter {
  const _ItemPattern(this.theme);
  final _ItemTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = theme.text.withValues(alpha: .06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width * .12, size.height * .18), Offset(size.width * .88, size.height * .06), line);
    canvas.drawLine(Offset(size.width * .04, size.height * .52), Offset(size.width * .96, size.height * .34), line);
    canvas.drawCircle(Offset(size.width * .72, size.height * .25), size.width * .28, line);
  }

  @override
  bool shouldRepaint(covariant _ItemPattern oldDelegate) => oldDelegate.theme != theme;
}

class _ItemTheme {
  const _ItemTheme({
    required this.gradient,
    required this.text,
    required this.accent,
    required this.glow,
    required this.panel,
  });

  final List<Color> gradient;
  final Color text;
  final Color accent;
  final Color glow;
  final Color panel;

  static _ItemTheme fromPlayer(Player player) {
    final raw = '${player.version} ${player.rarity} ${player.cardType}'.toLowerCase();
    if (raw.contains('icon')) {
      return const _ItemTheme(
        gradient: [Color(0xFFFFF7DF), Color(0xFFE6D3A3), Color(0xFFA38A4C)],
        text: Color(0xFF292116), accent: Color(0xFF9A7428), glow: Color(0xFFEBCB72), panel: Color(0xFFEFE2BF),
      );
    }
    if (raw.contains('hero')) {
      return const _ItemTheme(
        gradient: [Color(0xFF170B2C), Color(0xFF5C174B), Color(0xFFC24B2B)],
        text: Color(0xFFFFF5E7), accent: Color(0xFFFFC757), glow: Color(0xFFFF8745), panel: Color(0xFF190B28),
      );
    }
    if (raw.contains('team of the week') || raw.contains('totw')) {
      return const _ItemTheme(
        gradient: [Color(0xFF050606), Color(0xFF151714), Color(0xFF3A3522)],
        text: Color(0xFFF7E99E), accent: Color(0xFFE6CE62), glow: Color(0xFFC7B24E), panel: Color(0xFF050606),
      );
    }
    if (raw.contains('hall of fut')) {
      return const _ItemTheme(
        gradient: [Color(0xFF041C24), Color(0xFF07585D), Color(0xFF17A394)],
        text: Color(0xFFECFFFB), accent: Color(0xFF8CFFF1), glow: Color(0xFF52F2D8), panel: Color(0xFF05252B),
      );
    }
    if (raw.contains('holographic') || raw.contains('pristine')) {
      return const _ItemTheme(
        gradient: [Color(0xFF12224B), Color(0xFF7B4AA0), Color(0xFF21B6A2)],
        text: Color(0xFFFFFFFF), accent: Color(0xFF9BFFED), glow: Color(0xFF7CFFE9), panel: Color(0xFF18113D),
      );
    }
    if (raw.contains('gold')) {
      return const _ItemTheme(
        gradient: [Color(0xFFF6E8A9), Color(0xFFC4A54D), Color(0xFF725718)],
        text: Color(0xFF1A180E), accent: Color(0xFF5B4310), glow: Color(0xFFFFD969), panel: Color(0xFFDECA7A),
      );
    }
    if (raw.contains('silver')) {
      return const _ItemTheme(
        gradient: [Color(0xFFE8EEF0), Color(0xFFA6B1B4), Color(0xFF59666A)],
        text: Color(0xFF111718), accent: Color(0xFF344347), glow: Color(0xFFC9D7DA), panel: Color(0xFFC1CBCD),
      );
    }
    if (raw.contains('bronze')) {
      return const _ItemTheme(
        gradient: [Color(0xFFD8A078), Color(0xFF9B6240), Color(0xFF56311F)],
        text: Color(0xFF1F110A), accent: Color(0xFF5E2F16), glow: Color(0xFFE7A06E), panel: Color(0xFFB87C55),
      );
    }
    return const _ItemTheme(
      gradient: [Color(0xFF0B100C), Color(0xFF14351D), Color(0xFF1E6B38)],
      text: Color(0xFFF4FFE8), accent: Color(0xFFC8FF42), glow: Color(0xFFC8FF42), panel: Color(0xFF09120C),
    );
  }
}
