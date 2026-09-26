import 'package:flutter/material.dart';

import '../../players/data/player_repository.dart';
import '../../players/domain/player.dart';
import '../../players/presentation/player_details_screen.dart';
import '../data/market_repository.dart';

class MarketToolsScreen extends StatefulWidget {
  const MarketToolsScreen({super.key});

  @override
  State<MarketToolsScreen> createState() => _MarketToolsScreenState();
}

class _MarketToolsScreenState extends State<MarketToolsScreen>
    with SingleTickerProviderStateMixin {
  final marketRepository = MarketRepository();
  final playerRepository = PlayerRepository();

  late final TabController tabController;
  List<Player> cheapest = const [];
  List<Player> popular = const [];
  bool loadingCheapest = true;
  bool loadingPopular = true;
  String? cheapestError;
  String? popularError;
  int rating = 85;
  String platform = 'console';

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadCheapest(), _loadPopular()]);
  }

  Future<void> _loadCheapest() async {
    setState(() {
      loadingCheapest = true;
      cheapestError = null;
    });
    try {
      final data = await marketRepository.getCheapestPlayers(
        minRating: rating,
        maxRating: rating,
        platform: platform,
      );
      if (!mounted) return;
      setState(() => cheapest = data.take(30).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => cheapestError = e.toString());
    } finally {
      if (mounted) setState(() => loadingCheapest = false);
    }
  }

  Future<void> _loadPopular() async {
    setState(() {
      loadingPopular = true;
      popularError = null;
    });
    try {
      final data = await playerRepository.getTrendingPlayers();
      if (!mounted) return;
      setState(() => popular = data.take(30).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => popularError = e.toString());
    } finally {
      if (mounted) setState(() => loadingPopular = false);
    }
  }

  int _price(Player player) => platform == 'pc' ? player.pricePc : player.pricePs;

  String _coins(int value) {
    if (value <= 0) return 'قیمت ناموجود';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(value >= 100000 ? 0 : 1)}K';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ابزارهای بازار'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'ارزان‌ترین بر اساس ریتینگ'),
            Tab(text: 'محبوب‌ترین بازیکنان'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _buildCheapest(),
          _buildPopular(),
        ],
      ),
    );
  }

  Widget _buildCheapest() {
    return RefreshIndicator(
      onRefresh: _loadCheapest,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Text('Cheapest by Rating', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'ارزان‌ترین کارت‌های واقعی بازار برای ساخت SBC؛ بدون قیمت یا بازیکن ساختگی.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in [82, 83, 84, 85, 86, 87, 88, 89, 90])
                ChoiceChip(
                  label: Text(value.toString()),
                  selected: rating == value,
                  onSelected: (_) {
                    setState(() => rating = value);
                    _loadCheapest();
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'console', label: Text('کنسول')),
              ButtonSegment(value: 'pc', label: Text('PC')),
            ],
            selected: {platform},
            onSelectionChanged: (value) {
              setState(() => platform = value.first);
              _loadCheapest();
            },
          ),
          const SizedBox(height: 18),
          if (loadingCheapest)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (cheapestError != null)
            _StateCard(
              title: 'داده بازار در دسترس نیست',
              subtitle: cheapestError!,
              action: _loadCheapest,
            )
          else if (cheapest.isEmpty)
            const _StateCard(
              title: 'قیمت معتبری پیدا نشد',
              subtitle: 'برای این ریتینگ و پلتفرم، منبع واقعی فعلاً نتیجه‌ای برنگرداند.',
            )
          else
            for (var i = 0; i < cheapest.length; i++) ...[
              _PlayerRow(
                player: cheapest[i],
                rank: i + 1,
                trailing: _coins(_price(cheapest[i])),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildPopular() {
    return RefreshIndicator(
      onRefresh: _loadPopular,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Text('بازیکنان محبوب', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'لیست محبوب‌ترین بازیکنان از منبع زنده؛ ترتیب توسط منبع داده تعیین می‌شود.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          if (loadingPopular)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (popularError != null)
            _StateCard(
              title: 'داده محبوب‌ترین‌ها در دسترس نیست',
              subtitle: popularError!,
              action: _loadPopular,
            )
          else if (popular.isEmpty)
            const _StateCard(
              title: 'داده‌ای دریافت نشد',
              subtitle: 'به‌جای نمایش داده نمایشی، این بخش خالی نگه داشته شده است.',
            )
          else
            for (var i = 0; i < popular.length; i++) ...[
              _PlayerRow(
                player: popular[i],
                rank: i + 1,
                trailing: popular[i].version.isEmpty ? popular[i].position : popular[i].version,
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.rank,
    required this.trailing,
  });

  final Player player;
  final int rank;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: player)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              CircleAvatar(
                radius: 25,
                backgroundImage: player.imageUrl.isEmpty ? null : NetworkImage(player.imageUrl),
                child: player.imageUrl.isEmpty ? Text(player.rating.toString()) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${player.rating} • ${player.position}${player.clubName.isEmpty ? '' : ' • ${player.clubName}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                trailing,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, color: Theme.of(context).colorScheme.primary, size: 38),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: action, child: const Text('تلاش دوباره')),
            ],
          ],
        ),
      ),
    );
  }
}
