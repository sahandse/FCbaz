import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';

class FcbazTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FcbazTopBar({
    required this.title,
    this.onSearch,
    this.onNotifications,
    this.unread = 0,
    super.key,
  });

  final String title;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;
  final int unread;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppBar(
      toolbarHeight: 58,
      titleSpacing: FcbazSpace.lg,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.primary,
              borderRadius: BorderRadius.circular(FcbazRadius.sm),
              boxShadow: [
                BoxShadow(
                  color: palette.primary.withValues(alpha: .18),
                  blurRadius: 18,
                  spreadRadius: -6,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'FC',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: palette.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: -.6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                Text(
                  'FC27 • ULTIMATE TEAM',
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: .8,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onSearch != null)
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
            tooltip: 'جستجوی سراسری',
          ),
        if (onNotifications != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Badge(
              isLabelVisible: unread > 0,
              alignment: AlignmentDirectional.topStart,
              offset: const Offset(5, 3),
              label: Text(unread > 99 ? '99+' : '$unread'),
              child: IconButton(
                onPressed: onNotifications,
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'اعلان‌ها',
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: palette.line),
      ),
    );
  }
}
