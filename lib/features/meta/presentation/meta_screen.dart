import 'package:flutter/material.dart';

import '../../players/presentation/player_details_screen.dart';
import '../data/meta_repository.dart';
import '../domain/meta_player_entry.dart';

class MetaScreen extends StatefulWidget {
  const MetaScreen({super.key});

  @override
  State<MetaScreen> createState() => _MetaScreenState();
}

class _MetaScreenState extends State<MetaScreen> {
  final repository = MetaRepository();

  String? position;
  String? role;
  String platform = 'console';
  bool loading = true;
  String? error;
  List<MetaPlayerEntry> items = const [];

  static const positions = [
    'ST',
    'LW',
    'RW',
    'CAM',
    'CM',
    'CDM',
    'CB',
    'LB',
    'RB',
    'GK',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await repository.getBestPlayers(
        position: position,
        role: role,
        platform: platform,
      );
      if (!mounted) return;
      setState(() => items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<String> get availableRoles {
    final roles = <String>{};
    for (final item in items) {
      if (item.role.isNotEmpty) roles.add(item.role);
      roles.addAll(item.player.roles.where((e) => e.trim().isNotEmpty));
    }
    final out = roles.toList()..sort();
    return out;
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
    final hasVerifiedMeta = items.any((e) => e.isVerifiedMeta);
    return Scaffold(
      appBar: AppBar(title: const Text('بازیکنان متا')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              hasVerifiedMeta ? 'بازیکنان متای FC27' : 'بالاترین ریتینگ‌های FC27',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 5),
            Text(
              hasVerifiedMeta
                  ? 'رتبه، Tier و دلیل فقط وقتی نمایش داده می‌شوند که Backend متا آن‌ها را برگرداند.'
                  : 'منبع متا در دسترس نیست؛ این لیست صرفاً از داده واقعی بازیکنان و مرتب‌سازی ریتینگ ساخته شده و رتبه متا محسوب نمی‌شود.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'console', label: Text('کنسول')),
                ButtonSegment(value: 'pc', label: Text('رایانه')),
              ],
              selected: {platform},
              onSelectionChanged: (value) {
                setState(() => platform = value.first);
                _load();
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('همه پست‌ها'),
                    selected: position == null,
                    onSelected: (_) {
                      setState(() {
                        position = null;
                        role = null;
                      });
                      _load();
                    },
                  ),
                  const SizedBox(width: 7),
                  for (final p in positions) ...[
                    ChoiceChip(
                      label: Text(p),
                      selected: position == p,
                      onSelected: (_) {
                        setState(() {
                          position = p;
                          role = null;
                        });
                        _load();
                      },
                    ),
                    const SizedBox(width: 7),
                  ],
                ],
              ),
            ),
            if (availableRoles.isNotEmpty) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                value: availableRoles.contains(role) ? role : null,
                decoration: const InputDecoration(
                  labelText: 'نقش بازیکن',
                  prefixIcon: Icon(Icons.schema_rounded),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('همه نقش‌ها'),
                  ),
                  for (final item in availableRoles)
                    DropdownMenuItem<String?>(value: item, child: Text(item)),
                ],
                onChanged: (value) {
                  setState(() => role = value);
                  _load();
                },
              ),
            ],
            const SizedBox(height: 16),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: const Text('داده بازیکنان در دسترس نیست'),
                  subtitle: Text(error!),
                  trailing: IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              )
            else if (items.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.leaderboard_outlined),
                  title: Text('بازیکنی برای این فیلتر پیدا نشد'),
                ),
              )
            else
              for (final entry in items) ...[
                _MetaPlayerCard(
                  entry: entry,
                  platform: platform,
                  coins: _coins,
                ),
                const SizedBox(height: 9),
              ],
          ],
        ),
      ),
    );
  }
}

class _MetaPlayerCard extends StatelessWidget {
  const _MetaPlayerCard({
    required this.entry,
    required this.platform,
    required this.coins,
  });

  final MetaPlayerEntry entry;
  final String platform;
  final String Function(int) coins;

  @override
  Widget build(BuildContext context) {
    final player = entry.player;
    final price = platform == 'pc' ? player.pricePc : player.pricePs;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerDetailsScreen(player: player),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 27,
                backgroundImage:
                    player.imageUrl.isEmpty ? null : NetworkImage(player.imageUrl),
                child: player.imageUrl.isEmpty
                    ? Text(player.rating.toString())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (entry.isVerifiedMeta && entry.rank != null)
                          Chip(label: Text('#${entry.rank}')),
                      ],
                    ),
                    Text(
                      '${player.rating} • ${player.position} • ${player.clubName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (entry.isVerifiedMeta &&
                        (entry.tier.isNotEmpty || entry.role.isNotEmpty)) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (entry.tier.isNotEmpty)
                            Chip(label: Text('Tier ${entry.tier}')),
                          if (entry.role.isNotEmpty)
                            Chip(label: Text(entry.role)),
                          if (entry.score != null)
                            Chip(label: Text('امتیاز ${entry.score!.toStringAsFixed(1)}')),
                        ],
                      ),
                    ],
                    if (entry.isVerifiedMeta && entry.reason.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(entry.reason),
                    ],
                    if (!entry.isVerifiedMeta) ...[
                      const SizedBox(height: 7),
                      Text(
                        'مرتب‌شده بر اساس ریتینگ واقعی کارت؛ این مورد رتبه متا نیست.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    coins(price),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    platform == 'pc' ? 'PC' : 'Console',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final repository = MetaRepository();
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await repository.getNews();
      if (!mounted) return;
      setState(() => items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _value(Map<String, dynamic> item, String key) =>
      (item[key] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اخبار FC27')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 72),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: const Text('اخبار در دسترس نیست'),
                  subtitle: Text(error!),
                ),
              )
            else if (items.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.newspaper_rounded),
                  title: Text('خبر جدیدی نیست'),
                  subtitle: Text('Promo، SBC، Evolution و تغییرات FC27 اینجا نمایش داده می‌شوند.'),
                ),
              )
            else
              for (final item in items) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _value(item, 'title'),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _value(item, 'summary'),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_value(item, 'published_at').isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            _value(item, 'published_at'),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}
