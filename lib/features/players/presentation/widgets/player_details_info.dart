part of '../player_details_screen.dart';

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    final data = <(String, String)>[
      ('CLUB', player.clubName),
      ('LEAGUE', player.leagueName),
      ('NATION', player.nationName),
      ('VERSION', player.version.isNotEmpty ? player.version : player.rarity),
      (
        'SKILLS',
        player.skillMoves > 0 ? '${faDigits(player.skillMoves)}★' : '—',
      ),
      (
        'WEAK FOOT',
        player.weakFoot > 0 ? '${faDigits(player.weakFoot)}★' : '—',
      ),
      ('FOOT', player.foot),
      ('HEIGHT', player.height),
      ('WORK RATES', player.workRates),
      ('RARITY', player.rarity),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      childAspectRatio: 2.2,
      children: [
        for (final item in data)
          _MiniInfo(label: item.$1, value: item.$2.isEmpty ? '—' : item.$2),
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceRaised.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.sm),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: palette.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final PlayerReview? review;

  @override
  Widget build(BuildContext context) {
    if (review == null) {
      return const _InfoCard(
        icon: Icons.rate_review_outlined,
        title: 'هنوز نظری ثبت نشده',
        subtitle: 'نظر شخصی فقط روی دستگاه ذخیره می‌شود.',
      );
    }
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.sm),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review!.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 19,
                  color: palette.primary,
                ),
            ],
          ),
          if (review!.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review!.text, style: const TextStyle(height: 1.6)),
          ],
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.sm),
        border: Border.all(color: palette.line),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 11.5, color: palette.textMuted),
      ),
    );
  }
}
