import 'package:flutter/material.dart';

import '../../../src/theme/fcbaz_theme.dart';
import '../domain/sbc_value_advisor.dart';

class SbcValueBadge extends StatelessWidget {
  const SbcValueBadge({
    required this.assessment,
    this.showDetail = false,
    super.key,
  });

  final SbcValueAssessment assessment;
  final bool showDetail;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (Color color, IconData icon) = switch (assessment.level) {
      SbcValueLevel.good => (palette.success, Icons.trending_up_rounded),
      SbcValueLevel.fair => (palette.warning, Icons.balance_rounded),
      SbcValueLevel.poor => (palette.danger, Icons.trending_down_rounded),
      SbcValueLevel.unknown => (palette.textMuted, Icons.help_outline_rounded),
    };

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: .32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              assessment.headlineFa,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: '${assessment.headlineFa}. ${assessment.detailFa}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(message: assessment.detailFa, child: badge),
          if (showDetail) ...[
            const SizedBox(height: 6),
            Text(
              assessment.detailFa,
              style: TextStyle(
                fontSize: 11,
                height: 1.65,
                color: palette.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
