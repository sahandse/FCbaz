part of '../player_details_screen.dart';

class _PriceCell extends StatelessWidget {
  const _PriceCell({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.md),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: 'BarlowCondensed',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            compactCoinsFa(value),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: 'BarlowCondensed',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              height: 1,
              color: palette.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Coins',
            textDirection: TextDirection.ltr,
            style: TextStyle(fontSize: 10, color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StatBars extends StatelessWidget {
  const _StatBars({required this.stats});

  final List<(String, int)> stats;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        for (var i = 0; i < stats.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == stats.length - 1 ? 0 : 9),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    stats[i].$1,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: palette.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stats[i].$2 <= 0
                          ? 0
                          : (stats[i].$2 / 99).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: palette.surfaceRaised,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    stats[i].$2 > 0 ? faDigits(stats[i].$2) : '—',
                    textAlign: TextAlign.end,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InGameStats extends StatelessWidget {
  const _InGameStats({required this.values});
  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (_, index) =>
          _StatTile(label: entries[index].key, value: entries[index].value),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.sm),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value > 0 ? faDigits(value) : '—',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: palette.primary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              height: 1.1,
            ),
          ),
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 10.5,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
