import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onOpenPlayers,
    required this.onOpenSearch,
    required this.onOpenSquad,
    required this.onOpenMore,
    super.key,
  });

  final VoidCallback onOpenPlayers;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenSquad;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _HeroCard(onPlayers: onOpenPlayers, onSearch: onOpenSearch),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'دسترسی سریع',
          subtitle: 'ابزارهای اصلی Ultimate Team',
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.65,
          children: [
            _QuickAction(
              title: 'بازیکنان',
              subtitle: 'دیتابیس و فیلترها',
              icon: Icons.groups_2_rounded,
              onTap: onOpenPlayers,
            ),
            _QuickAction(
              title: 'تیم‌ساز',
              subtitle: 'Squad + Chemistry',
              icon: Icons.stadium_rounded,
              onTap: onOpenSquad,
            ),
            _QuickAction(
              title: 'جستجو',
              subtitle: 'بازیکن و کارت',
              icon: Icons.search_rounded,
              onTap: onOpenSearch,
            ),
            _QuickAction(
              title: 'بازار و ابزارها',
              subtitle: 'SBC، Evo و قیمت',
              icon: Icons.query_stats_rounded,
              onTap: onOpenMore,
            ),
          ],
        ),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'وضعیت داده',
          subtitle: 'FCBaz اطلاعات ساختگی را جایگزین داده واقعی نمی‌کند',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.primary.withValues(alpha: .22)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.verified_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('فقط داده واقعی FC27', style: TextStyle(fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text('اگر منبع در دسترس نباشد، وضعیت خطا یا عدم اتصال نمایش داده می‌شود.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onPlayers, required this.onSearch});
  final VoidCallback onPlayers;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            scheme.primary.withValues(alpha: .19),
            scheme.secondary.withValues(alpha: .08),
            scheme.surface,
          ],
        ),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'FC27 • Ultimate Team',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'FCBaz',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'نسخه فارسی، سریع و مینیمال برای بازیکنان، قیمت‌ها، تیم‌ساز، SBC و Evolutions.',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.6),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPlayers,
                  icon: const Icon(Icons.groups_2_rounded),
                  label: const Text('بازیکنان'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: onSearch,
                icon: const Icon(Icons.search_rounded),
                tooltip: 'جستجو',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 9),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
