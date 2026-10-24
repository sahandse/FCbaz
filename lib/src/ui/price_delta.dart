import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';
import '../utils/persian_formatters.dart';

class PriceDelta extends StatelessWidget {
  const PriceDelta({required this.percent, super.key});

  final double? percent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final value = percent;
    if (value == null) {
      return Text(
        '—',
        style: TextStyle(color: palette.textMuted, fontSize: 11.5),
      );
    }

    final positive = value > 0;
    final neutral = value == 0;
    final color = neutral
        ? palette.textMuted
        : positive
        ? palette.success
        : palette.danger;
    final icon = neutral
        ? Icons.remove_rounded
        : positive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final amount = value.abs();
    final digits = amount
        .toStringAsFixed(amount >= 10 ? 1 : 2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    final label =
        '${neutral
            ? ''
            : positive
            ? '+'
            : '−'}${faDigits(digits)}٪';

    return Semantics(
      label: neutral
          ? 'بدون تغییر'
          : '${positive ? 'افزایش' : 'کاهش'} ${faDigits(digits)} درصد',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
