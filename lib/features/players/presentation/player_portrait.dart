import 'package:flutter/material.dart';

import '../../../core/network/player_media.dart';
import '../domain/player.dart';

class PlayerPortrait extends StatelessWidget {
  const PlayerPortrait({
    required this.player,
    this.width = 70,
    this.height = 88,
    this.borderRadius = 17,
    this.fit = BoxFit.cover,
    super.key,
  });

  final Player player;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final candidates = <String>[
      ...PlayerMedia.portraitCandidates(player.id, player.imageUrl),
      if (player.cardImageUrl.trim().isNotEmpty) player.cardImageUrl.trim(),
    ];
    final unique = <String>[];
    for (final url in candidates) {
      if (url.isNotEmpty && !unique.contains(url)) unique.add(url);
    }

    Widget fallback() => Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Text(
            player.rating > 0 ? player.rating.toString() : '?',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: width * 0.28,
            ),
          ),
        );

    if (unique.isEmpty) return fallback();

    return _PortraitChain(
      urls: unique,
      width: width,
      height: height,
      borderRadius: borderRadius,
      fit: fit,
      fallback: fallback(),
    );
  }
}

class _PortraitChain extends StatefulWidget {
  const _PortraitChain({
    required this.urls,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.fit,
    required this.fallback,
  });

  final List<String> urls;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final Widget fallback;

  @override
  State<_PortraitChain> createState() => _PortraitChainState();
}

class _PortraitChainState extends State<_PortraitChain> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    if (index >= widget.urls.length) return widget.fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Image.network(
        widget.urls[index],
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => index += 1);
          });
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }
}
