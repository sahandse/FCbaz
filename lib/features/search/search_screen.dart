import 'dart:async';

import 'package:flutter/material.dart';

import '../players/data/player_repository.dart';
import '../players/domain/player.dart';
import '../players/presentation/player_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final repository = PlayerRepository();
  final controller = TextEditingController();
  Timer? debounce;
  List<Player> results = const [];
  bool loading = false;
  String? error;

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    debounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      setState(() {
        results = const [];
        error = null;
        loading = false;
      });
      return;
    }

    debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await repository.search(query);
      if (!mounted || controller.text.trim() != query) return;
      setState(() => results = data);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        results = const [];
        error = e.toString();
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = controller.text.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        Text(
          'جستجوی بازیکن',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'حداقل دو حرف از نام بازیکن...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      controller.clear();
                      _onChanged('');
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (query.length < 2)
          const _SearchMessage(
            icon: Icons.manage_search_rounded,
            title: 'جستجوی سریع FC27',
            subtitle: 'نام بازیکن را به فارسی یا انگلیسی وارد کن.',
          )
        else if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 64),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (error != null)
          _SearchMessage(
            icon: Icons.cloud_off_rounded,
            title: 'جستجو در دسترس نیست',
            subtitle: error!,
          )
        else if (results.isEmpty)
          const _SearchMessage(
            icon: Icons.search_off_rounded,
            title: 'نتیجه‌ای پیدا نشد',
            subtitle: 'املای نام را بررسی کن یا عبارت دیگری جستجو کن.',
          )
        else ...[
          Text(
            results.length.toString() + ' نتیجه',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final player in results) ...[
            PlayerCard(player: player),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
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
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
