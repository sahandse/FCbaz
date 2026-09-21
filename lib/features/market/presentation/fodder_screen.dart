import 'package:flutter/material.dart';

import '../../players/data/player_repository.dart';
import '../../players/domain/player.dart';
import '../../players/presentation/player_details_screen.dart';
import '../../players/presentation/player_portrait.dart';
import '../../settings/app_settings_repository.dart';

/// Cheapest players by rating tier (fodder board).
class FodderScreen extends StatefulWidget {
  const FodderScreen({super.key});

  @override
  State<FodderScreen> createState() => _FodderScreenState();
}

class _FodderScreenState extends State<FodderScreen> {
  final repository = PlayerRepository();
  final settingsRepository = AppSettingsRepository();

  String platform = 'console';
  int rating = 84;
  bool loading = true;
  String? error;
  List<Player> players = const [];

  static const tiers = [81, 82, 83, 84, 85, 86, 87, 88, 89, 90];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final settings = await settingsRepository.load();
    if (!mounted) return;
    setState(() => platform = settings.defaultPlatform);
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await repository.advanced(
        PlayerFilter(
          minRating: rating,
          maxRating: rating,
          platform: platform,
          sort: PlayerSort.priceAsc,
        ),
      );
      if (!mounted) return;
      final pc = platform == 'pc';
      final sorted = List<Player>.from(result.players);
      sorted.sort((a, b) {
        final ap = pc ? a.pricePc : a.pricePs;
        final bp = pc ? b.pricePc : b.pricePs;
        if (ap <= 0 && bp > 0) return 1;
        if (bp <= 0 && ap > 0) return -1;
        if (ap == bp) return b.rating.compareTo(a.rating);
        return ap.compareTo(bp);
      });
      setState(() => players = sorted.take(30).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _coins(int value) {
    if (value <= 0) return '—';
    if (value >= 1000000) {
      final n = value / 1000000;
      return n.toStringAsFixed(n >= 10 ? 0 : 1) + 'M';
    }
    if (value >= 1000) {
      final n = value / 1000;
      return n.toStringAsFixed(n >= 100 ? 0 : 1) + 'K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fodder / ارزان‌ترین‌ها')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              'ارزان‌ترین کارت‌ها برای هر ریتینگ — مناسب SBC و ترید.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tier in tiers)
                  ChoiceChip(
                    label: Text('$tier'),
                    selected: rating == tier,
                    onSelected: (_) async {
                      setState(() => rating = tier);
                      await _load();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'console', label: Text('Console')),
                ButtonSegment(value: 'pc', label: Text('PC')),
              ],
              selected: {platform},
              onSelectionChanged: (value) async {
                setState(() => platform = value.first);
                await _load();
              },
            ),
            const SizedBox(height: 16),
            if (loading) const Center(child: CircularProgressIndicator()),
            if (error != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: const Text('بارگذاری نشد'),
                  subtitle: Text(error!),
                ),
              ),
            if (!loading && error == null && players.isEmpty)
              const Card(
                child: ListTile(
                  title: Text('بازیکنی پیدا نشد'),
                  subtitle: Text(
                    'اگر قیمت زنده در دسترس نباشد، لیست بر اساس ریتینگ می‌آید ولی مرتب‌سازی قیمت ممکن است خالی باشد.',
                  ),
                ),
              ),
            for (final player in players)
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
                  trailing: Text(
                    _coins(platform == 'pc' ? player.pricePc : player.pricePs),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerDetailsScreen(player: player),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
