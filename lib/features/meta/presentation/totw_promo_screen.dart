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
  String scoutTitle = 'هایلایت رایگان GitHub';
  List<Player> highlights = const [];
  List<Map<String, dynamic>> news = const [];
  List<Map<String, dynamic>> scoutLists = const [];
  String selectedList = 'fastest';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final lists = await metaRepo.freeContent.scoutLists();
      final newsItems = await metaRepo.getNews();
      final scout = await metaRepo.getScoutHighlight(
        listId: selectedList,
        limit: 24,
      );
      var cards = scout;
      if (cards.isEmpty) {
        cards = await playersRepo.getTrendingPlayers();
      }
      if (!mounted) return;
      final matched = lists.where((e) => (e['id'] ?? '').toString() == selectedList);
      final title = matched.isEmpty
          ? null
          : (matched.first['title'] ?? '').toString();
      setState(() {
        scoutLists = lists;
        news = newsItems;
        highlights = cards.take(24).toList();
        scoutTitle =
            (title != null && title.isNotEmpty) ? title : 'هایلایت رایگان GitHub';
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
              'لیست‌های رایگان از GitHub (EAFC26-DataHub) به‌همراه راهنماهای FCBaz. قیمت جعلی ساخته نمی‌شود.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (scoutLists.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in scoutLists)
                    ChoiceChip(
                      label: Text('${item['title'] ?? item['id']}'),
                      selected: selectedList == '${item['id']}',
                      onSelected: (_) async {
                        setState(() => selectedList = '${item['id']}');
                        await _load();
                      },
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Text(scoutTitle, style: Theme.of(context).textTheme.titleLarge),
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
                    '${player.rating} • ${player.position} • ${player.clubName}',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerDetailsScreen(player: player),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text('اخبار و راهنما', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (news.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.newspaper_rounded),
                  title: Text('خبری نیست'),
                ),
              ),
            for (final item in news)
              Card(
                child: ListTile(
                  title: Text('${item['title'] ?? item['name'] ?? 'خبر'}'),
                  subtitle: Text(
                    '${item['summary'] ?? item['description'] ?? ''}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
