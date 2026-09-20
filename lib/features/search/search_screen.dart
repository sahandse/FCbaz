import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('جستجو', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        const TextField(
          decoration: InputDecoration(
            hintText: 'نام بازیکن، باشگاه یا لیگ...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
      ],
    );
  }
}
