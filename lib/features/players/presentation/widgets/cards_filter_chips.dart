part of '../cards_screen.dart';

class _PriceFreshnessChip extends StatelessWidget {
  const _PriceFreshnessChip({
    required this.updatedAt,
    required this.ageLabel,
    required this.onTap,
  });

  final DateTime? updatedAt;
  final String? ageLabel;
  final VoidCallback onTap;

  /// Green under an hour, amber under six hours, red beyond that; the verified
  /// snapshot age is visible without opening anything.
  Color _dotColor(FcbazPalette palette) {
    final at = updatedAt;
    if (at == null) return palette.lineStrong;
    final age = DateTime.now().difference(at.toLocal());
    if (age.inMinutes < 60) return palette.success;
    if (age.inHours < 6) return palette.warning;
    return palette.danger;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = ageLabel == null ? 'کاتالوگ FC27' : 'قیمت‌ها · $ageLabel';
    return Semantics(
      button: true,
      label: 'تازگی قیمت‌ها: $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FcbazRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: palette.surfaceRaised.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(FcbazRadius.pill),
              border: Border.all(color: palette.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _dotColor(palette),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: palette.textMuted.withValues(alpha: .8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FreshnessRow extends StatelessWidget {
  const _FreshnessRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: palette.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: palette.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RarityChip extends StatelessWidget {
  const _RarityChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, textDirection: TextDirection.ltr),
        selected: active,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: palette.primary,
        labelStyle: TextStyle(
          color: active ? palette.onPrimary : palette.text,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StickySearchHeader extends SliverPersistentHeaderDelegate {
  _StickySearchHeader({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(height: height, width: double.infinity, child: child);

  @override
  bool shouldRebuild(covariant _StickySearchHeader oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.filter, required this.onClear});

  final PlayerFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (filter.position != null) 'پست ${filter.position!}',
      if (filter.version != null) 'نسخه ${filter.version!}',
      if (filter.rarity != null) 'کمیابی ${filter.rarity!}',
      if (filter.cardType != null && filter.cardType != filter.rarity)
        'نوع ${filter.cardType!}',
      if (filter.league != null) filter.league!,
      if (filter.club != null) filter.club!,
      if (filter.nation != null) filter.nation!,
      if (filter.minRating != 40 || filter.maxRating != 99)
        'ریتینگ ${faDigits(filter.minRating)}–${faDigits(filter.maxRating)}',
      if (filter.minPrice != null) 'از ${compactCoinsFa(filter.minPrice!)}',
      if (filter.maxPrice != null) 'تا ${compactCoinsFa(filter.maxPrice!)}',
      if (filter.platform == 'pc') 'PC',
      if (filter.role != null) 'نقش ${filter.role!}',
      if (filter.playStyle != null) filter.playStyle!,
      if (filter.playStylePlus != null) '+ ${filter.playStylePlus!}',
      if (filter.minSkillMoves != null)
        'SM ${faDigits(filter.minSkillMoves!)}★+',
      if (filter.minWeakFoot != null) 'WF ${faDigits(filter.minWeakFoot!)}★+',
    ];

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final label in labels) ...[
            Chip(label: Text(label)),
            const SizedBox(width: 5),
          ],
          ActionChip(
            avatar: const Icon(Icons.close_rounded, size: 15),
            label: const Text('پاک کردن'),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
