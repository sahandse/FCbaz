import 'package:flutter/material.dart';

import '../../players/data/player_repository.dart';
import '../../players/domain/player.dart';
import '../../squad/data/squad_repository.dart';
import '../../squad/domain/squad_models.dart';
import '../../settings/app_settings_repository.dart';
import '../data/my_club_repository.dart';
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

  String platform = 'console';

  List<MyClubItem> items = const [];
  ClubValuation? valuation;
  BestClubSquad? bestSquad;

  bool loading = true;
  bool loadingValue = false;
  String? valueError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final settings = await settingsRepository.load();
    if (!mounted) return;
    setState(() => platform = settings.defaultPlatform);
    await _load();
  }

  String _coins(int value) {
    final negative = value < 0;
    final abs = value.abs();
    String result;
    if (abs >= 1000000) {
      final n = abs / 1000000;
      result = n.toStringAsFixed(n >= 10 ? 0 : 1) + 'M';
    } else if (abs >= 1000) {
      final n = abs / 1000;
      result = n.toStringAsFixed(n >= 100 ? 0 : 1) + 'K';
    } else {
      result = abs.toString();
    }
    return negative ? '-' + result : result;
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
      setState(() {
        valuation = null;
        valueError = null;
      });
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
      if (!mounted) return;
      setState(() => valuation = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => valueError = e.toString());
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return;
    }

    if (!mounted) return;

    final selected = await showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ClubPlayerPicker(players: players),
    );

    if (selected == null || !mounted) return;

    final result = await showDialog<_AddClubResult>(
      context: context,
      builder: (context) => _AddClubDialog(player: selected),
    );

    if (result == null) return;

    await clubRepository.upsert(
      MyClubItem.fromPlayer(
        selected,
        acquisitionPrice: result.acquisitionPrice,
        untradeable: result.untradeable,
      ),
    );

    await _load();
  }

  Future<void> _saveBestSquad() async {
    final best = bestSquad;
    if (best == null) return;

    final squad = SquadStateModel(
      id: 'club_best_' + DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'بهترین ترکیب باشگاه من',
      formationId: best.formation.id,
      playersBySlot: {
        for (final entry in best.playersBySlot.entries)
          entry.key: entry.value.toPlayer(),
      },
    );

    await squadRepository.upsert(squad);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('بهترین ترکیب در تیم‌ساز ذخیره شد'),
      ),
    );
  }

  Future<void> _remove(String playerId) async {
    await clubRepository.remove(playerId);
    await _load();
  }

  ClubPlayerValue? _valueFor(String playerId) {
    final list = valuation?.players ?? const <ClubPlayerValue>[];
    for (final value in list) {
      if (value.item.playerId == playerId) return value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('باشگاه من'),
        actions: [
          IconButton(
            onPressed: loadingValue ? null : () => _refreshValue(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'بروزرسانی قیمت‌ها',
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
          padding: const EdgeInsets.all(16),
          children: [
            _ClubSummary(
              count: items.length,
              valuation: valuation,
              loadingValue: loadingValue,
              error: valueError,
              coins: _coins,
            ),
            const SizedBox(height: 14),
            if (bestSquad != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'بهترین ترکیب از باشگاه من',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        bestSquad!.formation.name +
                            ' • Chemistry ' +
                            bestSquad!.chemistry.total.toString() +
                            '/33 • میانگین ' +
                            bestSquad!.averageRating.toStringAsFixed(1),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saveBestSquad,
                          icon: const Icon(Icons.stadium_rounded),
                          label: const Text('ذخیره در تیم‌ساز'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (items.isNotEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('برای ساخت ترکیب حداقل ۱۱ کارت لازم است'),
                ),
              ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 44,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'باشگاهت خالی است',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'کارت‌های واقعی Ultimate Team خودت را اینجا ثبت کن.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _addPlayer,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('افزودن بازیکن'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                'کارت‌های باشگاه',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              for (final item in items) ...[
                _ClubPlayerCard(
                  item: item,
                  value: _valueFor(item.playerId),
                  coins: _coins,
                  onDelete: () => _remove(item.playerId),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ClubSummary extends StatelessWidget {
  const _ClubSummary({
    required this.count,
    required this.valuation,
    required this.loadingValue,
    required this.error,
    required this.coins,
  });

  final int count;
  final ClubValuation? valuation;
  final bool loadingValue;
  final String? error;
  final String Function(int) coins;

  @override
  Widget build(BuildContext context) {
    final data = valuation;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'بازیکن',
                value: count.toString(),
                icon: Icons.groups_2_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'ارزش لحظه‌ای',
                value: loadingValue
                    ? '...'
                    : data == null
                        ? '—'
                        : coins(data.totalMarketValue),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'قابل فروش',
                value: data == null ? '—' : coins(data.tradeableMarketValue),
                icon: Icons.sell_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'سود/ضرر',
                value: data == null
                    ? '—'
                    : coins(data.realizedComparableProfitLoss),
                icon: data != null && data.realizedComparableProfitLoss < 0
                    ? Icons.trending_down_rounded
                    : Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off_rounded),
              title: const Text('ارزش زنده قابل دریافت نیست'),
              subtitle: Text(error!),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubPlayerCard extends StatelessWidget {
  const _ClubPlayerCard({
    required this.item,
    required this.value,
    required this.coins,
    required this.onDelete,
  });

  final MyClubItem item;
  final ClubPlayerValue? value;
  final String Function(int) coins;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final current = value?.currentPrice;
    final pnl = value?.profitLoss;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundImage:
              item.imageUrl.isEmpty ? null : NetworkImage(item.imageUrl),
          child: item.imageUrl.isEmpty ? Text(item.rating.toString()) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.playerName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            if (item.untradeable)
              const Chip(label: Text('Untradeable')),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.rating.toString() +
                  ' • ' +
                  item.position +
                  ' • ' +
                  item.clubName,
            ),
            const SizedBox(height: 4),
            Text(
              current == null
                  ? 'قیمت زنده: در دسترس نیست'
                  : 'قیمت زنده: ' + coins(current) + ' Coins',
            ),
            if (!item.untradeable && item.acquisitionPrice > 0)
              Text(
                pnl == null
                    ? 'سود/ضرر: نامشخص'
                    : 'سود/ضرر: ' + coins(pnl) + ' Coins',
                style: TextStyle(
                  color: pnl == null
                      ? null
                      : pnl >= 0
                          ? Theme.of(context).colorScheme.primary
                          : Colors.redAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: 'حذف از باشگاه',
        ),
      ),
    );
  }
}

class _AddClubResult {
  const _AddClubResult({
    required this.acquisitionPrice,
    required this.untradeable,
  });

  final int acquisitionPrice;
  final bool untradeable;
}

class _AddClubDialog extends StatefulWidget {
  const _AddClubDialog({required this.player});
  final Player player;

  @override
  State<_AddClubDialog> createState() => _AddClubDialogState();
}

class _AddClubDialogState extends State<_AddClubDialog> {
  final controller = TextEditingController();
  bool untradeable = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.player.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: untradeable,
            onChanged: (value) => setState(() => untradeable = value),
            title: const Text('Untradeable'),
            subtitle: const Text('این کارت قابل فروش نیست'),
          ),
          if (!untradeable)
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'قیمت خرید واقعی',
                suffixText: 'Coins',
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _AddClubResult(
              acquisitionPrice:
                  untradeable ? 0 : int.tryParse(controller.text.trim()) ?? 0,
              untradeable: untradeable,
            ),
          ),
          child: const Text('افزودن'),
        ),
      ],
    );
  }
}

class _ClubPlayerPicker extends StatefulWidget {
  const _ClubPlayerPicker({required this.players});
  final List<Player> players;

  @override
  State<_ClubPlayerPicker> createState() => _ClubPlayerPickerState();
}

class _ClubPlayerPickerState extends State<_ClubPlayerPicker> {
  String query = '';

  List<Player> get visible {
    final q = query.trim().toLowerCase();
    final data = widget.players.where((p) {
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.clubName.toLowerCase().contains(q) ||
          p.position.toLowerCase().contains(q);
    }).toList();

    data.sort((a, b) => b.rating.compareTo(a.rating));
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final data = visible;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  hintText: 'جستجوی بازیکن...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final p = data[index];

                    return Card(
                      child: ListTile(
                        onTap: () => Navigator.pop(context, p),
                        leading: CircleAvatar(
                          backgroundImage:
                              p.imageUrl.isEmpty ? null : NetworkImage(p.imageUrl),
                          child:
                              p.imageUrl.isEmpty ? Text(p.rating.toString()) : null,
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          p.rating.toString() +
                              ' • ' +
                              p.position +
                              ' • ' +
                              p.clubName,
                        ),
                        trailing: const Icon(Icons.add_rounded),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
