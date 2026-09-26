import 'package:flutter/material.dart';

import '../domain/player.dart';

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
    final t = _VisualTheme.fromPlayer(player);
    final version = player.version.isNotEmpty
        ? player.version
        : (player.rarity.isNotEmpty ? player.rarity : player.cardType);

    return AspectRatio(
      aspectRatio: compact ? .72 : .70,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final imageTop = h * .12;
          final imageHeight = h * (compact ? .43 : .46);
          final panelHeight = h * (showPrices ? .43 : .35);

          return ClipPath(
            clipper: const _ItemClipper(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: t.gradient,
                  stops: const [0, .55, 1],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(child: CustomPaint(painter: _Pattern(t))),
                  Positioned(
                    top: h * .045,
                    left: w * .055,
                    child: SizedBox(
                      width: w * .19,
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              player.rating > 0 ? '${player.rating}' : '—',
                              style: TextStyle(
                                color: t.text,
                                fontWeight: FontWeight.w900,
                                fontSize: compact ? 31 : 38,
                                height: .88,
                                letterSpacing: -1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            player.position.isEmpty ? '—' : player.position,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              color: t.text.withValues(alpha: .92),
                              fontWeight: FontWeight.w900,
                              fontSize: compact ? 10 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: imageTop,
                    left: w * .16,
                    right: w * .07,
                    height: imageHeight,
                    child: _PlayerImage(
                      primaryUrl: player.imageUrl,
                      fallbackUrl: player.cardImageUrl,
                      color: t.text.withValues(alpha: .24),
                      compact: compact,
                    ),
                  ),
                  Positioned(
                    left: w * .05,
                    right: w * .05,
                    bottom: h * .035,
                    height: panelHeight,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 8 : 11,
                        compact ? 7 : 10,
                        compact ? 8 : 11,
                        compact ? 7 : 9,
                      ),
                      decoration: BoxDecoration(
                        color: t.panel.withValues(alpha: .86),
                        borderRadius: BorderRadius.circular(compact ? 10 : 12),
                        border: Border.all(color: t.text.withValues(alpha: .10)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: compact ? 18 : 21,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    player.name,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                      color: t.text,
                                      fontSize: compact ? 13 : 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (player.clubName.isNotEmpty) player.clubName,
                                  if (player.nationName.isNotEmpty) player.nationName,
                                ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: t.text.withValues(alpha: .64),
                                  fontSize: compact ? 7.5 : 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(children: [
                                _Stat('PAC', player.pace, t.text),
                                _Stat('SHO', player.shooting, t.text),
                                _Stat('PAS', player.passing, t.text),
                              ]),
                              const SizedBox(height: 3),
                              Row(children: [
                                _Stat('DRI', player.dribbling, t.text),
                                _Stat('DEF', player.defending, t.text),
                                _Stat('PHY', player.physical, t.text),
                              ]),
                            ],
                          ),
                          if (showPrices)
                            Row(children: [
                              Expanded(child: _Price(label: 'Console', value: _coins(player.pricePs), t: t)),
                              const SizedBox(width: 5),
                              Expanded(child: _Price(label: 'PC', value: _coins(player.pricePc), t: t)),
                            ]),
                          if (version.isNotEmpty)
                            Container(
                              constraints: const BoxConstraints(maxWidth: 120),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: t.accent.withValues(alpha: .13),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                version.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: t.text.withValues(alpha: .84),
                                  fontSize: compact ? 7 : 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
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

class _PlayerImage extends StatelessWidget {
  const _PlayerImage({
    required this.primaryUrl,
    required this.fallbackUrl,
    required this.color,
    required this.compact,
  });

  final String primaryUrl;
  final String fallbackUrl;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (primaryUrl.isEmpty && fallbackUrl.isEmpty) return _placeholder();
    return Image.network(
      primaryUrl.isNotEmpty ? primaryUrl : fallbackUrl,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) {
        if (primaryUrl.isNotEmpty && fallbackUrl.isNotEmpty && fallbackUrl != primaryUrl) {
          return Image.network(
            fallbackUrl,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => _placeholder(),
          );
        }
        return _placeholder();
      },
    );
  }

  Widget _placeholder() => Center(
        child: Icon(
          Icons.person_rounded,
          size: compact ? 72 : 104,
          color: color,
        ),
      );
}

class _Price extends StatelessWidget {
  const _Price({required this.label, required this.value, required this.t});
  final String label;
  final String value;
  final _VisualTheme t;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: t.text.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$value $label',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: TextStyle(color: t.text, fontSize: 7.5, fontWeight: FontWeight.w900),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
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
        ),
      );
}

class _ItemClipper extends CustomClipper<Path> {
  const _ItemClipper();

  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width * .17, 0)
    ..lineTo(s.width * .83, 0)
    ..lineTo(s.width, s.height * .10)
    ..lineTo(s.width * .96, s.height * .88)
    ..lineTo(s.width * .79, s.height)
    ..lineTo(s.width * .21, s.height)
    ..lineTo(s.width * .04, s.height * .88)
    ..lineTo(0, s.height * .10)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _Pattern extends CustomPainter {
  const _Pattern(this.t);
  final _VisualTheme t;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = t.text.withValues(alpha: .055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width * .12, size.height * .18), Offset(size.width * .88, size.height * .06), p);
    canvas.drawLine(Offset(size.width * .04, size.height * .52), Offset(size.width * .96, size.height * .34), p);
    canvas.drawCircle(Offset(size.width * .72, size.height * .25), size.width * .28, p);
  }

  @override
  bool shouldRepaint(covariant _Pattern oldDelegate) => oldDelegate.t != t;
}

class _VisualTheme {
  const _VisualTheme(this.gradient, this.text, this.accent, this.glow, this.panel);
  final List<Color> gradient;
  final Color text;
  final Color accent;
  final Color glow;
  final Color panel;

  static _VisualTheme fromPlayer(Player p) {
    final raw = '${p.version} ${p.rarity} ${p.cardType}'.toLowerCase();
    if (raw.contains('icon')) return const _VisualTheme([Color(0xFFFFF7DF), Color(0xFFE6D3A3), Color(0xFFA38A4C)], Color(0xFF292116), Color(0xFF9A7428), Color(0xFFEBCB72), Color(0xFFEFE2BF));
    if (raw.contains('hero')) return const _VisualTheme([Color(0xFF170B2C), Color(0xFF5C174B), Color(0xFFC24B2B)], Color(0xFFFFF5E7), Color(0xFFFFC757), Color(0xFFFF8745), Color(0xFF190B28));
    if (raw.contains('team of the week') || raw.contains('totw')) return const _VisualTheme([Color(0xFF050606), Color(0xFF151714), Color(0xFF3A3522)], Color(0xFFF7E99E), Color(0xFFE6CE62), Color(0xFFC7B24E), Color(0xFF050606));
    if (raw.contains('hall of fut')) return const _VisualTheme([Color(0xFF041C24), Color(0xFF07585D), Color(0xFF17A394)], Color(0xFFECFFFB), Color(0xFF8CFFF1), Color(0xFF52F2D8), Color(0xFF05252B));
    if (raw.contains('holographic') || raw.contains('pristine')) return const _VisualTheme([Color(0xFF12224B), Color(0xFF7B4AA0), Color(0xFF21B6A2)], Colors.white, Color(0xFF9BFFED), Color(0xFF7CFFE9), Color(0xFF18113D));
    if (raw.contains('gold')) return const _VisualTheme([Color(0xFFF6E8A9), Color(0xFFC4A54D), Color(0xFF725718)], Color(0xFF1A180E), Color(0xFF5B4310), Color(0xFFFFD969), Color(0xFFDECA7A));
    if (raw.contains('silver')) return const _VisualTheme([Color(0xFFE8EEF0), Color(0xFFA6B1B4), Color(0xFF59666A)], Color(0xFF111718), Color(0xFF344347), Color(0xFFC9D7DA), Color(0xFFC1CBCD));
    if (raw.contains('bronze')) return const _VisualTheme([Color(0xFFD8A078), Color(0xFF9B6240), Color(0xFF56311F)], Color(0xFF1F110A), Color(0xFF5E2F16), Color(0xFFE7A06E), Color(0xFFB87C55));
    return const _VisualTheme([Color(0xFF0B100C), Color(0xFF14351D), Color(0xFF1E6B38)], Color(0xFFF4FFE8), Color(0xFFC8FF42), Color(0xFFC8FF42), Color(0xFF09120C));
  }
}
