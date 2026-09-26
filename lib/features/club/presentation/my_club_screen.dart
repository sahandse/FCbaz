import 'package:flutter/material.dart';

import '../../evolutions/presentation/evolutions_screen.dart';
import '../../players/data/player_repository.dart';
import '../../players/domain/player.dart';
import '../../players/presentation/player_details_screen.dart';
import '../../players/presentation/player_item_visual.dart';
import '../../squad/data/squad_repository.dart';
import '../../squad/domain/squad_models.dart';
import '../../squad/squad_screen.dart';
import '../../settings/app_settings_repository.dart';
import '../data/my_club_repository.dart';
import '../domain/club_inventory_analysis.dart';
import '../my_club_service.dart';

class MyClubScreen extends StatefulWidget {
  const MyClubScreen({super.key});
  @override
  State<MyClubScreen> createState() => _MyClubScreenState();
}

class _MyClubScreenState extends State<MyClubScreen> {
  final clubRepository = MyClubRepository();
  final playerRepository = PlayerRepository();
  final clubService = MyClubService();
  final squadRepository = SquadRepository();
  final settingsRepository = AppSettingsRepository();
  final inventoryAnalysis = const ClubInventoryAnalysis();
  final searchController = TextEditingController();

  String platform = 'console';
  List<MyClubItem> items = const [];
  ClubValuation? valuation;
  BestClubSquad? bestSquad;
  ClubInventoryFilter filter = const ClubInventoryFilter();
  bool loading = true;
  bool loadingValue = false;
  String? valueError;

  List<MyClubItem> get visibleItems => inventoryAnalysis.filter(items, filter);
  List<ClubDuplicateGroup> get duplicates => inventoryAnalysis.duplicateGroups(items);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final settings = await settingsRepository.load();
    if (!mounted) return;
    setState(() => platform = settings.defaultPlatform);
    await _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final data = await clubRepository.getAll();
    if (!mounted) return;
    setState(() {
      items = data;
      bestSquad = clubService.buildBestSquad(data);
      loading = false;
    });
    await _refreshValue(forceRefresh: forceRefresh);
  }

  Future<void> _refreshValue({bool forceRefresh = false}) async {
    if (items.isEmpty) {
      if (mounted) setState(() => valuation = null);
      return;
    }
    setState(() {
      loadingValue = true;
      valueError = null;
    });
    try {
      final data = await clubService.valueClub(items, platform: platform, forceRefresh: forceRefresh);
      if (mounted) setState(() => valuation = data);
    } catch (e) {
      if (mounted) setState(() => valueError = e.toString());
    } finally {
      if (mounted) setState(() => loadingValue = false);
    }
  }

  Future<void> _addPlayer() async {
    List<Player> players;
    try {
      players = await playerRepository.getPlayers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
    if (!mounted) return;
    final selected = await showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PlayerPicker(players: players),
    );
    if (selected == null || !mounted) return;

    final result = await showDialog<_AddResult>(context: context, builder: (_) => _AddDialog(player: selected));
    if (result == null) return;
    await clubRepository.upsert(MyClubItem.fromPlayer(selected, acquisitionPrice: result.price, untradeable: result.untradeable));
    await _load();
  }

  Future<void> _remove(String playerId) async {
    await clubRepository.remove(playerId);
    await _load();
  }

  Future<void> _saveBestSquad() async {
    final best = bestSquad;
    if (best == null) return;
    await squadRepository.upsert(SquadStateModel(
      id: 'club_best_${DateTime.now().millisecondsSinceEpoch}',
      name: 'بهترین ترکیب باشگاه من',
      formationId: best.formation.id,
      playersBySlot: {for (final entry in best.playersBySlot.entries) entry.key: entry.value.toPlayer()},
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ترکیب در تیم‌ساز ذخیره شد')));
  }

  ClubPlayerValue? _valueFor(String id) {
    for (final value in valuation?.players ?? const <ClubPlayerValue>[]) {
      if (value.item.playerId == id) return value;
    }
    return null;
  }

  String _coins(int value) {
    if (value <= 0) return '—';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(value >= 100000 ? 0 : 1)}K';
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final visible = visibleItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MY CLUB'),
        actions: [
          IconButton(onPressed: loadingValue ? null : () => _refreshValue(forceRefresh: true), icon: const Icon(Icons.refresh_rounded), tooltip: 'بروزرسانی قیمت'),
          IconButton(onPressed: _addPlayer, icon: const Icon(Icons.add_rounded), tooltip: 'افزودن کارت'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary.withValues(alpha: .28)),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [scheme.primary.withValues(alpha: .11), scheme.surface, scheme.secondary.withValues(alpha: .04)],
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(7)),
                    child: const Text('FC27 • LOCAL CLUB', textDirection: TextDirection.ltr, style: TextStyle(color: Color(0xFF10140C), fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                  const Spacer(),
                  Text('${items.length} ITEMS', textDirection: TextDirection.ltr, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 9, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 14),
                Text('YOUR CLUB\nCOLLECTION', textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.headlineMedium?.copyWith(height: .94, fontWeight: FontWeight.w900, letterSpacing: -1.1)),
                const SizedBox(height: 8),
                Text('کارت‌ها، ارزش بازار، Duplicateها و بهترین ترکیب فقط روی دستگاه خودت.', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5)),
              ]),
            ),
            const SizedBox(height: 10),
            _Summary(count: items.length, valuation: valuation, loading: loadingValue, duplicates: duplicates.length, coins: _coins),
            if (valueError != null) ...[
              const SizedBox(height: 8),
              _StateLine(icon: Icons.cloud_off_rounded, text: 'قیمت زنده در دسترس نیست؛ مقدار ساختگی نمایش داده نمی‌شود.'),
            ],
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'console', label: Text('Console'), icon: Icon(Icons.sports_esports_rounded)),
                ButtonSegment(value: 'pc', label: Text('PC'), icon: Icon(Icons.computer_rounded)),
              ],
              selected: {platform},
              onSelectionChanged: (value) async {
                setState(() => platform = value.first);
                await _refreshValue(forceRefresh: true);
              },
            ),
            if (bestSquad != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: scheme.outline.withValues(alpha: .6))),
                child: Row(children: [
                  Icon(Icons.stadium_rounded, color: scheme.primary),
                  const SizedBox(width: 9),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('BEST CLUB XI', textDirection: TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                    Text('${bestSquad!.formation.name} • شیمی ${bestSquad!.chemistry.total}/33 • میانگین ${bestSquad!.averageRating.toStringAsFixed(1)}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
                  ])),
                  IconButton(onPressed: _saveBestSquad, icon: const Icon(Icons.save_alt_rounded), tooltip: 'ذخیره در تیم‌ساز'),
                ]),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: searchController,
              onChanged: (value) => setState(() => filter = filter.copyWith(query: value)),
              decoration: const InputDecoration(hintText: 'جستجو در Collection...', prefixIcon: Icon(Icons.search_rounded)),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Expanded(child: Text('CLUB ITEMS', textDirection: TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
              Text('${visible.length}/${items.length}', textDirection: TextDirection.ltr, style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w900, fontSize: 10)),
            ]),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const _EmptyClub()
            else if (visible.isEmpty)
              const _StateLine(icon: Icons.filter_alt_off_rounded, text: 'کارت مطابق جستجو پیدا نشد')
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visible.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 10, childAspectRatio: .67),
                itemBuilder: (_, i) {
                  final item = visible[i];
                  final value = _valueFor(item.playerId);
                  final p = item.toPlayer();
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: p))),
                    onLongPress: () => _showActions(item, value),
                    child: Stack(children: [
                      Positioned.fill(child: PlayerItemVisual(player: p, compact: true, showPrices: true)),
                      if (item.untradeable)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFF050806).withValues(alpha: .8), borderRadius: BorderRadius.circular(6)),
                            child: const Text('UNTRADEABLE', textDirection: TextDirection.ltr, style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900)),
                          ),
                        ),
                    ]),
                  );
                },
              ),
            const SizedBox(height: 10),
            Text('برای اکشن‌های بیشتر روی کارت نگه دار.', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(MyClubItem item, ClubPlayerValue? value) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(title: Text(item.playerName, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(value?.currentPrice == null ? 'قیمت زنده: —' : 'قیمت زنده: ${_coins(value!.currentPrice!)} سکه')),
            ListTile(leading: const Icon(Icons.person_search_rounded), title: const Text('جزئیات بازیکن'), onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: item.toPlayer()))); }),
            ListTile(leading: const Icon(Icons.stadium_rounded), title: const Text('باز کردن تیم‌ساز'), onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SquadScreen())); }),
            ListTile(leading: const Icon(Icons.auto_awesome_rounded), title: const Text('بررسی Evolution'), onTap: () { Navigator.pop(context); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EvolutionsScreen())); }),
            ListTile(leading: const Icon(Icons.delete_outline_rounded), title: const Text('حذف از باشگاه'), onTap: () async { Navigator.pop(context); await _remove(item.playerId); }),
          ]),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.count, required this.valuation, required this.loading, required this.duplicates, required this.coins});
  final int count;
  final ClubValuation? valuation;
  final bool loading;
  final int duplicates;
  final String Function(int) coins;
  @override
  Widget build(BuildContext context) {
    final data = valuation;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      childAspectRatio: .95,
      children: [
        _Metric(label: 'ITEMS', value: '$count'),
        _Metric(label: 'VALUE', value: loading ? '…' : data == null ? '—' : coins(data.totalMarketValue)),
        _Metric(label: 'TRADE', value: data == null ? '—' : coins(data.tradeableMarketValue)),
        _Metric(label: 'DUPES', value: '$duplicates'),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(9), border: Border.all(color: scheme.outline.withValues(alpha: .6))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, textDirection: TextDirection.ltr, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, textDirection: TextDirection.ltr, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 7.5, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _StateLine extends StatelessWidget {
  const _StateLine({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: scheme.outline.withValues(alpha: .6))),
      child: Row(children: [Icon(icon, color: scheme.primary), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(color: scheme.onSurfaceVariant)))]),
    );
  }
}

class _EmptyClub extends StatelessWidget {
  const _EmptyClub();
  @override
  Widget build(BuildContext context) => const _StateLine(icon: Icons.inventory_2_outlined, text: 'باشگاه خالی است؛ از دکمه + کارت واقعی FC27 اضافه کن.');
}

class _AddResult {
  const _AddResult({required this.price, required this.untradeable});
  final int price;
  final bool untradeable;
}

class _AddDialog extends StatefulWidget {
  const _AddDialog({required this.player});
  final Player player;
  @override
  State<_AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<_AddDialog> {
  final controller = TextEditingController();
  bool untradeable = false;
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.player.name),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      SwitchListTile(contentPadding: EdgeInsets.zero, value: untradeable, onChanged: (v) => setState(() => untradeable = v), title: const Text('غیرقابل فروش')),
      if (!untradeable) TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت خرید واقعی', suffixText: 'Coins')),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
      FilledButton(onPressed: () => Navigator.pop(context, _AddResult(price: untradeable ? 0 : int.tryParse(controller.text.trim()) ?? 0, untradeable: untradeable)), child: const Text('ذخیره')),
    ],
  );
}

class _PlayerPicker extends StatefulWidget {
  const _PlayerPicker({required this.players});
  final List<Player> players;
  @override
  State<_PlayerPicker> createState() => _PlayerPickerState();
}

class _PlayerPickerState extends State<_PlayerPicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final data = widget.players.where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.clubName.toLowerCase().contains(q) || p.position.toLowerCase().contains(q)).toList()..sort((a, b) => b.rating.compareTo(a.rating));
    return SafeArea(child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(children: [
          TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(hintText: 'جستجوی بازیکن FC27...', prefixIcon: Icon(Icons.search_rounded))),
          const SizedBox(height: 10),
          Expanded(child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: .67),
            itemCount: data.length,
            itemBuilder: (_, i) {
              final p = data[i];
              return GestureDetector(onTap: () => Navigator.pop(context, p), child: PlayerItemVisual(player: p, compact: true, showPrices: true));
            },
          )),
        ]),
      ),
    ));
  }
}
