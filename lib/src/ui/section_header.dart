import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.kicker,
    this.actionLabel = 'همه',
    this.onAction,
    super.key,
  });

  final String title;
  final String? kicker;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kicker != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    kicker!.toUpperCase(),
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
                ),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_left_rounded, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}
