import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';
import '../utils/persian_formatters.dart';

class DeadlineChip extends StatelessWidget {
  const DeadlineChip({
    required this.expiresAt,
    this.now,
    this.compact = false,
    super.key,
  });

  final DateTime? expiresAt;
  final DateTime? now;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final value = expiresAt;
    if (value == null) return const SizedBox.shrink();
    final palette = context.palette;
    final remaining = value.toLocal().difference(now ?? DateTime.now());
    final expired = remaining <= Duration.zero;
    final color = expired || remaining < const Duration(hours: 3)
        ? palette.danger
        : remaining < const Duration(hours: 24)
        ? palette.warning
        : palette.textMuted;
    final icon = expired
        ? Icons.event_busy_rounded
        : remaining < const Duration(hours: 24)
        ? Icons.timer_rounded
        : Icons.schedule_rounded;

    return Container(
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
            expired ? 'منقضی' : relativeDeadlineFa(value, now: now),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
