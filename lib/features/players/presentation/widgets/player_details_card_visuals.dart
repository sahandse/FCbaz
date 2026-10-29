part of '../player_details_screen.dart';

class _CardBackdrop extends StatelessWidget {
  const _CardBackdrop({required this.player, required this.tint});

  final Player player;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(tint.withValues(alpha: .22), palette.canvas),
                palette.canvas,
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: 58,
          start: 0,
          end: 0,
          child: Center(
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tint.withValues(alpha: .30),
                    tint.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 64,
          start: 0,
          end: 0,
          child: Center(
            child: Hero(
              tag: playerHeroTag(player.id),
              child: SizedBox(
                width: 140,
                height: 200,
                child: PlayerItemVisual(player: player, showPrices: false),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.player,
    required this.loading,
    required this.detailError,
    required this.onRetry,
  });

  final Player player;
  final bool loading;
  final String? detailError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final version = player.version.isNotEmpty
        ? player.version
        : (player.rarity.isNotEmpty ? player.rarity : player.cardType);
    final meta = [
      player.clubName,
      player.leagueName,
      player.nationName,
    ].where((value) => value.trim().isNotEmpty).join(' • ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLAYER ITEM',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: 'BarlowCondensed',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.2,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(FcbazRadius.md),
                ),
                child: Text(
                  player.rating > 0 ? faDigits(player.rating) : '—',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    height: 1,
                    color: palette.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_value(player.position)}'
                      '${version.isEmpty ? '' : ' • $version'}',
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.isEmpty ? 'باشگاه، لیگ و ملیت ثبت نشده' : meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SourceBadge(
            source: 'FC27 Catalog',
            note: 'قیمت‌ها در تب بازار از منبع بازار خوانده می‌شوند.',
          ),
          if (loading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(minHeight: 2),
            ),
          ],
          if (detailError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.cloud_off_rounded, size: 17, color: palette.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'جزئیات کامل در دسترس نیست.',
                    style: TextStyle(fontSize: 11, color: palette.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _value(String value) => value.trim().isEmpty ? '—' : value;
}
