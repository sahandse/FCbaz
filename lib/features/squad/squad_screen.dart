import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../market/data/market_repository.dart';
import '../players/data/player_repository.dart';
import '../players/domain/player.dart';
import 'data/squad_repository.dart';
import 'domain/chemistry_engine.dart';
import 'domain/squad_chemistry_optimizer.dart';
import 'domain/squad_models.dart';

class SquadScreen extends StatefulWidget {
  const SquadScreen({super.key});

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  final squadRepository = SquadRepository();
  final playerRepository = PlayerRepository();
  final marketRepository = MarketRepository();
  final chemistryEngine = const ChemistryEngineFC27();
  final chemistryOptimizer = const SquadChemistryOptimizer();

  List<SquadStateModel> savedSquads = const [];
  late SquadStateModel squad;
  int? squadPrice;
  bool loadingPrice = false;

  FormationDefinition get formation => Formations.byId(squad.formationId);

  ChemistryResult get chemistry => chemistryEngine.calculate(
        formation: formation,
        playersBySlot: squad.playersBySlot,
        manager: squad.manager,
      );

  @override
  void initState() {
    super.initState();
    squad = _newSquad();
    _loadSaved();
  }

  SquadStateModel _newSquad() => SquadStateModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'ترکیب من',
        formationId: '433',
        playersBySlot: const {},
      );

  Future<void> _loadSaved() async {
    final data = await squadRepository.getAll();
    if (!mounted) return;
    setState(() {
      savedSquads = data;
      if (data.isNotEmpty) squad = data.first;
    });
    await _refreshPrice();
  }

  Future<void> _save() async {
    await squadRepository.upsert(squad);
    final data = await squadRepository.getAll();
    if (!mounted) return;
    setState(() => savedSquads = data);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ترکیب ذخیره شد')),
    );
  }

  Future<void> _createNew() async {
    setState(() {
      squad = _newSquad();
      squadPrice = null;
    });
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: squad.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نام ترکیب'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'مثلاً تیم اصلی'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;
    setState(() => squad = squad.copyWith(name: name));
    await _save();
  }

  Future<void> _deleteCurrent() async {
    await squadRepository.delete(squad.id);
    final data = await squadRepository.getAll();
    if (!mounted) return;
    setState(() {
      savedSquads = data;
      squad = data.isEmpty ? _newSquad() : data.first;
      squadPrice = null;
    });
    await _refreshPrice();
  }

  void _changeFormation(String? id) {
    if (id == null || id == squad.formationId) return;

    final nextFormation = Formations.byId(id);
    final compatible = <String, Player>{};

    for (final entry in squad.playersBySlot.entries) {
      if (nextFormation.slots.any((slot) => slot.id == entry.key)) {
        compatible[entry.key] = entry.value;
      }
    }

    final compatibleConfigs = <String, SquadPlayerConfig>{};
    for (final slotId in compatible.keys) {
      final config = squad.playerConfigs[slotId];
      if (config != null) compatibleConfigs[slotId] = config;
    }

    setState(() {
      squad = squad.copyWith(
        formationId: id,
        playersBySlot: compatible,
        playerConfigs: compatibleConfigs,
      );
    });
    _refreshPrice();
  }

  Future<void> _pickPlayer(FormationSlot slot) async {
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
      builder: (context) => _PlayerPicker(
        players: players,
        slotPosition: slot.position,
        selectedIds: squad.playersBySlot.values.map((e) => e.id).toSet(),
      ),
    );

    if (selected == null) return;

    final playersBySlot = Map<String, Player>.from(squad.playersBySlot);
    playersBySlot[slot.id] = selected;

    setState(() => squad = squad.copyWith(playersBySlot: playersBySlot));
    await _refreshPrice();
  }

  Future<void> _removePlayer(String slotId) async {
    final players = Map<String, Player>.from(squad.playersBySlot)..remove(slotId);
    final configs = Map<String, SquadPlayerConfig>.from(squad.playerConfigs)
      ..remove(slotId);
    setState(() => squad = squad.copyWith(
          playersBySlot: players,
          playerConfigs: configs,
        ));
    await _refreshPrice();
  }

  Future<void> _editManager() async {
    final current = squad.manager;
    final name = TextEditingController(text: current?.name ?? '');
    final nation = TextEditingController(text: current?.nationName ?? '');
    final league = TextEditingController(text: current?.leagueName ?? '');

    final result = await showDialog<ManagerProfile?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manager'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'نام Manager'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nation,
              decoration: const InputDecoration(labelText: 'Nation واقعی'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: league,
              decoration: const InputDecoration(labelText: 'League فعال Manager'),
            ),
          ],
        ),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(context, const ManagerProfile(
                name: '',
                nationName: '',
                leagueName: '',
              )),
              child: const Text('حذف'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              ManagerProfile(
                name: name.text.trim(),
                nationName: nation.text.trim(),
                leagueName: league.text.trim(),
              ),
            ),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    name.dispose();
    nation.dispose();
    league.dispose();

    if (result == null) return;
    setState(() {
      squad = result.isEmpty
          ? squad.copyWith(clearManager: true)
          : squad.copyWith(manager: result);
    });
  }

  Future<void> _configurePlayer(FormationSlot slot, Player player) async {
    final current = squad.playerConfigs[slot.id] ?? const SquadPlayerConfig();
    final focusController = TextEditingController(text: current.focus);
    var style = current.chemistryStyle;
    var role = current.role;

    const styles = [
      'Basic', 'Sniper', 'Finisher', 'Deadeye', 'Marksman', 'Hawk',
      'Artist', 'Architect', 'Powerhouse', 'Maestro', 'Engine',
      'Sentinel', 'Guardian', 'Gladiator', 'Backbone', 'Anchor',
      'Hunter', 'Catalyst', 'Shadow', 'GK Basic', 'Wall', 'Shield',
      'Cat', 'Glove',
    ];

    final result = await showModalBottomSheet<SquadPlayerConfig>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16, 4, 16, 16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  player.name + ' • ' + slot.position,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: styles.contains(style) ? style : 'Basic',
                  decoration: const InputDecoration(
                    labelText: 'Chemistry Style',
                  ),
                  items: [
                    for (final item in styles)
                      DropdownMenuItem(value: item, child: Text(item)),
                  ],
                  onChanged: (value) {
                    if (value != null) setSheetState(() => style = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role.isEmpty || !player.roles.contains(role)
                      ? null
                      : role,
                  decoration: const InputDecoration(
                    labelText: 'Role واقعی کارت',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('بدون انتخاب'),
                    ),
                    for (final item in player.roles)
                      DropdownMenuItem(value: item, child: Text(item)),
                  ],
                  onChanged: (value) {
                    setSheetState(() => role = value ?? '');
                  },
                ),
                if (player.roles.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'منبع این کارت Role قابل استفاده‌ای برنگردانده است.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: focusController,
                  decoration: const InputDecoration(
                    labelText: 'Focus',
                    hintText: 'Focus واقعی که داخل بازی استفاده می‌کنی',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    SquadPlayerConfig(
                      chemistryStyle: style,
                      role: role,
                      focus: focusController.text.trim(),
                    ),
                  ),
                  child: const Text('اعمال'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    focusController.dispose();
    if (result == null) return;

    final configs = Map<String, SquadPlayerConfig>.from(squad.playerConfigs)
      ..[slot.id] = result;
    setState(() => squad = squad.copyWith(playerConfigs: configs));
  }

  Future<void> _addBenchPlayer() async {
    if (squad.bench.length >= 7) return;

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

    final used = {
      ...squad.playersBySlot.values.map((e) => e.id),
      ...squad.bench.map((e) => e.id),
    };

    final selected = await showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PlayerPicker(
        players: players,
        slotPosition: '',
        selectedIds: used,
      ),
    );

    if (selected == null) return;
    setState(() => squad = squad.copyWith(
          bench: [...squad.bench, selected].take(7).toList(),
        ));
  }

  void _removeBenchPlayer(String id) {
    setState(() => squad = squad.copyWith(
          bench: squad.bench.where((e) => e.id != id).toList(),
        ));
  }

  Future<void> _exportSquad() async {
    final raw = squadRepository.exportSquad(squad);
    await Clipboard.setData(ClipboardData(text: raw));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('کد ترکیب در Clipboard کپی شد')),
    );
  }

  Future<void> _importSquad() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text?.trim() ?? '';
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard خالی است')),
      );
      return;
    }

    try {
      final imported = squadRepository.importSquad(raw);
      await squadRepository.upsert(imported);
      final all = await squadRepository.getAll();
      if (!mounted) return;
      setState(() {
        squad = imported;
        savedSquads = all;
      });
      await _refreshPrice();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import ناموفق: ' + e.toString())),
      );
    }
  }

  void _optimizeChemistry() {
    if (squad.playersBySlot.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برای Optimize باید Starting XI کامل باشد')),
      );
      return;
    }

    final before = chemistry.total;
    final result = chemistryOptimizer.optimize(
      formation: formation,
      current: squad.playersBySlot,
      engine: chemistryEngine,
      manager: squad.manager,
    );

    final oldConfigsByPlayer = <String, SquadPlayerConfig>{};
    for (final entry in squad.playersBySlot.entries) {
      final config = squad.playerConfigs[entry.key];
      if (config != null) oldConfigsByPlayer[entry.value.id] = config;
    }

    final remappedConfigs = <String, SquadPlayerConfig>{};
    for (final entry in result.playersBySlot.entries) {
      final config = oldConfigsByPlayer[entry.value.id];
      if (config != null) remappedConfigs[entry.key] = config;
    }

    setState(() => squad = squad.copyWith(
          playersBySlot: result.playersBySlot,
          playerConfigs: remappedConfigs,
        ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Chemistry: ' + before.toString() + ' → ' + result.chemistry.total.toString(),
        ),
      ),
    );
  }

  Future<void> _refreshPrice() async {
    final players = squad.playersBySlot.values.toList();
    if (players.isEmpty) {
      if (mounted) setState(() => squadPrice = 0);
      return;
    }

    setState(() => loadingPrice = true);

    try {
      final prices = await Future.wait(
        players.map((p) => marketRepository.getPlayerPrice(p.id)),
      );
      final total = prices.fold<int>(0, (sum, item) => sum + item.current);
      if (mounted) setState(() => squadPrice = total);
    } catch (_) {
      if (mounted) setState(() => squadPrice = null);
    } finally {
      if (mounted) setState(() => loadingPrice = false);
    }
  }

  String _coins(int value) {
    if (value >= 1000000) {
      final v = value / 1000000;
      return v.toStringAsFixed(v >= 10 ? 0 : 1) + 'M';
    }
    if (value >= 1000) {
      final v = value / 1000;
      return v.toStringAsFixed(v >= 100 ? 0 : 1) + 'K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final result = chemistry;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تیم‌ساز', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 3),
                  Text(
                    squad.name,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: _createNew,
              tooltip: 'ترکیب جدید',
              icon: const Icon(Icons.add_rounded),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              tooltip: 'مدیریت ترکیب',
              onSelected: (value) {
                if (value == 'save') _save();
                if (value == 'rename') _rename();
                if (value == 'manager') _editManager();
                if (value == 'optimize') _optimizeChemistry();
                if (value == 'export') _exportSquad();
                if (value == 'import') _importSquad();
                if (value == 'delete') _deleteCurrent();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'save', child: Text('ذخیره')),
                PopupMenuItem(value: 'rename', child: Text('تغییر نام')),
                PopupMenuItem(value: 'manager', child: Text('Manager')),
                PopupMenuItem(value: 'optimize', child: Text('Optimize Chemistry')),
                PopupMenuItem(value: 'export', child: Text('Export / Share')),
                PopupMenuItem(value: 'import', child: Text('Import از Clipboard')),
                PopupMenuItem(value: 'delete', child: Text('حذف ترکیب')),
              ],
            ),
          ],
        ),
        if (savedSquads.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: savedSquads.any((s) => s.id == squad.id) ? squad.id : null,
            decoration: const InputDecoration(
              labelText: 'ترکیب‌های ذخیره‌شده',
              prefixIcon: Icon(Icons.folder_open_rounded),
            ),
            items: [
              for (final item in savedSquads)
                DropdownMenuItem(
                  value: item.id,
                  child: Text(item.name),
                ),
            ],
            onChanged: (id) {
              if (id == null) return;
              final selected = savedSquads.firstWhere((s) => s.id == id);
              setState(() => squad = selected);
              _refreshPrice();
            },
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            onTap: _editManager,
            leading: Icon(
              Icons.badge_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              squad.manager == null || squad.manager!.name.isEmpty
                  ? 'Manager اضافه نشده'
                  : squad.manager!.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              squad.manager == null
                  ? 'برای +1 Chemistry از Nation/League Manager استفاده کن'
                  : [
                      squad.manager!.nationName,
                      squad.manager!.leagueName,
                    ].where((e) => e.isNotEmpty).join(' • '),
            ),
            trailing: const Icon(Icons.edit_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: squad.formationId,
                decoration: const InputDecoration(
                  labelText: 'Formation',
                  prefixIcon: Icon(Icons.account_tree_rounded),
                ),
                items: [
                  for (final item in Formations.all)
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
                ],
                onChanged: _changeFormation,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Chemistry',
                value: result.total.toString() + '/33',
                icon: Icons.hub_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'بازیکن',
                value: squad.playersBySlot.length.toString() + '/11',
                icon: Icons.groups_2_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'قیمت تیم',
                value: loadingPrice
                    ? '...'
                    : squadPrice == null
                        ? 'نامشخص'
                        : _coins(squadPrice!) + ' C',
                icon: Icons.monetization_on_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Pitch(
          formation: formation,
          playersBySlot: squad.playersBySlot,
          playerConfigs: squad.playerConfigs,
          chemistryBySlot: result.bySlot,
          onTapEmptySlot: _pickPlayer,
          onConfigurePlayer: _configurePlayer,
          onRemovePlayer: _removePlayer,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                'نیمکت',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              squad.bench.length.toString() + '/7',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: squad.bench.length >= 7 ? null : _addBenchPlayer,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              tooltip: 'افزودن به نیمکت',
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: squad.bench.isEmpty ? 1 : squad.bench.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              if (squad.bench.isEmpty) {
                return SizedBox(
                  width: 180,
                  child: Card(
                    child: InkWell(
                      onTap: _addBenchPlayer,
                      borderRadius: BorderRadius.circular(18),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline_rounded),
                          SizedBox(height: 6),
                          Text('افزودن بازیکن نیمکت'),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final player = squad.bench[index];
              return SizedBox(
                width: 132,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: player.imageUrl.isEmpty
                              ? null
                              : NetworkImage(player.imageUrl),
                          child: player.imageUrl.isEmpty
                              ? Text(player.rating.toString())
                              : null,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          player.rating.toString() + ' • ' + player.position,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _removeBenchPlayer(player.id),
                          child: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _optimizeChemistry,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Optimize Chemistry'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _exportSquad,
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share / Export',
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('ذخیره ترکیب'),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
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

class _Pitch extends StatelessWidget {
  const _Pitch({
    required this.formation,
    required this.playersBySlot,
    required this.playerConfigs,
    required this.chemistryBySlot,
    required this.onTapEmptySlot,
    required this.onConfigurePlayer,
    required this.onRemovePlayer,
  });

  final FormationDefinition formation;
  final Map<String, Player> playersBySlot;
  final Map<String, SquadPlayerConfig> playerConfigs;
  final Map<String, int> chemistryBySlot;
  final ValueChanged<FormationSlot> onTapEmptySlot;
  final void Function(FormationSlot slot, Player player) onConfigurePlayer;
  final ValueChanged<String> onRemovePlayer;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: .76,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF174D2D), Color(0xFF0D2D1B)],
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(child: _PitchLines()),
                for (final slot in formation.slots)
                  Positioned(
                    left: constraints.maxWidth * slot.x - 31,
                    top: constraints.maxHeight * slot.y - 39,
                    width: 62,
                    height: 78,
                    child: _SlotCard(
                      slot: slot,
                      player: playersBySlot[slot.id],
                      chemistry: chemistryBySlot[slot.id] ?? 0,
                      config: playerConfigs[slot.id],
                      onTap: () {
                        final player = playersBySlot[slot.id];
                        if (player == null) {
                          onTapEmptySlot(slot);
                        } else {
                          onConfigurePlayer(slot, player);
                        }
                      },
                      onRemove: () => onRemovePlayer(slot.id),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PitchLines extends StatelessWidget {
  const _PitchLines();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PitchPainter());
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rect = Rect.fromLTWH(14, 14, size.width - 28, size.height - 28);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)), paint);
    canvas.drawLine(
      Offset(14, size.height / 2),
      Offset(size.width - 14, size.height / 2),
      paint,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 42, paint);

    final topBox = Rect.fromCenter(
      center: Offset(size.width / 2, 14),
      width: size.width * .55,
      height: size.height * .16,
    );
    final bottomBox = Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 14),
      width: size.width * .55,
      height: size.height * .16,
    );
    canvas.drawRect(topBox, paint);
    canvas.drawRect(bottomBox, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.player,
    required this.chemistry,
    required this.config,
    required this.onTap,
    required this.onRemove,
  });

  final FormationSlot slot;
  final Player? player;
  final int chemistry;
  final SquadPlayerConfig? config;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: player == null ? null : onRemove,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xE610151C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: player == null
                  ? Colors.white.withValues(alpha: .24)
                  : primary.withValues(alpha: .72),
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 12,
                color: Color(0x33000000),
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: player == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white70, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      slot.position,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: player!.imageUrl.isEmpty
                          ? const Icon(Icons.person_rounded, color: Colors.white, size: 28)
                          : Image.network(
                              player!.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                    ),
                    Text(
                      player!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (config != null &&
                        (config!.role.isNotEmpty ||
                            config!.chemistryStyle != 'Basic')) ...[
                      const SizedBox(height: 1),
                      Text(
                        [
                          if (config!.role.isNotEmpty) config!.role,
                          if (config!.chemistryStyle != 'Basic')
                            config!.chemistryStyle,
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 6.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (i) => Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < chemistry ? primary : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _PlayerPicker extends StatefulWidget {
  const _PlayerPicker({
    required this.players,
    required this.slotPosition,
    required this.selectedIds,
  });

  final List<Player> players;
  final String slotPosition;
  final Set<String> selectedIds;

  @override
  State<_PlayerPicker> createState() => _PlayerPickerState();
}

class _PlayerPickerState extends State<_PlayerPicker> {
  final controller = TextEditingController();
  String query = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  List<Player> get visible {
    final q = query.trim().toLowerCase();

    final result = widget.players.where((p) {
      if (widget.selectedIds.contains(p.id)) return false;
      if (q.isEmpty) return true;

      return p.name.toLowerCase().contains(q) ||
          p.clubName.toLowerCase().contains(q) ||
          p.leagueName.toLowerCase().contains(q) ||
          p.nationName.toLowerCase().contains(q);
    }).toList();

    result.sort((a, b) {
      final aFit = a.position == widget.slotPosition || a.positions.contains(widget.slotPosition);
      final bFit = b.position == widget.slotPosition || b.positions.contains(widget.slotPosition);

      if (aFit != bFit) return aFit ? -1 : 1;
      return b.rating.compareTo(a.rating);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final players = visible;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .78,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.slotPosition.isEmpty
                          ? 'انتخاب بازیکن نیمکت'
                          : 'انتخاب بازیکن برای ' + widget.slotPosition,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(players.length.toString() + ' بازیکن'),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  hintText: 'نام بازیکن، باشگاه، لیگ...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final fit = widget.slotPosition.isEmpty ||
                        player.position == widget.slotPosition ||
                        player.positions.contains(widget.slotPosition);

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        onTap: () => Navigator.pop(context, player),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                          backgroundImage:
                              player.imageUrl.isEmpty ? null : NetworkImage(player.imageUrl),
                          child: player.imageUrl.isEmpty
                              ? const Icon(Icons.person_rounded)
                              : null,
                        ),
                        title: Text(
                          player.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          player.rating.toString() +
                              ' • ' +
                              player.position +
                              ' • ' +
                              player.clubName,
                        ),
                        trailing: widget.slotPosition.isEmpty
                            ? const Icon(Icons.add_rounded)
                            : fit
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : const Icon(Icons.warning_amber_rounded),
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
