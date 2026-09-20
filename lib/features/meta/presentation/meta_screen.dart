import 'package:flutter/material.dart';

import '../data/meta_repository.dart';

class MetaScreen extends StatefulWidget {
  const MetaScreen({super.key});

  @override
  State<MetaScreen> createState() => _MetaScreenState();
}

class _MetaScreenState extends State<MetaScreen> {
  final repository = MetaRepository();

  String? position;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> items = const [];

  static const positions = ['ST', 'LW', 'RW', 'CAM', 'CM', 'CDM', 'CB', 'LB', 'RB', 'GK'];

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
      final data = await repository.getBestPlayers(position: position);
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
      (item[key] ?? '—').toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meta Players')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'بهترین بازیکنان متا',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('همه'),
                    selected: position == null,
                    onSelected: (_) {
                      setState(() => position = null);
                      _load();
                    },
                  ),
                  const SizedBox(width: 7),
                  for (final p in positions) ...[
                    ChoiceChip(
                      label: Text(p),
                      selected: position == p,
                      onSelected: (_) {
                        setState(() => position = p);
                        _load();
                      },
                    ),
                    const SizedBox(width: 7),
                  ],
                ],
              ),
            ),
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
                  title: const Text('Meta data در دسترس نیست'),
                  subtitle: Text(error!),
                ),
              )
            else if (items.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.leaderboard_outlined),
                  title: Text('داده‌ای پیدا نشد'),
                  subtitle: Text('رتبه‌بندی فقط از Backend واقعی نمایش داده می‌شود.'),
                ),
              )
            else
              for (var i = 0; i < items.length; i++) ...[
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text((i + 1).toString()),
                    ),
                    title: Text(
                      _value(items[i], 'name'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      _value(items[i], 'position') +
                          ' • ' +
                          _value(items[i], 'rating') +
                          ' • ' +
                          _value(items[i], 'reason'),
                    ),
                    trailing: Text(
                      _value(items[i], 'price'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
          ],
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
