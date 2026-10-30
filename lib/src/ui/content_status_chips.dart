import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';
import 'deadline_chip.dart';

enum ContentFreshness { expired, urgent, closingSoon, active }

ContentFreshness contentFreshness(DateTime expiresAt, {DateTime? now}) {
  final remaining = expiresAt.toLocal().difference(now ?? DateTime.now());
  if (remaining <= Duration.zero) return ContentFreshness.expired;
  if (remaining < const Duration(hours: 3)) return ContentFreshness.urgent;
  if (remaining < const Duration(hours: 24)) {
    return ContentFreshness.closingSoon;
  }
  return ContentFreshness.active;
}

bool isFreshContent(DateTime? publishedAt, {DateTime? now}) {
  if (publishedAt == null) return false;
  final age = (now ?? DateTime.now()).difference(publishedAt.toLocal());
  return !age.isNegative && age < const Duration(hours: 72);
}

/// The single row of honest content states used across SBC, Evolutions,
/// Objectives and News. A deadline only renders when the source supplies one;
/// nothing here invents an expiry date.
class ContentStatusChips extends StatelessWidget {
  const ContentStatusChips({
    this.expiresAt,
    this.publishedAt,
    this.now,
    this.repeatable = false,
    this.compact = true,
    this.alignment = WrapAlignment.start,
    this.showJalaliDate = false,
    super.key,
  });

  final DateTime? expiresAt;
  final DateTime? publishedAt;
  final DateTime? now;
  final bool repeatable;
  final bool compact;
  final WrapAlignment alignment;
  final bool showJalaliDate;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final chips = <Widget>[
      if (expiresAt != null)
        DeadlineChip(
          expiresAt: expiresAt,
          now: now,
          compact: compact,
          showJalaliDate: showJalaliDate,
        ),
      if (repeatable)
        _StatusPill(
          icon: Icons.repeat_rounded,
          label: 'قابل تکرار',
          color: palette.secondary,
          compact: compact,
        ),
      if (isFreshContent(publishedAt, now: now))
        _StatusPill(
          icon: Icons.auto_awesome_rounded,
          label: 'تازه',
          color: palette.success,
          compact: compact,
          semanticLabel: 'گزارش تازه',
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: alignment,
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.compact,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool compact;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: semanticLabel != null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 3 : 4,
        ),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
