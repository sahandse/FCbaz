import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';
import '../utils/persian_formatters.dart';

class SourceBadge extends StatelessWidget {
  const SourceBadge({
    required this.source,
    this.updatedAt,
    this.note,
    this.onRetry,
    super.key,
  });

  final String source;
  final DateTime? updatedAt;
  final String? note;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fresh =
        updatedAt != null &&
        DateTime.now().difference(updatedAt!.toLocal()) <
            const Duration(hours: 24);
    final dot = updatedAt == null
        ? palette.textMuted
        : fresh
        ? palette.success
        : palette.warning;
    final description = [
      if (updatedAt != null) 'بهروزرسانی ${relativeTimeFa(updatedAt!)}',
      if (note != null && note!.trim().isNotEmpty) note!.trim(),
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.md),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'منبع: $source',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description.isEmpty ? 'زمان به‌روزرسانی نامشخص' : description,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'تلاش دوباره',
            )
          else
            const SizedBox(width: 4),
        ],
      ),
    );
  }
}
