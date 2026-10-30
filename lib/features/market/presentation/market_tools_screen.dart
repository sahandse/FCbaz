import 'package:flutter/material.dart';

import '../../players/domain/player.dart';
import '../../players/domain/player_value_analysis.dart';
import '../domain/purchase_value.dart';
import 'package:fcbaz/src/app_dependencies.dart';
import 'package:fcbaz/src/navigation/app_navigator.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';
import 'market_tax_calculator_panel.dart';

class MarketToolsScreen extends StatefulWidget {
  const MarketToolsScreen({super.key});

  @override
  State<MarketToolsScreen> createState() => _MarketToolsScreenState();
}

class _MarketToolsScreenState extends State<MarketToolsScreen>
    with SingleTickerProviderStateMixin {
  final marketRepository = AppDependencies.instance.market;
  final playerRepository = AppDependencies.instance.players;

  late final TabController tabController;
  List<Player> cheapest = const [];
  List<Player> popular = const [];
  List<PurchaseValue> valueRanked = const [];
  bool loadingCheapest = true;
  bool loadingPopular = true;
  bool loadingValue = true;
  String? cheapestError;
  String? popularError;
  String? valueError;
  int rating = 85;
  int valueMinRating = 85;
  String platform = 'console';

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadCheapest(), _loadPopular(), _loadValue()]);
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

  PlayerMarketPlatform get _marketPlatform =>
      platform == 'pc' ? PlayerMarketPlatform.pc : PlayerMarketPlatform.console;

  Future<void> _loadValue() async {
    setState(() {
      loadingValue = true;
      valueError = null;
    });
    try {
      final data = await marketRepository.getCheapestPlayers(
        minRating: valueMinRating,
        maxRating: 99,
        platform: platform,
      );
      if (!mounted) return;
      final ranked = const PurchaseValueAnalyzer().rank(
        data,
        platform: _marketPlatform,
        minRating: valueMinRating,
      );
      setState(() => valueRanked = ranked.take(30).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        valueRanked = const [];
        valueError = e.toString();
      });
    } finally {
      if (mounted) setState(() => loadingValue = false);
    }
  }

  int _price(Player player) =>
      platform == 'pc' ? player.pricePc : player.pricePs;

  String _coins(int value) {
    if (value <= 0) return 'قیمت ناموجود';
    if (value >= 1000000) {
      return faDigits('${(value / 1000000).toStringAsFixed(1)}M');
    }
    if (value >= 1000) {
      return faDigits(
        '${(value / 1000).toStringAsFixed(value >= 100000 ? 0 : 1)}K',
      );
    }
    return faDigits(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ابزارهای بازار'),
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'ارزان‌ترین بر اساس ریتینگ'),
            Tab(text: 'ارزش خرید'),
            Tab(text: 'محبوب‌ترین بازیکنان'),
            Tab(text: 'مالیات و سود'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _buildCheapest(),
          _buildValue(),
          _buildPopular(),
          const MarketTaxCalculatorPanel(),
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
          Text(
            'Cheapest by Rating',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'ارزان‌ترین کارت‌های واقعی بازار برای ساخت SBC؛ بدون قیمت یا بازیکن ساختگی.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
              _loadValue();
            },
          ),
          const SizedBox(height: 18),
          _AnimatedState(
            child: loadingCheapest
                ? const _ToolsListSkeleton(key: ValueKey('cheapest-loading'))
                : cheapestError != null
                ? _StateCard(
                    key: const ValueKey('cheapest-error'),
                    title: 'داده بازار در دسترس نیست',
                    subtitle: cheapestError!,
                    action: _loadCheapest,
                  )
                : cheapest.isEmpty
                ? _StateCard(
                    key: const ValueKey('cheapest-empty'),
                    title: 'قیمت معتبری پیدا نشد',
                    subtitle:
                        'برای این ریتینگ و پلتفرم، منبع واقعی فعلاً نتیجه‌ای برنگرداند.',
                    action: _loadCheapest,
                  )
                : Column(
                    key: const ValueKey('cheapest-list'),
                    children: [
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
          ),
        ],
      ),
    );
  }

  Widget _buildValue() {
    final palette = context.palette;
    return RefreshIndicator(
      onRefresh: _loadValue,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Text(
            'Value to Buy',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'ارزش خرید از قیمت واقعی همان پلتفرم تقسیم بر ریتینگ ساخته می‌شود؛ کارت بدون قیمت واقعی کنار گذاشته می‌شود و عدد جایگزین ساخته نمی‌شود.',
            style: TextStyle(color: palette.textMuted, height: 1.7),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in [85, 86, 87, 88, 89, 90])
                ChoiceChip(
                  label: Text('${faDigits(value)}+'),
                  selected: valueMinRating == value,
                  onSelected: (_) {
                    setState(() => valueMinRating = value);
                    _loadValue();
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
              _loadValue();
            },
          ),
          const SizedBox(height: 18),
          _AnimatedState(
            child: loadingValue
                ? const _ToolsListSkeleton(key: ValueKey('value-loading'))
                : valueError != null
                ? _StateCard(
                    key: const ValueKey('value-error'),
                    title: 'داده ارزش خرید در دسترس نیست',
                    subtitle: valueError!,
                    action: _loadValue,
                  )
                : valueRanked.isEmpty
                ? _StateCard(
                    key: const ValueKey('value-empty'),
                    title: 'قیمت معتبری پیدا نشد',
                    subtitle:
                        'برای ریتینگ ${faDigits(valueMinRating)}+ و این پلتفرم، منبع واقعی کارتی با قیمت برنگرداند.',
                    action: _loadValue,
                  )
                : Column(
                    key: const ValueKey('value-list'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < valueRanked.length; i++) ...[
                        _ValueRow(value: valueRanked[i], rank: i + 1),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        '«سکه/رنکینگ» قیمت تقسیم بر ریتینگ است؛ «فروش سربه‌سر» قیمتی است که پس از ۵٪ مالیات فروش، پول خرید را برمی‌گرداند.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.7,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
          ),
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
          Text(
            'بازیکنان محبوب',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'لیست محبوب‌ترین بازیکنان از منبع زنده؛ ترتیب توسط منبع داده تعیین می‌شود.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          _AnimatedState(
            child: loadingPopular
                ? const _ToolsListSkeleton(key: ValueKey('popular-loading'))
                : popularError != null
                ? _StateCard(
                    key: const ValueKey('popular-error'),
                    title: 'داده محبوب‌ترین‌ها در دسترس نیست',
                    subtitle: popularError!,
                    action: _loadPopular,
                  )
                : popular.isEmpty
                ? _StateCard(
                    key: const ValueKey('popular-empty'),
                    title: 'داده‌ای دریافت نشد',
                    subtitle:
                        'به‌جای نمایش داده نمایشی، این بخش خالی نگه داشته شده است.',
                    action: _loadPopular,
                  )
                : Column(
                    key: const ValueKey('popular-list'),
                    children: [
                      for (var i = 0; i < popular.length; i++) ...[
                        _PlayerRow(
                          player: popular[i],
                          rank: i + 1,
                          trailing: popular[i].version.isEmpty
                              ? popular[i].position
                              : popular[i].version,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedState extends StatelessWidget {
  const _AnimatedState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}

class _ToolsListSkeleton extends StatelessWidget {
  const _ToolsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      label: 'در حال بارگذاری ابزارهای بازار',
      child: Column(
        children: [
          for (var i = 0; i < 5; i++)
            Container(
              height: 74,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    palette.surface,
                    palette.surfaceRaised,
                    palette.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(FcbazRadius.md),
                border: Border.all(color: palette.line),
              ),
            ),
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
        onTap: () => AppNavigator.playerDetails(context, player),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '#${faDigits(rank)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              CircleAvatar(
                radius: 25,
                backgroundImage: player.imageUrl.isEmpty
                    ? null
                    : NetworkImage(player.imageUrl),
                child: player.imageUrl.isEmpty
                    ? Text(faDigits(player.rating))
                    : null,
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
                      '${faDigits(player.rating)} • ${player.position}${player.clubName.isEmpty ? '' : ' • ${player.clubName}'}',
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
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.value, required this.rank});

  final PurchaseValue value;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final player = value.player;
    final perRating = value.coinsPerRating;
    final breakEven = value.taxAdjustedPrice;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => AppNavigator.playerDetails(context, player),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '#${faDigits(rank)}',
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              CircleAvatar(
                radius: 23,
                backgroundImage: player.imageUrl.isEmpty
                    ? null
                    : NetworkImage(player.imageUrl),
                child: player.imageUrl.isEmpty
                    ? Text(faDigits(player.rating))
                    : null,
              ),
              const SizedBox(width: 10),
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
                    const SizedBox(height: 2),
                    Text(
                      'ریتینگ ${faDigits(value.rating)} • ${player.position}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    if (perRating != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'سکه/رنکینگ: ${formatCoinsFa(perRating.round())}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: palette.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    if (breakEven != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'فروش سربه‌سر پس از ۵٪ مالیات: ${formatCoinsFa(breakEven)}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: palette.textMuted,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    compactCoinsFa(value.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.platform == PlayerMarketPlatform.pc ? 'PC' : 'PS',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: palette.textMuted,
                    ),
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

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.subtitle,
    this.action,
    super.key,
  });

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
            Icon(
              Icons.cloud_off_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: action,
                child: const Text('تلاش دوباره'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
