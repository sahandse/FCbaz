import 'package:flutter/material.dart';

import '../../market/data/market_repository.dart';
import '../../players/domain/player.dart';
import '../domain/sbc_rating_tools.dart';

class SbcToolsScreen extends StatefulWidget {
  const SbcToolsScreen({super.key});

  @override
  State<SbcToolsScreen> createState() => _SbcToolsScreenState();
}

class _SbcToolsScreenState extends State<SbcToolsScreen> {
  final marketRepository = MarketRepository();
  final calculator = const SbcRatingCalculator();

  int targetRating = 84;
  String platform = 'console';
  bool loading = false;
  String? error;
  Map<int, Player> cheapestByRating = const {};
  List<SbcRatingCombination> combinations = const [];

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

    final minRating = (targetRating - 5).clamp(75, 95);
    final maxRating = (targetRating + 5).clamp(75, 95);
    final found = <int, Player>{};

    try {
      for (var rating = minRating; rating <= maxRating; rating++) {
        final players = await marketRepository.getCheapestPlayers(
          minRating: rating,
          maxRating: rating,
          platform: platform,
        );
        if (players.isEmpty) continue;

        final priced = players.where((player) => _price(player) > 0).toList()
          ..sort((a, b) => _price(a).compareTo(_price(b)));
        if (priced.isNotEmpty) found[rating] = priced.first;
      }

      final prices = <int, int>{
        for (final entry in found.entries) entry.key: _price(entry.value),
      };

      final result = calculator.combinations(
        targetRating: targetRating,
        minCardRating: minRating,
        maxCardRating: maxRating,
        cheapestPriceByRating: prices,
      );

      if (!mounted) return;
      setState(() {
        cheapestByRating = found;
        combinations = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  int _price(Player player) => platform == 'pc' ? player.pricePc : player.pricePs;

  String _coins(int value) {
    if (value >= 1000000) {
      final amount = value / 1000000;
      return '${amount.toStringAsFixed(amount >= 10 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final amount = value / 1000;
      return '${amount.toStringAsFixed(amount >= 100 ? 0 : 1)}K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ابزارهای SBC')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Text(
              'Rating Combination و فودر ارزان',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 5),
            Text(
              'ترکیب امتیاز به‌صورت محلی محاسبه می‌شود؛ قیمت فقط از کارت‌های واقعی بازار خوانده می‌شود.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            _Fc27Notice(),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: targetRating,
                    decoration: const InputDecoration(labelText: 'ریتینگ هدف'),
                    items: [
                      for (var rating = 75; rating <= 95; rating++)
                        DropdownMenuItem(
                          value: rating,
                          child: Text(rating.toString()),
                        ),
                    ],
                    onChanged: loading
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => targetRating = value);
                            _load();
                          },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 132,
                  child: DropdownButtonFormField<String>(
                    initialValue: platform,
                    decoration: const InputDecoration(labelText: 'بازار'),
                    items: const [
                      DropdownMenuItem(value: 'console', child: Text('کنسول')),
                      DropdownMenuItem(value: 'pc', child: Text('رایانه')),
                    ],
                    onChanged: loading
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => platform = value);
                            _load();
                          },
                  ),
                ),
              ],
            ),
            if (loading) ...[
              const SizedBox(height: 18),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (error != null) ...[
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: const Text('دیتای قیمت کامل در دسترس نیست'),
                  subtitle: Text(error!),
                  trailing: IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text('ارزان‌ترین کارت واقعی هر ریتینگ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 9),
            if (!loading && cheapestByRating.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.price_check_rounded),
                  title: Text('قیمت واقعی پیدا نشد'),
                  subtitle: Text('تا زمان دریافت داده بازار، قیمت یا هزینه تخمینی ساخته نمی‌شود.'),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in cheapestByRating.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key)))
                    _FodderCard(
                      rating: entry.key,
                      player: entry.value,
                      price: _price(entry.value),
                      coins: _coins,
                    ),
                ],
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ترکیب‌های مناسب برای $targetRating',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text('${combinations.length} حالت')),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'هزینه فقط زمانی نمایش داده می‌شود که برای تمام ریتینگ‌های استفاده‌شده قیمت واقعی موجود باشد.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            if (!loading && combinations.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.calculate_outlined),
                  title: Text('ترکیبی پیدا نشد'),
                  subtitle: Text('ریتینگ هدف یا محدوده کارت‌ها را دوباره بررسی کن.'),
                ),
              )
            else
              for (var i = 0; i < combinations.length; i++) ...[
                _CombinationCard(
                  index: i + 1,
                  combination: combinations[i],
                  coins: _coins,
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

class _Fc27Notice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'در FC27 بعضی SBCها با Item Score انجام می‌شوند. این ابزار Rating Combination فقط برای SBCهای سنتی/Puzzle است و برای Item Score مقدار حدسی تولید نمی‌کند.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FodderCard extends StatelessWidget {
  const _FodderCard({
    required this.rating,
    required this.player,
    required this.price,
    required this.coins,
  });

  final int rating;
  final Player player;
  final int price;
  final String Function(int value) coins;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 158,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    rating.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Text(
                    '${coins(price)} سکه',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                player.version.isEmpty ? player.position : '${player.position} • ${player.version}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CombinationCard extends StatelessWidget {
  const _CombinationCard({
    required this.index,
    required this.combination,
    required this.coins,
  });

  final int index;
  final SbcRatingCombination combination;
  final String Function(int value) coins;

  @override
  Widget build(BuildContext context) {
    final entries = combination.counts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(radius: 18, child: Text(index.toString())),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in entries)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${entry.value}× ${entry.key}'),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ریتینگ ${combination.squadRating}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  combination.estimatedCost == null
                      ? 'هزینه نامشخص'
                      : '${coins(combination.estimatedCost!)} سکه',
                  style: TextStyle(
                    color: combination.estimatedCost == null
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
