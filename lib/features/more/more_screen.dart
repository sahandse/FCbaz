import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('SBC', Icons.extension_rounded),
      ('Evolutions', Icons.auto_awesome_rounded),
      ('مقایسه بازیکنان', Icons.compare_arrows_rounded),
      ('آموزش FC27', Icons.school_rounded),
      ('تنظیمات', Icons.settings_rounded),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('بیشتر', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        for (final item in items)
          Card(
            child: ListTile(
              leading: Icon(item.$2, color: Theme.of(context).colorScheme.primary),
              title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_left_rounded),
            ),
          ),
      ],
    );
  }
}
