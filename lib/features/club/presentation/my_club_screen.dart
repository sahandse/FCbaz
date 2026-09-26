import 'package:flutter/material.dart';

import '../../evolutions/presentation/evolutions_screen.dart';
import '../../players/data/player_repository.dart';
import '../../players/domain/player.dart';
import '../../players/presentation/player_details_screen.dart';
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
      final data = await clubService.valueClub(
        items,
        platform: platform,
        forceRefresh: forceRefresh,
      );
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

    final existing = items.where((e) =>
        e.playerName.trim().toLowerCase() == selected.name.trim().toLowerCase() &&
        e.rating == selected.rating &&
        e.position == selected.position &&
        e.version.trim().toLowerCase() == selected.version.trim().toLowerCase()).toList();

    if (existing.isNotEmpty) {
      final continueAdd = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('کارت مشابه در باشگاه'),
          content: Text('یک کارت مشابه از ${selected.name} از قبل ثبت شده است. اطلاعات موجود بروزرسانی می‌شود.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ادامه')),
          ],
        ),
      );
      if (continueAdd != true) return;
    }

    final result = await showDialog<_AddResult>(
      context: context,
      builder: (_) => _AddDialog(player: selected),
    );
    if (result == null) return;

    await clubRepository.upsert(MyClubItem.fromPlayer(
      selected,
      acquisitionPrice: result.price,
      untradeable: result.untradeable,
    ));
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
      playersBySlot: {
        for (final entry in best.playersBySlot.entries) entry.key: entry.value.toPlayer(),
      },
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ترکیب در تیم‌ساز ذخیره شد')),
    );
  }

  ClubPlayerValue? _valueFor(String id) {
    for (final value in valuation?.players ?? const <ClubPlayerValue>[]) {
      if (value.item.playerId == id) return value;
    }
    return null;
  }

  String _coins(int value) {
    final negative = value < 0;
    final abs = value.abs();
    final text = abs >= 1000000
        ? '${(abs / 1000000).toStringAsFixed(abs >= 10000000 ? 0 : 1)}M'
        : abs >= 1000
            ? '${(abs / 1000).toStringAsFixed(abs >= 100000 ? 0 : 1)}K'
            : '$abs';
    return negative ? '-$text' : text;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final visible = visibleItems;
    final positions = inventoryAnalysis.positions(items).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('باشگاه من'),
        actions: [
          IconButton(
            onPressed: loadingValue ? null : () => _refreshValue(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'بروزرسانی قیمت واقعی',
          ),
          IconButton(
            onPressed: _addPlayer,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'افزودن بازیکن',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            _Summary(
              count: items.length,
              valuation: valuation,
              loading: loadingValue,
              duplicates: duplicates.length,
              coins: _coins,
            ),
            if (valueError != null) ...[
              const SizedBox(height: 10),
              Card(child: ListTile(
                leading: const Icon(Icons.cloud_off_rounded),
                title: const Text('قیمت زنده در دسترس نیست'),
                subtitle: Text(valueError!),
              )),
            ],
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'console', label: Text('کنسول'), icon: Icon(Icons.sports_esports_rounded)),
                ButtonSegment(value: 'pc', label: Text('رایانه'), icon: Icon(Icons.computer_rounded)),
              ],
              selected: {platform},
              onSelectionChanged: (value) async {
                setState(() => platform = value.first);
                await _refreshValue(forceRefresh: true);
              },
            ),
            if (bestSquad != null) ...[
              const SizedBox(height: 14),
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('بهترین ترکیب از باشگاه', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('${bestSquad!.formation.name} • شیمی ${bestSquad!.chemistry.total}/33 • میانگین ${bestSquad!.averageRating.toStringAsFixed(1)}'),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: FilledButton.icon(
                    onPressed: _saveBestSquad,
                    icon: const Icon(Icons.stadium_rounded),
                    label: const Text('ذخیره در تیم‌ساز'),
                  )),
                ]),
              )),
            ],
            if (duplicates.isNotEmpty) ...[
              const SizedBox(height: 14),
              Card(child: ExpansionTile(
                leading: const Icon(Icons.copy_all_rounded),
                title: Text('${duplicates.length} گروه کارت مشابه'),
                subtitle: const Text('بر اساس نام، ریتینگ، پست و نسخه ثبت‌شده محلی'),
                children: [
                  for (final group in duplicates.take(8))
                    ListTile(
                      dense: true,
                      title: Text(group.items.first.playerName),
                      subtitle: Text('${group.items.first.rating} • ${group.items.first.version}'),
                      trailing: Text('${group.items.length}×'),
                    ),
                ],
              )),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              onChanged: (value) => setState(() => filter = filter.copyWith(query: value)),
              decoration: const InputDecoration(
                hintText: 'جستجو در نام، باشگاه، لیگ، کشور یا نسخه...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                initialValue: filter.position.isEmpty ? '' : filter.position,
                decoration: const InputDecoration(labelText: 'پست'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('همه پست‌ها')),
                  for (final p in positions) DropdownMenuItem(value: p, child: Text(p)),
                ],
                onChanged: (value) => setState(() => filter = filter.copyWith(position: value ?? '')),
              )),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<ClubTradeFilter>(
                initialValue: filter.trade,
                decoration: const InputDecoration(labelText: 'وضعیت فروش'),
                items: const [
                  DropdownMenuItem(value: ClubTradeFilter.all, child: Text('همه')),
                  DropdownMenuItem(value: ClubTradeFilter.tradeable, child: Text('قابل فروش')),
                  DropdownMenuItem(value: ClubTradeFilter.untradeable, child: Text('غیرقابل فروش')),
                ],
                onChanged: (value) => setState(() => filter = filter.copyWith(trade: value)),
              )),
            ]),
            const SizedBox(height: 10),
            DropdownButtonFormField<ClubSort>(
              initialValue: filter.sort,
              decoration: const InputDecoration(labelText: 'مرتب‌سازی'),
              items: const [
                DropdownMenuItem(value: ClubSort.rating, child: Text('بالاترین ریتینگ')),
                DropdownMenuItem(value: ClubSort.name, child: Text('نام بازیکن')),
                DropdownMenuItem(value: ClubSort.acquisitionPrice, child: Text('بیشترین قیمت خرید')),
              ],
              onChanged: (value) => setState(() => filter = filter.copyWith(sort: value)),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: Text('کارت‌های باشگاه', style: Theme.of(context).textTheme.titleLarge)),
              Text('${visible.length} از ${items.length}', style: Theme.of(context).textTheme.labelMedium),
            ]),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const _EmptyClub()
            else if (visible.isEmpty)
              const Card(child: ListTile(
                leading: Icon(Icons.filter_alt_off_rounded),
                title: Text('کارت مطابق فیلتر پیدا نشد'),
              ))
            else
              for (final item in visible) ...[
                _ClubCard(
                  item: item,
                  value: _valueFor(item.playerId),
                  coins: _coins,
                  onDelete: () => _remove(item.playerId),
                  onDetails: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PlayerDetailsScreen(player: item.toPlayer()),
                  )),
                  onSquad: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SquadScreen())),
                  onEvolution: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EvolutionsScreen())),
                ),
                const SizedBox(height: 8),
              ],
          ],
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
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _Metric(label: 'کارت‌ها', value: '$count', icon: Icons.groups_2_rounded),
        _Metric(label: 'ارزش واقعی', value: loading ? '...' : data == null ? '—' : coins(data.totalMarketValue), icon: Icons.account_balance_wallet_outlined),
        _Metric(label: 'قابل فروش', value: data == null ? '—' : coins(data.tradeableMarketValue), icon: Icons.sell_outlined),
        _Metric(label: 'کارت مشابه', value: '$duplicates', icon: Icons.copy_all_rounded),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(12),
    child: Row(children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 9),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ])),
    ]),
  ));
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.item, required this.value, required this.coins, required this.onDelete, required this.onDetails, required this.onSquad, required this.onEvolution});
  final MyClubItem item;
  final ClubPlayerValue? value;
  final String Function(int) coins;
  final VoidCallback onDelete;
  final VoidCallback onDetails;
  final VoidCallback onSquad;
  final VoidCallback onEvolution;

  @override
  Widget build(BuildContext context) {
    final current = value?.currentPrice;
    final pnl = value?.profitLoss;
    return Card(child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: item.imageUrl.isEmpty ? null : NetworkImage(item.imageUrl),
            child: item.imageUrl.isEmpty ? Text('${item.rating}') : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.playerName, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text('${item.rating} • ${item.position}${item.clubName.isEmpty ? '' : ' • ${item.clubName}'}'),
            Text(current == null ? 'قیمت زنده: —' : 'قیمت زنده: ${coins(current)} سکه', style: Theme.of(context).textTheme.labelMedium),
            if (!item.untradeable && item.acquisitionPrice > 0)
              Text(pnl == null ? 'سود/ضرر: —' : 'سود/ضرر: ${coins(pnl)} سکه', style: TextStyle(fontWeight: FontWeight.w800, color: pnl != null && pnl >= 0 ? Theme.of(context).colorScheme.primary : null)),
          ])),
          if (item.untradeable) const Chip(label: Text('غیرقابل فروش')),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: onDetails, icon: const Icon(Icons.person_search_rounded, size: 18), label: const Text('جزئیات'))),
          const SizedBox(width: 6),
          IconButton(onPressed: onSquad, tooltip: 'تیم‌ساز', icon: const Icon(Icons.stadium_rounded)),
          IconButton(onPressed: onEvolution, tooltip: 'Evolution', icon: const Icon(Icons.auto_awesome_rounded)),
          IconButton(onPressed: onDelete, tooltip: 'حذف از باشگاه', icon: const Icon(Icons.delete_outline_rounded)),
        ]),
      ]),
    ));
  }
}

class _EmptyClub extends StatelessWidget {
  const _EmptyClub();
  @override
  Widget build(BuildContext context) => const Card(child: Padding(
    padding: EdgeInsets.all(28),
    child: Column(children: [
      Icon(Icons.inventory_2_outlined, size: 44),
      SizedBox(height: 10),
      Text('باشگاهت خالی است', style: TextStyle(fontWeight: FontWeight.w900)),
      SizedBox(height: 5),
      Text('کارت‌های واقعی Ultimate Team خودت را از دکمه بالا اضافه کن.', textAlign: TextAlign.center),
    ]),
  ));
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
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: untradeable,
        onChanged: (v) => setState(() => untradeable = v),
        title: const Text('غیرقابل فروش'),
      ),
      if (!untradeable) TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'قیمت خرید واقعی', suffixText: 'سکه'),
      ),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
      FilledButton(onPressed: () => Navigator.pop(context, _AddResult(
        price: untradeable ? 0 : int.tryParse(controller.text.trim()) ?? 0,
        untradeable: untradeable,
      )), child: const Text('ذخیره')),
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
    final data = widget.players.where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.clubName.toLowerCase().contains(q) || p.position.toLowerCase().contains(q)).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return SafeArea(child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .78,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(children: [
          TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(hintText: 'جستجوی بازیکن...', prefixIcon: Icon(Icons.search_rounded))),
          const SizedBox(height: 10),
          Expanded(child: ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 7),
            itemBuilder: (_, i) {
              final p = data[i];
              return Card(child: ListTile(
                onTap: () => Navigator.pop(context, p),
                leading: CircleAvatar(backgroundImage: p.imageUrl.isEmpty ? null : NetworkImage(p.imageUrl), child: p.imageUrl.isEmpty ? Text('${p.rating}') : null),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text('${p.rating} • ${p.position} • ${p.clubName}'),
                trailing: const Icon(Icons.add_rounded),
              ));
            },
          )),
        ]),
      ),
    ));
  }
}
