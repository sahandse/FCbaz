import 'package:flutter/material.dart';

import '../theme/fcbaz_theme.dart';

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    required this.controller,
    required this.tabs,
    super.key,
  });

  static const double height = 45;

  final TabController controller;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerHeight: 0,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color: palette.primary,
        borderRadius: BorderRadius.circular(FcbazRadius.sm),
      ),
      labelColor: palette.onPrimary,
      unselectedLabelColor: palette.textMuted,
      labelStyle: const TextStyle(
        fontFamily: 'Vazirmatn',
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Vazirmatn',
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      tabs: [for (final tab in tabs) Tab(height: 44, text: tab)],
    );
  }
}
