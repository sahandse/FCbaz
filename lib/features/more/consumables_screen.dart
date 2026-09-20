import 'package:flutter/material.dart';

class ConsumablesScreen extends StatelessWidget {
  const ConsumablesScreen({super.key});

  static const chemistryStyles = [
    _Style('Basic', 'Balanced'),
    _Style('Sniper', 'SHO + PHY'),
    _Style('Finisher', 'SHO + DRI'),
    _Style('Deadeye', 'SHO + PAS'),
    _Style('Marksman', 'SHO + DRI + PHY'),
    _Style('Hawk', 'PAC + SHO + PHY'),
    _Style('Artist', 'PAS + DRI'),
    _Style('Architect', 'PAS + PHY'),
    _Style('Powerhouse', 'PAS + DEF'),
    _Style('Maestro', 'SHO + PAS + DRI'),
    _Style('Engine', 'PAC + PAS + DRI'),
    _Style('Sentinel', 'DEF + PHY'),
    _Style('Guardian', 'DRI + DEF'),
    _Style('Gladiator', 'SHO + DEF'),
    _Style('Backbone', 'PAS + DEF + PHY'),
    _Style('Anchor', 'PAC + DEF + PHY'),
    _Style('Hunter', 'PAC + SHO'),
    _Style('Catalyst', 'PAC + PAS'),
    _Style('Shadow', 'PAC + DEF'),
    _Style('GK Basic', 'Balanced GK'),
    _Style('Wall', 'GK'),
    _Style('Shield', 'GK'),
    _Style('Cat', 'GK'),
    _Style('Glove', 'GK'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consumables')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Consumables در Ultimate Team',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            'FCBaz فقط اطلاعات کاربردی و مستند را نمایش می‌دهد؛ قیمت زنده Consumable چون منبع فعلی آن را ارائه نمی‌کند نمایش داده نمی‌شود.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          const _InfoCard(
            icon: Icons.healing_rounded,
            title: 'Healing',
            subtitle: 'برای درمان Player Item آسیب‌دیده.',
          ),
          const SizedBox(height: 8),
          const _InfoCard(
            icon: Icons.auto_fix_high_rounded,
            title: 'Chemistry Styles',
            subtitle:
                'برای تقویت گروه‌های مشخصی از Attributeها بر اساس Chemistry.',
          ),
          const SizedBox(height: 8),
          const _InfoCard(
            icon: Icons.badge_outlined,
            title: 'Manager Leagues',
            subtitle:
                'برای تغییر League مدیر و کمک به Squad Chemistry.',
          ),
          const SizedBox(height: 22),
          Text(
            'Chemistry Styles FC27',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '۲۴ Style شامل ۱۹ سبک بازیکن و ۵ سبک دروازه‌بان',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chemistryStyles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              childAspectRatio: 1.65,
            ),
            itemBuilder: (_, index) {
              final item = chemistryStyles[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.focus,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Style {
  const _Style(this.name, this.focus);
  final String name;
  final String focus;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}
