import 'package:flutter/material.dart';

class PlayersScreen extends StatelessWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('بازیکنان FC27', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            hintText: 'جستجوی بازیکن...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.cloud_off_rounded, size: 42, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                const Text('داده بازیکنان هنوز متصل نشده است', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text(
                  'این صفحه برای دریافت داده واقعی FC27 از Backend آماده شده و از اطلاعات ساختگی استفاده نمی‌کند.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
