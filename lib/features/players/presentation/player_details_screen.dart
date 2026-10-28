import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../club/data/my_club_repository.dart';
import '../../club/presentation/add_club_player_dialog.dart';
import '../../market/presentation/player_market_panel.dart';
import '../../search/search_history_repository.dart';
import '../../../src/theme/fcbaz_theme.dart';
import '../../../src/ui/segmented_tabs.dart';
import '../../../src/ui/section_header.dart';
import '../../../src/ui/source_badge.dart';
import '../../../src/utils/persian_formatters.dart';
import '../data/player_repository.dart';
import '../data/player_review_repository.dart';
import '../domain/chemistry_style_advisor.dart';
import '../domain/player.dart';
import 'card/player_card_theme.dart';
import 'player_compare_screen.dart';
import 'player_item_visual.dart';

class PlayerDetailsScreen extends StatefulWidget {
  const PlayerDetailsScreen({required this.player, super.key});
  final Player player;

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['نمای کلی', 'آمار', 'استایل‌ها', 'بازار', 'یادداشت'];

  final repository = PlayerRepository();
  final reviewRepository = PlayerReviewRepository();
  final clubRepository = MyClubRepository();
  final historyRepository = SearchHistoryRepository();
  final chemistryAdvisor = const ChemistryStyleAdvisor();

  late final TabController tabController;
  late Player player = widget.player;
  PlayerReview? review;
  List<Player> versions = const [];
  bool loading = true;
  bool favorite = false;
  bool inClub = false;
  bool savingClub = false;
  String? detailError;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: _tabs.length, vsync: this);
    _load();
    _loadReview();
    _loadFavorite();
    _loadClubStatus();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      detailError = null;
    });
    try {
      final results = await Future.wait([
        repository.getPlayer(widget.player.id),
        repository.getVersions(widget.player.id),
      ]);
      if (!mounted) return;
      final loaded = results[0] as Player;
      setState(() {
        player = loaded;
        versions = (results[1] as List<Player>)
            .where((p) => p.id != loaded.id)
            .toList();
      });
    } catch (e) {
      if (mounted) setState(() => detailError = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadReview() async {
    final data = await reviewRepository.get(widget.player.id);
    if (mounted) setState(() => review = data);
  }

  Future<void> _loadFavorite() async {
    final value = await historyRepository.isFavorite(widget.player.id);
    if (mounted) setState(() => favorite = value);
  }

  Future<void> _loadClubStatus() async {
    final ids = await clubRepository.getPlayerIds();
    if (mounted) setState(() => inClub = ids.contains(widget.player.id));
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _load(),
      _loadReview(),
      _loadFavorite(),
      _loadClubStatus(),
    ]);
  }

  Future<void> _toggleFavorite() async {
    await historyRepository.toggleFavorite(player);
    if (!mounted) return;
    setState(() => favorite = !favorite);
  }

  Future<void> _copyPlayer() async {
    final parts = [
      player.name,
      player.rating > 0 ? '${player.rating}' : '',
      player.position,
      player.clubName,
      player.leagueName,
      player.nationName,
    ].where((value) => value.trim().isNotEmpty).join(' • ');
    await Clipboard.setData(ClipboardData(text: parts));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('اطلاعات کارت کپی شد.')));
  }

  Future<void> _addToClub() async {
    if (inClub) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('این کارت در باشگاه شماست.')),
      );
      return;
    }
    if (savingClub) return;

    final result = await AddClubPlayerDialog.show(context, player);
    if (result == null || !mounted) return;
    setState(() => savingClub = true);
    try {
      await clubRepository.upsert(
        MyClubItem.fromPlayer(
          player,
          acquisitionPrice: result.price,
          untradeable: result.untradeable,
        ),
      );
      if (!mounted) return;
      setState(() => inClub = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('کارت به باشگاه اضافه شد.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ذخیره در باشگاه ممکن نشد: $e')));
    } finally {
      if (mounted) setState(() => savingClub = false);
    }
  }

  void _compare() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerCompareScreen(initialPlayers: [player]),
      ),
    );
  }

  Future<void> _editReview() async {
    var rating = review?.rating ?? 5;
    final controller = TextEditingController(text: review?.text ?? '');
    final result = await showDialog<(int, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(player.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setDialogState(() => rating = i),
                      icon: Icon(
                        i <= rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'یادداشت شخصی'),
              ),
            ],
          ),
          actions: [
            if (review != null)
              TextButton(
                onPressed: () => Navigator.pop(context, (0, '')),
                child: const Text('حذف'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, (rating, controller.text.trim())),
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result == null) return;
    if (result.$1 == 0) {
      await reviewRepository.remove(player.id);
    } else {
      await reviewRepository.save(
        playerId: player.id,
        rating: result.$1,
        text: result.$2,
      );
    }
    await _loadReview();
  }

  void _openVersion(Player version) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: version)),
    );
  }

  List<(String, int)> get _faceStats => player.position.toUpperCase() == 'GK'
      ? [
          ('DIV', player.inGameStats['DIV'] ?? 0),
          ('HAN', player.inGameStats['HAN'] ?? 0),
          ('KIC', player.inGameStats['KIC'] ?? 0),
          ('REF', player.inGameStats['REF'] ?? 0),
          ('SPD', player.inGameStats['SPD'] ?? 0),
          ('POS', player.inGameStats['POS'] ?? 0),
        ]
      : [
          ('PAC', player.pace),
          ('SHO', player.shooting),
          ('PAS', player.passing),
          ('DRI', player.dribbling),
          ('DEF', player.defending),
          ('PHY', player.physical),
        ];

  Color _rarityTint(BuildContext context) {
    final theme = PlayerCardTheme.forPlayer(player);
    return Theme.of(context).brightness == Brightness.dark
        ? theme.glow
        : theme.accent;
  }

  Widget _tabBody(String key, List<Widget> children) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        key: PageStorageKey(key),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = _rarityTint(context);
    final chem = chemistryAdvisor.suggest(player);
    final playStyles = [
      for (final item in player.playStylesPlus) '$item +',
      ...player.playStyles,
    ];

    return Scaffold(
      backgroundColor: palette.canvas,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 336,
            backgroundColor: palette.canvas,
            surfaceTintColor: Colors.transparent,
            foregroundColor: palette.text,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'بازگشت',
            ),
            actions: [
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                color: favorite ? palette.danger : null,
                tooltip: favorite
                    ? 'حذف از علاقه‌مندی‌ها'
                    : 'افزودن به علاقه‌مندی‌ها',
              ),
              IconButton(
                onPressed: _copyPlayer,
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'کپی اطلاعات کارت',
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1.15,
              collapseMode: CollapseMode.parallax,
              titlePadding: const EdgeInsetsDirectional.only(
                start: 56,
                end: 16,
                bottom: 14,
              ),
              title: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                ),
              ),
              background: _CardBackdrop(player: player, tint: tint),
            ),
          ),
          SliverToBoxAdapter(
            child: _Identity(
              player: player,
              loading: loading,
              detailError: detailError,
              onRetry: _load,
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabsDelegate(
              background: palette.canvas,
              line: palette.line,
              child: SegmentedTabs(controller: tabController, tabs: _tabs),
            ),
          ),
        ],
        body: TabBarView(
          controller: tabController,
          children: [
            _tabBody('overview', [
              SectionHeader(
                kicker: 'PRICE',
                title: 'قیمت بازار',
                actionLabel: 'بازار',
                onAction: () => tabController.animateTo(3),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PriceCell(label: 'PS', value: player.pricePs),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PriceCell(label: 'PC', value: player.pricePc),
                  ),
                ],
              ),
              if (player.pricePs <= 0 && player.pricePc <= 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'قیمت این کارت هنوز از منبع بازار خوانده نشده است.',
                    style: TextStyle(fontSize: 11, color: palette.textMuted),
                  ),
                ),
              const SizedBox(height: FcbazSpace.xl),
              const SectionHeader(
                kicker: 'FACE STATS',
                title: 'شاخص‌های کلیدی',
              ),
              const SizedBox(height: 10),
              _StatBars(stats: _faceStats),
              const SizedBox(height: FcbazSpace.xl),
              const SectionHeader(
                kicker: 'CHEMISTRY STYLE',
                title: 'استایل شیمیایی پیشنهادی',
              ),
              const SizedBox(height: 10),
              if (chem.isEmpty)
                const _EmptyLine('پیشنهاد شیمیایی برای این کارت موجود نیست.')
              else
                for (var i = 0; i < chem.length && i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: _InfoCard(
                      icon: Icons.bolt_rounded,
                      title: chem[i].name,
                      subtitle: chem[i].reason,
                    ),
                  ),
              const SizedBox(height: FcbazSpace.xl),
              const SectionHeader(kicker: 'ROLES', title: 'نقش‌ها'),
              const SizedBox(height: 10),
              if (player.roles.isEmpty)
                const _EmptyLine('نقشی برای این کارت ثبت نشده است.')
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final role in player.roles) Chip(label: Text(role)),
                  ],
                ),
              const SizedBox(height: FcbazSpace.xl),
              const SectionHeader(
                kicker: 'OTHER VERSIONS',
                title: 'نسخه‌های دیگر',
              ),
              const SizedBox(height: 10),
              if (versions.isEmpty)
                const _EmptyLine('نسخه دیگری از این کارت ثبت نشده است.')
              else
                SizedBox(
                  height: 202,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: versions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) => GestureDetector(
                      onTap: () => _openVersion(versions[index]),
                      child: SizedBox(
                        width: 145,
                        height: 202,
                        child: PlayerItemVisual(
                          player: versions[index],
                          compact: true,
                          showPrices: true,
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
            _tabBody('stats', [
              const SectionHeader(kicker: 'FACE STATS', title: 'آمار چهره'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faceStats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 7,
                  crossAxisSpacing: 7,
                  childAspectRatio: 1.45,
                ),
                itemBuilder: (_, index) => _StatTile(
                  label: _faceStats[index].$1,
                  value: _faceStats[index].$2,
                ),
              ),
              if (player.inGameStats.isNotEmpty) ...[
                const SizedBox(height: FcbazSpace.xl),
                const SectionHeader(kicker: 'IN-GAME', title: 'آمار داخل بازی'),
                const SizedBox(height: 10),
                _InGameStats(values: player.inGameStats),
              ],
              const SizedBox(height: FcbazSpace.xl),
              const SectionHeader(kicker: 'ITEM INFO', title: 'اطلاعات کارت'),
              const SizedBox(height: 10),
              _InfoGrid(player: player),
            ]),
            _tabBody('styles', [
              const SectionHeader(
                kicker: 'PLAYSTYLES',
                title: 'استایل‌های بازی',
              ),
              const SizedBox(height: 10),
              if (playStyles.isEmpty)
                const _EmptyLine('استایل بازی برای این کارت ثبت نشده است.')
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final item in player.playStylesPlus)
                      Chip(
                        avatar: const Icon(Icons.stars_rounded, size: 15),
                        label: Text('$item +'),
                      ),
                    for (final item in player.playStyles)
                      Chip(label: Text(item)),
                  ],
                ),
              const SizedBox(height: FcbazSpace.xl),
              const SectionHeader(kicker: 'ROLES', title: 'نقش‌ها'),
              const SizedBox(height: 10),
              if (player.roles.isEmpty)
                const _EmptyLine('نقشی برای این کارت ثبت نشده است.')
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final role in player.roles) Chip(label: Text(role)),
                  ],
                ),
              if (player.traits.isNotEmpty) ...[
                const SizedBox(height: FcbazSpace.xl),
                const SectionHeader(kicker: 'TRAITS', title: 'ویژگی‌ها'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final trait in player.traits) Chip(label: Text(trait)),
                  ],
                ),
              ],
            ]),
            _tabBody('market', [
              const SectionHeader(kicker: 'MARKET', title: 'بازار کارت'),
              const SizedBox(height: 6),
              Text(
                'قیمت، تاریخچه و هشدار فقط از منبع عمومی بازار خوانده می‌شوند؛ اگر تاریخچه‌ای موجود نباشد جایگزین جعلی ساخته نمی‌شود.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.6,
                  color: palette.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              PlayerMarketPanel(playerId: player.id, playerName: player.name),
            ]),
            _tabBody('review', [
              const SectionHeader(kicker: 'MY REVIEW', title: 'یادداشت من'),
              const SizedBox(height: 10),
              _ReviewCard(review: review),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _editReview,
                icon: const Icon(Icons.edit_note_rounded, size: 20),
                label: Text(review == null ? 'ثبت یادداشت' : 'ویرایش یادداشت'),
              ),
              const SizedBox(height: 10),
              Text(
                'یادداشت شخصی فقط روی همین دستگاه ذخیره می‌شود.',
                style: TextStyle(fontSize: 11, color: palette.textMuted),
              ),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActions(
        inClub: inClub,
        saving: savingClub,
        onAdd: _addToClub,
        onCompare: _compare,
      ),
    );
  }
}

class _CardBackdrop extends StatelessWidget {
  const _CardBackdrop({required this.player, required this.tint});

  final Player player;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(tint.withValues(alpha: .22), palette.canvas),
                palette.canvas,
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: 58,
          start: 0,
          end: 0,
          child: Center(
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    tint.withValues(alpha: .30),
                    tint.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 64,
          start: 0,
          end: 0,
          child: Center(
            child: Hero(
              tag: playerHeroTag(player.id),
              child: SizedBox(
                width: 140,
                height: 200,
                child: PlayerItemVisual(player: player, showPrices: false),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.player,
    required this.loading,
    required this.detailError,
    required this.onRetry,
  });

  final Player player;
  final bool loading;
  final String? detailError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final version = player.version.isNotEmpty
        ? player.version
        : (player.rarity.isNotEmpty ? player.rarity : player.cardType);
    final meta = [
      player.clubName,
      player.leagueName,
      player.nationName,
    ].where((value) => value.trim().isNotEmpty).join(' • ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLAYER ITEM',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: 'BarlowCondensed',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.2,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(FcbazRadius.md),
                ),
                child: Text(
                  player.rating > 0 ? faDigits(player.rating) : '—',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    height: 1,
                    color: palette.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_value(player.position)}'
                      '${version.isEmpty ? '' : ' • $version'}',
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.isEmpty ? 'باشگاه، لیگ و ملیت ثبت نشده' : meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SourceBadge(
            source: 'FC27 Catalog',
            note: 'قیمت‌ها در تب بازار از منبع بازار خوانده می‌شوند.',
          ),
          if (loading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(minHeight: 2),
            ),
          ],
          if (detailError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.cloud_off_rounded, size: 17, color: palette.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'جزئیات کامل در دسترس نیست.',
                    style: TextStyle(fontSize: 11, color: palette.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('تلاش دوباره'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _value(String value) => value.trim().isEmpty ? '—' : value;
}

class _PriceCell extends StatelessWidget {
  const _PriceCell({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.md),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: 'BarlowCondensed',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            compactCoinsFa(value),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontFamily: 'BarlowCondensed',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              height: 1,
              color: palette.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Coins',
            textDirection: TextDirection.ltr,
            style: TextStyle(fontSize: 10, color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StatBars extends StatelessWidget {
  const _StatBars({required this.stats});

  final List<(String, int)> stats;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        for (var i = 0; i < stats.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == stats.length - 1 ? 0 : 9),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    stats[i].$1,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: palette.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stats[i].$2 <= 0
                          ? 0
                          : (stats[i].$2 / 99).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: palette.surfaceRaised,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    stats[i].$2 > 0 ? faDigits(stats[i].$2) : '—',
                    textAlign: TextAlign.end,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InGameStats extends StatelessWidget {
  const _InGameStats({required this.values});
  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (_, index) =>
          _StatTile(label: entries[index].key, value: entries[index].value),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.sm),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value > 0 ? faDigits(value) : '—',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: palette.primary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              height: 1.1,
            ),
          ),
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 10.5,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    final data = <(String, String)>[
      ('CLUB', player.clubName),
      ('LEAGUE', player.leagueName),
      ('NATION', player.nationName),
      ('VERSION', player.version.isNotEmpty ? player.version : player.rarity),
      ('SKILLS', player.skillMoves > 0 ? '${player.skillMoves}★' : '—'),
      ('WEAK FOOT', player.weakFoot > 0 ? '${player.weakFoot}★' : '—'),
      ('FOOT', player.foot),
      ('HEIGHT', player.height),
      ('WORK RATES', player.workRates),
      ('RARITY', player.rarity),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 7,
      crossAxisSpacing: 7,
      childAspectRatio: 2.2,
      children: [
        for (final item in data)
          _MiniInfo(label: item.$1, value: item.$2.isEmpty ? '—' : item.$2),
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surfaceRaised.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.sm),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: palette.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final PlayerReview? review;

  @override
  Widget build(BuildContext context) {
    if (review == null) {
      return const _InfoCard(
        icon: Icons.rate_review_outlined,
        title: 'هنوز نظری ثبت نشده',
        subtitle: 'نظر شخصی فقط روی دستگاه ذخیره می‌شود.',
      );
    }
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.sm),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review!.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 19,
                  color: palette.primary,
                ),
            ],
          ),
          if (review!.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review!.text, style: const TextStyle(height: 1.6)),
          ],
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(FcbazRadius.sm),
        border: Border.all(color: palette.line),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 11.5, color: palette.textMuted),
      ),
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate({
    required this.child,
    required this.background,
    required this.line,
  });

  final Widget child;
  final Color background;
  final Color line;

  @override
  double get minExtent => SegmentedTabs.height + 1;

  @override
  double get maxExtent => SegmentedTabs.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _TabsDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.background != background ||
      oldDelegate.line != line;
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.inClub,
    required this.saving,
    required this.onAdd,
    required this.onCompare,
  });

  final bool inClub;
  final bool saving;
  final VoidCallback onAdd;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCompare,
                  icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                  label: const Text('مقایسه'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: saving ? null : onAdd,
                  style: inClub
                      ? FilledButton.styleFrom(
                          backgroundColor: palette.surfaceRaised,
                          foregroundColor: palette.primary,
                          side: BorderSide(color: palette.line),
                        )
                      : null,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          inClub ? Icons.check_rounded : Icons.add_rounded,
                          size: 18,
                        ),
                  label: Text(inClub ? 'در باشگاه' : 'افزودن به باشگاه'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
