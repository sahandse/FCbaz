import 'package:flutter/material.dart';

import '../../players/data/player_repository.dart';
import '../../players/domain/player.dart';
import '../../players/presentation/player_details_screen.dart';
import '../../players/presentation/player_portrait.dart';
import '../data/meta_repository.dart';

class TotwPromoScreen extends StatefulWidget {
  const TotwPromoScreen({super.key});

  @override
  State<TotwPromoScreen> createState() => _TotwPromoScreenState();
}

class _TotwPromoScreenState extends State<TotwPromoScreen> {
  final playersRepo = PlayerRepository();
  final metaRepo = MetaRepository();

  bool loading = true;
  List<Player> highlights = const [];
  List<Map<String, dynamic>> news = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final trending = await playersRepo.getTrendingPlayers();
      final newsItems = await metaRepo.getNews();
      if (!mounted) return;
      setState(() {
        highlights = trending.take(20).toList();
        news = newsItems;
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TOTW / Promo / News')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              'هایلایت کارت‌های داغ و اخبار پرومو. اگر منبع خبر زنده نباشد، لیست خبر خالی می‌ماند.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text('کارت‌های داغ / Meta', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (loading) const Center(child: CircularProgressIndicator()),
            if (!loading && highlights.isEmpty)
              const Card(
                child: ListTile(title: Text('هایلایتی در دسترس نیست')),
              ),
            for (final player in highlights)
              Card(
                child: ListTile(
                  leading: PlayerPortrait(
                    player: player,
                    width: 48,
                    height: 48,
                    borderRadius: 12,
                  ),
                  title: Text(player.name),
                  subtitle: Text(
                    '${player.rating} • ${player.position} • ${player.version}',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerDetailsScreen(player: player),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text('اخبار', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (news.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.newspaper_rounded),
                  title: Text('خبر زنده‌ای نیست'),
                  subtitle: Text(
                    'وقتی منبع News پیکربندی شود، Promo و TOTW اینجا می‌آیند.',
                  ),
                ),
              ),
            for (final item in news)
              Card(
                child: ListTile(
                  title: Text('${item['title'] ?? item['name'] ?? 'خبر'}'),
                  subtitle: Text('${item['summary'] ?? item['description'] ?? ''}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
