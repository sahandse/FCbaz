import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../club/data/my_club_repository.dart';
import '../../club/presentation/add_club_player_dialog.dart';
import '../../evolutions/domain/evolution.dart';
import '../../market/presentation/player_market_panel.dart';
import '../../sbc/domain/sbc.dart';
import '../../../src/theme/fcbaz_theme.dart';
import '../../../src/ui/segmented_tabs.dart';
import '../../../src/ui/section_header.dart';
import '../../../src/ui/source_badge.dart';
import '../../../src/utils/persian_formatters.dart';
import '../data/player_review_repository.dart';
import '../domain/chemistry_style_advisor.dart';
import '../domain/player.dart';
import 'card/player_card_theme.dart';
import 'player_item_visual.dart';
import 'widgets/player_usage_panel.dart';
import 'package:fcbaz/src/app_dependencies.dart';
import 'package:fcbaz/src/navigation/app_navigator.dart';

part 'widgets/player_details_card_visuals.dart';
part 'widgets/player_details_market_stats.dart';
part 'widgets/player_details_info.dart';
part 'widgets/player_details_actions.dart';

class PlayerDetailsScreen extends StatefulWidget {
  const PlayerDetailsScreen({required this.player, super.key});
  final Player player;

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['نمای کلی', 'آمار', 'استایل‌ها', 'بازار', 'یادداشت'];

  final repository = AppDependencies.instance.players;
  final reviewRepository = AppDependencies.instance.reviews;
  final clubRepository = AppDependencies.instance.club;
  final historyRepository = AppDependencies.instance.history;
  final evolutionRepository = AppDependencies.instance.evolutions;
  final sbcRepository = AppDependencies.instance.sbc;
  final chemistryAdvisor = const ChemistryStyleAdvisor();

  late final TabController tabController;
  late Player player = widget.player;
  PlayerReview? review;
  List<Player> versions = const [];
  List<Evolution> evolutions = const [];
  List<SbcChallenge> sbcChallenges = const [];
  bool loading = true;
  bool loadingUsage = true;
  bool favorite = false;
  bool inClub = false;
  bool savingClub = false;
  String? detailError;
  String? evolutionsError;
  String? sbcError;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: _tabs.length, vsync: this);
    _load();
    _loadReview();
    _loadFavorite();
    _loadClubStatus();
    _loadUsage();
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

  Future<void> _loadUsage() async {
    if (!loadingUsage && mounted) setState(() => loadingUsage = true);
    await Future.wait([_loadEvolutions(), _loadSbcs()]);
    if (mounted) setState(() => loadingUsage = false);
  }

  Future<void> _loadEvolutions() async {
    try {
      final items = await evolutionRepository.getActive();
      if (!mounted) return;
      setState(() {
        evolutions = items;
        evolutionsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => evolutionsError = e.toString());
    }
  }

  Future<void> _loadSbcs() async {
    try {
      final items = await sbcRepository.getActive();
      if (!mounted) return;
      setState(() {
        sbcChallenges = items;
        sbcError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => sbcError = e.toString());
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _load(),
      _loadReview(),
      _loadFavorite(),
      _loadClubStatus(),
      _loadUsage(),
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
    AppNavigator.compare(context, player);
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
    AppNavigator.replace(context, PlayerDetailsScreen(player: version));
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
              const SizedBox(height: FcbazSpace.xl),
              const SectionHeader(
                kicker: 'WHERE IT IS USED',
                title: 'کجا استفاده می‌شود',
              ),
              const SizedBox(height: 10),
              PlayerUsagePanel(
                player: player,
                loading: loadingUsage,
                evolutions: evolutions,
                sbcChallenges: sbcChallenges,
                evolutionsError: evolutionsError,
                sbcError: sbcError,
                onRetry: _loadUsage,
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
