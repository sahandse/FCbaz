part of '../player_details_screen.dart';

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate({
    required this.child,
    required this.background,
    required this.line,
  });

  final Widget child;
  final Color background;
  final Color line;

  @override
  double get minExtent => SegmentedTabs.height + 1;

  @override
  double get maxExtent => SegmentedTabs.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _TabsDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.background != background ||
      oldDelegate.line != line;
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.inClub,
    required this.saving,
    required this.onAdd,
    required this.onCompare,
  });

  final bool inClub;
  final bool saving;
  final VoidCallback onAdd;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCompare,
                  icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                  label: const Text('مقایسه'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: saving ? null : onAdd,
                  style: inClub
                      ? FilledButton.styleFrom(
                          backgroundColor: palette.surfaceRaised,
                          foregroundColor: palette.primary,
                          side: BorderSide(color: palette.line),
                        )
                      : null,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          inClub ? Icons.check_rounded : Icons.add_rounded,
                          size: 18,
                        ),
                  label: Text(inClub ? 'در باشگاه' : 'افزودن به باشگاه'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
