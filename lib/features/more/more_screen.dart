import 'package:flutter/material.dart';

import '../club/presentation/my_club_screen.dart';
import '../evolutions/presentation/evolutions_hub_screen.dart';
import '../home/objectives_screen.dart';
import '../market/presentation/fodder_screen.dart';
import '../market/presentation/market_screen.dart';
import '../market/presentation/pack_value_screen.dart';
import '../market/presentation/tax_calculator_screen.dart';
import '../meta/presentation/meta_screen.dart';
import '../meta/presentation/totw_promo_screen.dart';
import '../sbc/presentation/sbc_hub_screen.dart';
import '../settings/app_settings_repository.dart';
import '../settings/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../squad/presentation/tactics_builder_screen.dart';
import '../squad/squad_screen.dart';
import 'consumables_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    required this.settings,
    required this.onSettingsChanged,
    super.key,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text(
          'بیشتر',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'ابزارهای اصلی و تنظیمات؛ بدون ثبت‌نام و بدون حساب اجباری.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        Text(
          'ابزارهای Ultimate Team',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _ToolCard(
              title: 'بازار',
              subtitle: 'قیمت و Watchlist',
              icon: Icons.query_stats_rounded,
              onTap: () => _open(context, const MarketScreen()),
            ),
            _ToolCard(
              title: 'Fodder',
              subtitle: 'ارزان‌ترین هر ریتینگ',
              icon: Icons.local_offer_rounded,
              onTap: () => _open(context, const FodderScreen()),
            ),
            _ToolCard(
              title: 'مالیات ۵٪',
              subtitle: 'سود واقعی فروش',
              icon: Icons.calculate_rounded,
              onTap: () => _open(context, const TaxCalculatorScreen()),
            ),
            _ToolCard(
              title: 'ارزش پک',
              subtitle: 'جمع کارت‌های پک',
              icon: Icons.inventory_rounded,
              onTap: () => _open(context, const PackValueScreen()),
            ),
            _ToolCard(
              title: 'SBC Center',
              subtitle: 'چالش + ترکیب ریتینگ',
              icon: Icons.extension_rounded,
              onTap: () => _open(context, const SbcHubScreen()),
            ),
            _ToolCard(
              title: 'Evolutions',
              subtitle: 'فعال + My Evo',
              icon: Icons.auto_awesome_rounded,
              onTap: () => _open(context, const EvolutionsHubScreen()),
            ),
            _ToolCard(
              title: 'TOTW / News',
              subtitle: 'پرومو و هایلایت',
              icon: Icons.newspaper_rounded,
              onTap: () => _open(context, const TotwPromoScreen()),
            ),
            _ToolCard(
              title: 'Meta',
              subtitle: 'برترین‌ها هر پست',
              icon: Icons.leaderboard_rounded,
              onTap: () => _open(context, const MetaScreen()),
            ),
            _ToolCard(
              title: 'تیم‌ساز',
              subtitle: 'Squad + Chemistry',
              icon: Icons.stadium_rounded,
              onTap: () => _open(context, const SquadScreen()),
            ),
            _ToolCard(
              title: 'Tactics',
              subtitle: 'کد و پلن تاکتیک',
              icon: Icons.sports_soccer_rounded,
              onTap: () => _open(context, const TacticsBuilderScreen()),
            ),
            _ToolCard(
              title: 'باشگاه من',
              subtitle: 'کارت‌ها و ارزش',
              icon: Icons.inventory_2_rounded,
              onTap: () => _open(context, const MyClubScreen()),
            ),
            _ToolCard(
              title: 'اهداف',
              subtitle: 'Objectives',
              icon: Icons.flag_rounded,
              onTap: () => _open(context, const ObjectivesScreen()),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'اطلاعات من',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.account_circle_rounded,
                title: 'پروفایل',
                subtitle: 'Favorites، My Club، Squads و Watchlist',
                onTap: () => _open(context, const ProfileScreen()),
              ),
              const Divider(),
              _MenuTile(
                icon: Icons.settings_rounded,
                title: 'تنظیمات',
                subtitle: 'تم، بازار، اعلان و بروزرسانی',
                onTap: () => _open(
                  context,
                  SettingsScreen(
                    settings: settings,
                    onChanged: onSettingsChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'راهنما',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Card(
          child: _MenuTile(
            icon: Icons.auto_fix_high_rounded,
            title: 'Consumables',
            subtitle: 'Chemistry Styles و راهنمای مصرفی‌ها',
            onTap: () => _open(context, const ConsumablesScreen()),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.primary.withValues(alpha: .18),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_outlined),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'دیتابیس بازیکن داخل اپ است؛ عکس کارت‌ها از CDN عمومی لود می‌شود و قیمت سکه وقتی منبع زنده بازار جواب بدهد نمایش داده می‌شود. داده ساختگی جایگزین نمی‌شود.',
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
          padding: const EdgeInsets.all(15),
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
              const SizedBox(height: 9),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_left_rounded),
    );
  }
}
