import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onOpenPlayers, super.key});

  final VoidCallback onOpenPlayers;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                primary.withValues(alpha: .20),
                Theme.of(context).colorScheme.surface,
              ],
            ),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('همه چیز درباره FC27',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                'بازیکنان، کارت‌ها، SBC، Evolutions و تیم‌ساز در یک تجربه فارسی و مینیمال.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onOpenPlayers,
                icon: const Icon(Icons.groups_2_rounded),
                label: const Text('مشاهده بازیکنان'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('دسترسی سریع', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        const _QuickGrid(),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: Icon(Icons.verified_user_rounded, color: primary),
            title: const Text('داده واقعی FC27', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('FCBaz داده ساختگی را به‌عنوان اطلاعات واقعی نمایش نمی‌دهد.'),
          ),
        ),
      ],
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('بازیکنان', Icons.groups_2_rounded),
      ('SBC', Icons.extension_rounded),
      ('Evolutions', Icons.auto_awesome_rounded),
      ('مقایسه', Icons.compare_arrows_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (_, i) {
        final item = items[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.$2, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        );
      },
    );
  }
}
