import 'package:flutter/material.dart';

import '../club/presentation/my_club_screen.dart';
import '../evolutions/presentation/evolutions_screen.dart';
import '../home/objectives_screen.dart';
import '../market/presentation/market_screen.dart';
import '../meta/presentation/meta_screen.dart';
import '../sbc/presentation/sbc_screen.dart';
import 'consumables_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text(
          'ابزارها',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'بخش‌های اصلی FCBaz، بدون گزینه‌های نمایشی و ناقص',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.42,
          children: [
            _ToolCard(
              title: 'بازار',
              subtitle: 'قیمت، تاریخچه و واچ‌لیست',
              icon: Icons.query_stats_rounded,
              onTap: () => _open(context, const MarketScreen()),
            ),
            _ToolCard(
              title: 'SBC',
              subtitle: 'چالش‌ها و Solver',
              icon: Icons.extension_rounded,
              onTap: () => _open(context, const SbcScreen()),
            ),
            _ToolCard(
              title: 'Evolutions',
              subtitle: 'Evo Lab و بازیکنان مناسب',
              icon: Icons.auto_awesome_rounded,
              onTap: () => _open(context, const EvolutionsScreen()),
            ),
            _ToolCard(
              title: 'باشگاه من',
              subtitle: 'بازیکنان و سرمایه باشگاه',
              icon: Icons.inventory_2_rounded,
              onTap: () => _open(context, const MyClubScreen()),
            ),
            _ToolCard(
              title: 'Meta',
              subtitle: 'بهترین بازیکنان هر پست',
              icon: Icons.leaderboard_rounded,
              onTap: () => _open(context, const MetaScreen()),
            ),
            _ToolCard(
              title: 'Objectives',
              subtitle: 'هدف‌ها و پاداش‌های زنده',
              icon: Icons.flag_rounded,
              onTap: () => _open(context, const ObjectivesScreen()),
            ),
            _ToolCard(
              title: 'Consumables',
              subtitle: 'Chemistry Styles و راهنما',
              icon: Icons.auto_fix_high_rounded,
              onTap: () => _open(context, const ConsumablesScreen()),
            ),
            _ToolCard(
              title: 'اخبار FC27',
              subtitle: 'Promo، SBC و Evo جدید',
              icon: Icons.newspaper_rounded,
              onTap: () => _open(context, const NewsScreen()),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: .18)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ابزارهایی که داده واقعی یا منطق کامل ندارند فعلاً از منو حذف شده‌اند تا رابط کاربری تمیز بماند.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: scheme.primary, size: 21),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
