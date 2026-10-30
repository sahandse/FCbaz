import 'package:flutter/material.dart';
import 'package:fcbaz/src/navigation/app_navigator.dart';

import '../draft/presentation/draft_screen.dart';

import '../club/presentation/my_club_screen.dart';
import '../dns/presentation/dns_screen.dart';
import '../evolutions/presentation/evolutions_screen.dart';
import '../home/content_hub_screen.dart';
import '../home/objectives_screen.dart';
import '../market/presentation/market_screen.dart';
import '../market/presentation/market_tools_screen.dart';
import '../meta/presentation/meta_screen.dart' hide NewsScreen;
import '../news/presentation/news_screen.dart';
import '../sbc/presentation/sbc_screen.dart';
import '../settings/app_settings_repository.dart';
import '../settings/profile_screen.dart';
import '../settings/settings_screen.dart';
import 'consumables_screen.dart';
import 'fc27_reference_screen.dart';

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
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                scheme.primary.withValues(alpha: .22),
                scheme.surfaceContainerHighest,
                scheme.surface,
              ],
            ),
            border: Border.all(color: scheme.primary.withValues(alpha: .4)),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: .12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _open(context, const ProfileScreen()),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      child: const Icon(Icons.person_rounded, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'بخش من و باشگاه',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: .2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'LOCAL',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'مدیریت باشگاه، کارت‌ها، واچ‌لیست و ترکیب‌های ذخیره‌شده',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: scheme.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Text('ابزارها', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'همه ابزارهای FC27 بدون ثبت‌نام؛ فقط با داده واقعی و ذخیره محلی.',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        Text('ابزارهای اصلی', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 148,
          ),
          children: [
            _ToolCard(
              title: 'مرکز محتوا',
              subtitle: 'شمارش معکوس SBC، Evolution و Objectiveها',
              icon: Icons.hourglass_top_rounded,
              onTap: () => _open(context, const ContentHubScreen()),
            ),
            _ToolCard(
              title: 'بازار',
              subtitle: 'قیمت زنده و فهرست پیگیری',
              icon: Icons.query_stats_rounded,
              onTap: () => _open(context, const MarketScreen()),
            ),
            _ToolCard(
              title: 'ابزارهای بازار',
              subtitle: 'ارزان‌ترین ریتینگ و محبوب‌ترین‌ها',
              icon: Icons.price_check_rounded,
              onTap: () => _open(context, const MarketToolsScreen()),
            ),
            _ToolCard(
              title: 'چالش‌های ساخت ترکیب',
              subtitle: 'SBCهای فعال و راه‌حل‌ها',
              icon: Icons.extension_rounded,
              onTap: () => _open(context, const SbcScreen()),
            ),
            _ToolCard(
              title: 'تکامل بازیکنان',
              subtitle: 'Evoهای فعال و شرایط',
              icon: Icons.auto_awesome_rounded,
              onTap: () => _open(context, const EvolutionsScreen()),
            ),
            _ToolCard(
              title: 'اهداف',
              subtitle: 'ماموریت‌ها و پاداش‌ها',
              icon: Icons.flag_rounded,
              onTap: () => _open(context, const ObjectivesScreen()),
            ),
            _ToolCard(
              title: 'باشگاه من',
              subtitle: 'کارت‌ها و ارزش باشگاه',
              icon: Icons.inventory_2_rounded,
              onTap: () => _open(context, const MyClubScreen()),
            ),
            _ToolCard(
              title: 'بازیکنان برتر',
              subtitle: 'متای هر پست بر اساس داده واقعی',
              icon: Icons.leaderboard_rounded,
              onTap: () => _open(context, const MetaScreen()),
            ),
            _ToolCard(
              title: 'سبک‌ها و نقش‌ها',
              subtitle: 'راهنمای فارسی PlayStyle و Roleهای FC27',
              icon: Icons.schema_rounded,
              onTap: () => _open(context, const Fc27ReferenceScreen()),
            ),
            _ToolCard(
              title: 'شبیه‌ساز درافت',
              subtitle: 'FUT Draft ۱۱ نفره با شیمی و ریتینگ زنده',
              icon: Icons.sports_soccer_rounded,
              onTap: () => _open(context, const DraftScreen()),
            ),
            _ToolCard(
              title: 'دی‌ان‌اس گیمینگ',
              subtitle: '۲۰ سرور برتر ضدتحریم و کاهش پینگ کنسول',
              icon: Icons.dns_rounded,
              onTap: () => _open(context, const DnsScreen()),
            ),
            _ToolCard(
              title: 'اخبار و رویدادها',
              subtitle: 'پچ‌نوت‌ها، رویدادها و اخبار رسمی FC27',
              icon: Icons.newspaper_rounded,
              onTap: () => _open(context, const NewsScreen()),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text('داده‌های محلی من', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.account_circle_rounded,
                title: 'پروفایل محلی',
                subtitle: 'علاقه‌مندی‌ها، باشگاه، ترکیب‌ها و فهرست پیگیری',
                onTap: () => _open(context, const ProfileScreen()),
              ),
              const Divider(),
              _MenuTile(
                icon: Icons.settings_rounded,
                title: 'تنظیمات',
                subtitle: 'تم، بازار، اعلان‌ها و بروزرسانی',
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
        Text('راهنمای بازی', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.auto_fix_high_rounded,
                title: 'آیتم‌های مصرفی',
                subtitle: 'سبک‌های شیمی و راهنمای آیتم‌های مصرفی',
                onTap: () => _open(context, const ConsumablesScreen()),
              ),
              const Divider(),
              _MenuTile(
                icon: Icons.schema_rounded,
                title: 'سبک‌ها و نقش‌ها',
                subtitle: 'راهنمای فارسی ساختار جدید FC27',
                onTap: () => _open(context, const Fc27ReferenceScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.primary.withValues(alpha: .18)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_outlined),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'FCBaz هیچ داده نمایشی یا ساختگی نشان نمی‌دهد. اگر منبع معتبر یک بخش در دسترس نباشد، همان بخش خالی یا غیرفعال نمایش داده می‌شود.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget screen) {
    AppNavigator.push(context, screen);
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

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_left_rounded),
    );
  }
}
