import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FcbazSpace.xl,
        vertical: FcbazSpace.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  palette.primary.withValues(alpha: .18),
                  palette.primary.withValues(alpha: 0),
                ],
              ),
            ),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: BorderRadius.circular(FcbazRadius.lg),
                border: Border.all(
                  color: palette.primary.withValues(alpha: .28),
                ),
              ),
              child: Icon(icon, size: 26, color: palette.primary),
            ),
          ),
          const SizedBox(height: FcbazSpace.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: FcbazSpace.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: FcbazSpace.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.message,
    this.title = 'داده در دسترس نیست',
    this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.cloud_off_rounded,
      title: title,
      message: message,
      actionLabel: onRetry == null ? null : 'تلاش دوباره',
      onAction: onRetry,
    );
  }
}

class PlayerGridSkeleton extends StatelessWidget {
  const PlayerGridSkeleton({this.count = 6, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: 'در حال بارگذاری کارت‌ها',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        // Matches the collection grid so the list never jumps when the real
        // cards replace the placeholders.
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 10,
          childAspectRatio: .5,
        ),
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(FcbazRadius.lg),
            border: Border.all(color: palette.line),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0, .52, 1],
                      colors: [
                        palette.surfaceRaised,
                        palette.line.withValues(alpha: .45),
                        palette.surfaceRaised,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(FcbazRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 8,
                width: 90,
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 8,
                width: 54,
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
