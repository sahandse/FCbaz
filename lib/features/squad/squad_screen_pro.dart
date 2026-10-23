import 'package:flutter/material.dart';

import 'squad_screenshot_analyzer.dart';

import '../players/data/player_repository.dart';
import '../players/domain/player.dart';
import 'data/squad_repository.dart';
import 'domain/chemistry_engine.dart';
import 'domain/squad_chemistry_optimizer.dart';
import 'domain/squad_formation_migrator.dart';
import 'domain/squad_models.dart';
import 'presentation/formation_picker_sheet.dart';
import 'presentation/squad_insights_panel.dart';
import 'presentation/tactics_editor_sheet.dart';

class SquadScreenPro extends StatefulWidget {
  const SquadScreenPro({super.key});

  @override
  State<SquadScreenPro> createState() => _SquadScreenProState();
}

class _SquadScreenProState extends State<SquadScreenPro> {
  final squadRepository = SquadRepository();
  final playerRepository = PlayerRepository();
  final chemistryEngine = const ChemistryEngineFC27();
  final formationMigrator = const SquadFormationMigrator();
  final chemistryOptimizer = const SquadChemistryOptimizer();
  final screenshotAnalyzer = SquadScreenshotAnalyzer();
  bool importingScreenshot = false;

  List<SquadStateModel> savedSquads = const [];
  late SquadStateModel squad;
  bool loading = true;

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
    _load();
  }

  @override
  void dispose() {
    screenshotAnalyzer.dispose();
    super.dispose();
  }

  SquadStateModel _newSquad() => SquadStateModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'ترکیب من',
        formationId: '433',
        playersBySlot: const {},
      );

  Future<void> _load() async {
    final data = await squadRepository.getAll();
    if (!mounted) return;
    setState(() {
      savedSquads = data;
      if (data.isNotEmpty) squad = data.first;
      loading = false;
    });
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

  Future<void> _new() async {
    setState(() => squad = _newSquad());
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: squad.name);
    final value = await showDialog<String>(
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
    controller.dispose();
    if (value == null || value.isEmpty) return;
    setState(() => squad = squad.copyWith(name: value));
  }

  Future<void> _pickFormation() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: FormationPickerSheet(currentId: squad.formationId),
      ),
    );
    if (id == null || id == squad.formationId) return;

    final from = formation;
    final to = Formations.byId(id);
    final migrated = formationMigrator.migrate(
      squad: squad,
      from: from,
      to: to,
    );

    setState(() {
      squad = squad.copyWith(
        formationId: id,
        playersBySlot: migrated.playersBySlot,
        playerConfigs: migrated.playerConfigs,
        bench: migrated.bench,
      );
    });

    if (!mounted) return;
    if (migrated.movedToBench > 0 || migrated.outOfPositionPlacements > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${migrated.movedToBench} بازیکن به نیمکت منتقل شد • '
            '${migrated.outOfPositionPlacements} بازیکن موقتاً خارج از پست قرار گرفت',
          ),
        ),
      );
    }
  }

  Future<void> _editTactics() async {
    final result = await showModalBottomSheet<TacticProfile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TacticsEditorSheet(current: squad.tactics),
    );
    if (result == null) return;
    setState(() => squad = squad.copyWith(tactics: result));
  }

  Future<void> _importConsoleScreenshot() async {
    if (importingScreenshot) return;
    setState(() => importingScreenshot = true);
    try {
      final catalog = await playerRepository.getPlayers();
      if (!mounted) return;
      final analysis = await screenshotAnalyzer.pickAndAnalyze(
        catalog: catalog,
        formation: formation,
      );
      if (!mounted || analysis == null) return;
      if (analysis.matchedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('بازیکنی از تصویر شناسایی نشد؛ تصویر واضح‌تر و کامل‌تری انتخاب کن.'),
          ),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('بررسی ترکیب شناسایی‌شده'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${analysis.matchedCount} بازیکن از تصویر شناسایی شد.',
                  style: Theme.of(dialogContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'جای‌گذاری اولیه بر اساس موقعیت بازیکنان در تصویر انجام شده است. قبل از ذخیره، ترکیب و شیمی را بررسی کن.',
                ),
                const SizedBox(height: 12),
                for (final slot in formation.slots)
                  if (analysis.playersBySlot[slot.id] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(
                              slot.position,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(child: Text(analysis.playersBySlot[slot.id]!.name)),
                        ],
                      ),
                    ),
                if (analysis.unmatchedNames.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'متن‌های شناسایی‌شده‌ای که با دیتابیس بازیکنان تطبیق نداشتند: ${analysis.unmatchedNames.take(5).join('، ')}',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ],
                if (squad.playersBySlot.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'تأیید این مرحله، بازیکنان ترکیب اصلی فعلی را جایگزین می‌کند.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.check_rounded),
              label: const Text('اعمال ترکیب'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      var importedPlayers = Map<String, Player>.from(analysis.playersBySlot);
      if (importedPlayers.length == formation.slots.length) {
        final optimized = chemistryOptimizer.optimize(
          formation: formation,
          current: importedPlayers,
          engine: chemistryEngine,
          manager: squad.manager,
        );
        importedPlayers = Map<String, Player>.from(optimized.playersBySlot);
      }

      setState(() {
        squad = squad.copyWith(
          playersBySlot: importedPlayers,
          playerConfigs: const {},
          bench: const [],
        );
      });
      await _save();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ترکیب وارد شد؛ شیمی فعلی ${chemistry.total}/${chemistry.maxForFilledPlayers} است. پیشنهادها پایین صفحه نمایش داده می‌شوند.',
          ),
        ),
      );
    } catch (error) {
      debugPrint('Squad screenshot import failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'خواندن ترکیب از تصویر ممکن نشد. تصویر واضح‌تری از صفحه ترکیب انتخاب کنید.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => importingScreenshot = false);
    }
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

    final selectedIds = <String>{
      ...squad.playersBySlot.values.map((p) => p.id),
      ...squad.bench.map((p) => p.id),
    };
    final selected = await showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PlayerPicker(
        players: players,
        slotPosition: slot.position,
        selectedIds: selectedIds,
      ),
    );
    if (selected == null) return;

    final map = Map<String, Player>.from(squad.playersBySlot)
      ..[slot.id] = selected;
    setState(() => squad = squad.copyWith(playersBySlot: map));
  }

  void _removePlayer(String slotId) {
    final players = Map<String, Player>.from(squad.playersBySlot)
      ..remove(slotId);
    final configs = Map<String, SquadPlayerConfig>.from(squad.playerConfigs)
      ..remove(slotId);
    setState(() => squad = squad.copyWith(
          playersBySlot: players,
          playerConfigs: configs,
        ));
  }

  void _replace(String slotId, Player replacement) {
    final players = Map<String, Player>.from(squad.playersBySlot)
      ..[slotId] = replacement;
    final configs = Map<String, SquadPlayerConfig>.from(squad.playerConfigs)
      ..remove(slotId);
    setState(() => squad = squad.copyWith(
          playersBySlot: players,
          playerConfigs: configs,
        ));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      squad.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${formation.name} • ${squad.playersBySlot.length}/11 بازیکن',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: _rename,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'تغییر نام',
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded),
                tooltip: 'ذخیره',
              ),
            ],
          ),
          if (savedSquads.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: savedSquads.any((s) => s.id == squad.id)
                  ? squad.id
                  : null,
              decoration: const InputDecoration(
                labelText: 'ترکیب‌های ذخیره‌شده',
                prefixIcon: Icon(Icons.folder_open_rounded),
              ),
              items: [
                for (final item in savedSquads)
                  DropdownMenuItem(value: item.id, child: Text(item.name)),
              ],
              onChanged: (id) {
                if (id == null) return;
                final selected = savedSquads.firstWhere((s) => s.id == id);
                setState(() => squad = selected);
              },
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _pickFormation,
                  icon: const Icon(Icons.account_tree_rounded),
                  label: Text('آرایش ${formation.name}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _editTactics,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('تاکتیک'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: importingScreenshot ? null : _importConsoleScreenshot,
              icon: importingScreenshot
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.document_scanner_rounded),
              label: Text(
                importingScreenshot
                    ? 'در حال شناسایی بازیکنان...'
                    : 'وارد کردن عکس ترکیب کنسول',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _new,
              icon: const Icon(Icons.add_rounded),
              label: const Text('ترکیب جدید'),
            ),
          ),
          const SizedBox(height: 10),
          _Pitch(
            formation: formation,
            players: squad.playersBySlot,
            onTapSlot: _pickPlayer,
            onRemove: _removePlayer,
          ),
          if (squad.bench.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('نیمکت', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: squad.bench.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => _BenchCard(player: squad.bench[index]),
              ),
            ),
          ],
          const SizedBox(height: 22),
          SquadInsightsPanel(
            squad: squad,
            formation: formation,
            chemistry: chemistry,
            onReplace: _replace,
          ),
        ],
      ),
    );
  }
}

class _Pitch extends StatelessWidget {
  const _Pitch({
    required this.formation,
    required this.players,
    required this.onTapSlot,
    required this.onRemove,
  });

  final FormationDefinition formation;
  final Map<String, Player> players;
  final ValueChanged<FormationSlot> onTapSlot;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: .72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: scheme.primary.withValues(alpha: .08),
          border: Border.all(color: scheme.primary.withValues(alpha: .25)),
        ),
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Positioned(
                left: 10,
                right: 10,
                top: c.maxHeight / 2,
                child: Divider(color: scheme.primary.withValues(alpha: .22)),
              ),
              for (final slot in formation.slots)
                Positioned(
                  left: (c.maxWidth - 74) * slot.x,
                  top: (c.maxHeight - 86) * slot.y,
                  child: _SlotCard(
                    slot: slot,
                    player: players[slot.id],
                    onTap: () => onTapSlot(slot),
                    onRemove: () => onRemove(slot.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.player,
    required this.onTap,
    required this.onRemove,
  });

  final FormationSlot slot;
  final Player? player;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 74,
      height: 86,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: player == null ? null : onRemove,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (player == null)
                  Icon(Icons.add_circle_outline_rounded, color: scheme.primary)
                else
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: player!.imageUrl.isEmpty
                        ? null
                        : NetworkImage(player!.imageUrl),
                    child: player!.imageUrl.isEmpty
                        ? Text(player!.rating.toString())
                        : null,
                  ),
                const SizedBox(height: 4),
                Text(
                  player?.name ?? slot.position,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                ),
                if (player != null)
                  Text(
                    '${player!.rating} • ${slot.position}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenchCard extends StatelessWidget {
  const _BenchCard({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text('${player.rating} • ${player.position}'),
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
  String query = '';

  @override
  Widget build(BuildContext context) {
    final normalized = widget.slotPosition.toUpperCase();
    final filtered = widget.players.where((player) {
      if (widget.selectedIds.contains(player.id)) return false;
      final positions = <String>{
        player.position.toUpperCase(),
        ...player.positions.map((p) => p.toUpperCase()),
      };
      final matchesPosition = positions.contains(normalized);
      final matchesQuery = query.isEmpty ||
          player.name.toLowerCase().contains(query.toLowerCase());
      return matchesPosition && matchesQuery;
    }).take(80).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                onChanged: (value) => setState(() => query = value.trim()),
                decoration: InputDecoration(
                  labelText: 'بازیکن مناسب ${widget.slotPosition}',
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('بازیکن سازگار پیدا نشد'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, index) {
                        final player = filtered[index];
                        return ListTile(
                          onTap: () => Navigator.pop(context, player),
                          leading: CircleAvatar(
                            backgroundImage: player.imageUrl.isEmpty
                                ? null
                                : NetworkImage(player.imageUrl),
                            child: player.imageUrl.isEmpty
                                ? Text(player.rating.toString())
                                : null,
                          ),
                          title: Text(
                            player.name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${player.rating} • ${player.position} • ${player.version}',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
