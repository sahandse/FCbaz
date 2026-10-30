import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../club/data/my_club_repository.dart';
import '../../players/domain/player.dart';
import '../../../src/theme/fcbaz_theme.dart';
import '../domain/sbc_rating_tools.dart';
import '../domain/sbc_shopping_list.dart';
import 'sbc_club_solver_card.dart';
import 'sbc_shopping_list_sheet.dart';
import 'package:fcbaz/src/app_dependencies.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';

class SbcToolsScreen extends StatefulWidget {
  const SbcToolsScreen({super.key});

  @override
  State<SbcToolsScreen> createState() => _SbcToolsScreenState();
}

class _SbcToolsScreenState extends State<SbcToolsScreen> {
  final marketRepository = AppDependencies.instance.market;
  final clubRepository = AppDependencies.instance.club;
  final calculator = const SbcRatingCalculator();
  final budgetController = TextEditingController();

  int targetRating = 84;
  String platform = 'console';
  bool loading = false;
  String? error;
  Map<int, Player> cheapestByRating = const {};
  List<SbcRatingCombination> combinations = const [];
  List<MyClubItem> clubItems = const [];
  int? budget;

  @override
  void initState() {
    super.initState();
    _loadClub();
    _load();
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadClub() async {
    final items = await clubRepository.getAll();
    if (!mounted) return;
    setState(() => clubItems = items);
  }

  Future<void> _refresh() async {
    await _loadClub();
    await _load();
  }

  Map<int, int> get _ownedCountByRating {
    final counts = <int, int>{};
    for (final item in clubItems) {
      counts.update(item.rating, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    final minRating = (targetRating - 5).clamp(75, 95).toInt();
    final maxRating = (targetRating + 5).clamp(75, 95).toInt();
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
        ownedCountByRating: _ownedCountByRating,
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

  int _price(Player player) =>
      platform == 'pc' ? player.pricePc : player.pricePs;

  SbcShoppingList _shoppingListFor(SbcRatingCombination combination) {
    return SbcShoppingList.build(
      targetRating: targetRating,
      combination: combination,
      candidates: {
        for (final entry in cheapestByRating.entries)
          entry.key: SbcShoppingCandidate(
            playerId: entry.value.id,
            playerName: entry.value.name,
            price: _price(entry.value),
          ),
      },
      platform: platform,
      ownedCountByRating: _ownedCountByRating,
      budget: budget,
    );
  }

  void _openShoppingList(SbcShoppingList list, int index) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SbcShoppingListSheet(
        list: list,
        title: 'لیست خرید ترکیب ${faDigits(index)}',
      ),
    );
  }

  String _coins(int value) {
    if (value >= 1000000) {
      final amount = value / 1000000;
      return faDigits('${amount.toStringAsFixed(amount >= 10 ? 0 : 1)}M');
    }
    if (value >= 1000) {
      final amount = value / 1000;
      return faDigits('${amount.toStringAsFixed(amount >= 100 ? 0 : 1)}K');
    }
    return faDigits(value);
  }

  @override
  Widget build(BuildContext context) {
    final shoppingLists = [
      for (final combination in combinations) _shoppingListFor(combination),
    ];
    final affordableCount = budget == null
        ? null
        : shoppingLists.where((list) => list.withinBudget).length;
    final completeCount = shoppingLists
        .where((list) => list.hasCompletePrices)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('ابزارهای SBC')),
      body: RefreshIndicator(
        onRefresh: _refresh,
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
            const _Fc27Notice(),
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
                          child: Text(faDigits(rating)),
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
            const SizedBox(height: 10),
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩,٬\s]')),
              ],
              decoration: InputDecoration(
                labelText: 'بودجه (سکه) — اختیاری',
                prefixIcon: const Icon(Icons.savings_outlined),
                helperText:
                    'مقایسه بودجه فقط وقتی انجام می‌شود که همه ردیف‌های خرید قیمت واقعی داشته باشند.',
                suffixIcon: budget == null
                    ? null
                    : IconButton(
                        tooltip: 'پاک کردن بودجه',
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          budgetController.clear();
                          setState(() => budget = null);
                        },
                      ),
              ),
              onChanged: (value) =>
                  setState(() => budget = parsePersianInt(value)),
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
            SbcClubSolverCard(items: clubItems, targetRating: targetRating),
            const SizedBox(height: 18),
            Text(
              'ارزان‌ترین کارت واقعی هر ریتینگ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 9),
            if (!loading && cheapestByRating.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.price_check_rounded),
                  title: Text('قیمت واقعی پیدا نشد'),
                  subtitle: Text(
                    'تا زمان دریافت داده بازار، قیمت یا هزینه تخمینی ساخته نمی‌شود.',
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry
                      in cheapestByRating.entries.toList()
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
                    'ترکیب‌های مناسب برای ${faDigits(targetRating)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text('${faDigits(combinations.length)} حالت')),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'هزینه خرید فقط زمانی نمایش داده می‌شود که برای ریتینگ‌های خریدنی قیمت واقعی موجود باشد. کارت‌های ثبت‌شده در کلوب از تعداد خرید کم می‌شوند.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (budget != null && combinations.isNotEmpty) ...[
              const SizedBox(height: 10),
              _BudgetSummaryCard(
                budget: budget!,
                affordableCount: affordableCount ?? 0,
                completeCount: completeCount,
                totalCount: combinations.length,
                coins: _coins,
              ),
            ],
            const SizedBox(height: 10),
            if (!loading && combinations.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.calculate_outlined),
                  title: Text('ترکیبی پیدا نشد'),
                  subtitle: Text(
                    'ریتینگ هدف یا محدوده کارت‌ها را دوباره بررسی کن.',
                  ),
                ),
              )
            else
              for (var i = 0; i < combinations.length; i++) ...[
                _CombinationCard(
                  index: i + 1,
                  combination: combinations[i],
                  shoppingList: shoppingLists[i],
                  coins: _coins,
                  onOpenList: () => _openShoppingList(shoppingLists[i], i + 1),
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
  const _Fc27Notice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
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
                    faDigits(rating),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${coins(price)} سکه',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
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
                player.version.isEmpty
                    ? player.position
                    : '${player.position} • ${player.version}',
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
    required this.shoppingList,
    required this.coins,
    required this.onOpenList,
  });

  final int index;
  final SbcRatingCombination combination;
  final SbcShoppingList shoppingList;
  final String Function(int value) coins;
  final VoidCallback onOpenList;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    final success = context.palette.success;
    final entries = combination.counts.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final list = shoppingList;

    final (Color, IconData, String)? badge = list.budget == null
        ? null
        : list.isEmpty
        ? (success, Icons.check_circle_outline_rounded, 'همه از کلوب')
        : !list.hasCompletePrices
        ? (
            palette.onSurfaceVariant,
            Icons.help_outline_rounded,
            'مقایسه با بودجه ناممکن',
          )
        : list.withinBudget
        ? (
            success,
            Icons.savings_rounded,
            'در بودجه · ${coins(list.remainingBudget!)} باقی',
          )
        : (
            palette.error,
            Icons.trending_down_rounded,
            'کمبود ${coins(list.shortfall!)} سکه',
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 18, child: Text(faDigits(index))),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final entry in entries)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(faDigits('${entry.value}× ${entry.key}')),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ریتینگ ${faDigits(combination.squadRating)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      list.hasCompletePrices
                          ? '${coins(list.knownCost)} سکه'
                          : '${coins(list.knownCost)} + ${faDigits(list.unpricedCount)} بدون قیمت',
                      style: TextStyle(
                        color: list.hasCompletePrices
                            ? palette.primary
                            : palette.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (badge != null)
                  Flexible(
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(badge.$2, size: 15, color: badge.$1),
                      label: Text(
                        badge.$3,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badge.$1,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onOpenList,
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  label: const Text('لیست خرید'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    required this.budget,
    required this.affordableCount,
    required this.completeCount,
    required this.totalCount,
    required this.coins,
  });

  final int budget;
  final int affordableCount;
  final int completeCount;
  final int totalCount;
  final String Function(int value) coins;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: palette.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                completeCount == 0
                    ? 'برای هیچ ترکیبی قیمت کامل در دسترس نیست؛ بنابراین مقایسه با بودجه ${coins(budget)} سکه انجام نمی‌شود.'
                    : '$affordableCount از $totalCount ترکیب با قیمت کامل داخل بودجه ${coins(budget)} سکه‌اند.'
                          '${completeCount < totalCount ? ' ${faDigits(totalCount - completeCount)} ترکیب قیمت کامل ندارند.' : ''}',
                style: const TextStyle(fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
