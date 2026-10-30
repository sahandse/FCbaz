import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'squad_screenshot_analyzer.dart';

import '../players/domain/player.dart';
import 'domain/chemistry_engine.dart';
import 'domain/squad_auto_fill_service.dart';
import 'domain/squad_chemistry_optimizer.dart';
import 'domain/squad_formation_migrator.dart';
import 'domain/squad_models.dart';
import 'domain/squad_text_exporter.dart';
import 'presentation/chemistry_links.dart';
import 'presentation/formation_picker_sheet.dart';
import 'presentation/squad_insights_panel.dart';
import 'presentation/tactics_editor_sheet.dart';
import 'package:fcbaz/src/app_dependencies.dart';
import 'package:fcbaz/src/share/share_card.dart';
import 'package:fcbaz/src/share/share_service.dart';
import 'package:fcbaz/src/ui/section_heading.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';

class SquadScreenPro extends StatefulWidget {
  const SquadScreenPro({super.key});

  @override
  State<SquadScreenPro> createState() => _SquadScreenProState();
}

class _SquadScreenProState extends State<SquadScreenPro> {
  final squadRepository = AppDependencies.instance.squads;
  final playerRepository = AppDependencies.instance.players;
  final chemistryEngine = const ChemistryEngineFC27();
  final formationMigrator = const SquadFormationMigrator();
  final chemistryOptimizer = const SquadChemistryOptimizer();
  final screenshotAnalyzer = SquadScreenshotAnalyzer();
  final shareService = ShareService();
  bool importingScreenshot = false;
  bool sharingSquad = false;
  bool autoFilling = false;

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ترکیب ذخیره شد')));
  }

  Future<void> _new() async {
    setState(() => squad = _newSquad());
  }

  Future<void> _shareSquad() async {
    if (sharingSquad) return;
    if (squad.playersBySlot.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'برای اشتراک‌گذاری اول بازیکن‌ها را به ترکیب اضافه کن.',
          ),
        ),
      );
      return;
    }

    setState(() => sharingSquad = true);
    try {
      final rows = <ShareCardRow>[
        for (final slot in formation.slots)
          if (squad.playersBySlot[slot.id] != null)
            ShareCardRow(
              position: slot.position,
              name: squad.playersBySlot[slot.id]!.name,
              rating: squad.playersBySlot[slot.id]!.rating,
            ),
      ];
      if (rows.isEmpty) {
        throw StateError('ترکیب بازیکن قابل اشتراک‌گذاری ندارد.');
      }
      final averageRating =
          (rows.fold<int>(0, (sum, row) => sum + row.rating) / rows.length)
              .round();
      final data = ShareCardData(
        eyebrow: 'SQUAD BUILDER',
        title: squad.name.trim().isEmpty ? 'ترکیب من' : squad.name,
        subtitle: '${formation.name} • FC 27',
        metrics: [
          ShareCardMetric(label: 'ریتینگ', value: faDigits(averageRating)),
          ShareCardMetric(
            label: 'شیمی',
            value: faDigits(
              '${chemistry.total}/${chemistry.maxForFilledPlayers}',
            ),
          ),
          ShareCardMetric(label: 'بازیکن', value: faDigits(rows.length)),
        ],
        rows: rows,
        footer: 'FCBaz • دستیار فارسی FC 27',
      );
      final pngBytes = await const ShareCardRenderer().renderPng(data);
      final outcome = await shareService.shareImage(
        pngBytes: pngBytes,
        fileName: 'fcbaz-squad.png',
        fallbackText: shareCardToText(data),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(shareOutcomeMessage(outcome))));
    } catch (error) {
      debugPrint('Squad share failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ساخت کارت تصویری ترکیب ممکن نشد.')),
      );
    } finally {
      if (mounted) setState(() => sharingSquad = false);
    }
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
            '${faDigits(migrated.movedToBench)} بازیکن به نیمکت منتقل شد • '
            '${faDigits(migrated.outOfPositionPlacements)} بازیکن موقتاً خارج از پست قرار گرفت',
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
            content: Text(
              'بازیکنی از تصویر شناسایی نشد؛ تصویر واضح‌تر و کامل‌تری انتخاب کن.',
            ),
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
                  '${faDigits(analysis.matchedCount)} بازیکن از تصویر شناسایی شد.',
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(analysis.playersBySlot[slot.id]!.name),
                          ),
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
            'ترکیب وارد شد؛ شیمی فعلی ${faDigits('${chemistry.total}/${chemistry.maxForFilledPlayers}')} است. پیشنهادها پایین صفحه نمایش داده می‌شوند.',
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

  Future<void> _autoFill() async {
    if (autoFilling) return;
    final hasEmptySlot = formation.slots.any(
      (slot) => !squad.playersBySlot.containsKey(slot.id),
    );
    if (!hasEmptySlot) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('همه جای‌های ترکیب پر هستند.')),
      );
      return;
    }

    setState(() => autoFilling = true);
    try {
      final catalog = await playerRepository.getPlayers();
      if (!mounted) return;
      final result = const SquadAutoFillService().fillEmptySlots(
        formation: formation,
        current: squad.playersBySlot,
        catalog: catalog,
        manager: squad.manager,
        excludedIds: squad.bench.map((p) => p.id).toSet(),
      );

      if (result.filledCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'برای جای‌های خالی، بازیکن مناسبی در کاتالوگ پیدا نشد. انتخاب دستی را امتحان کن.',
            ),
          ),
        );
        return;
      }

      setState(
        () => squad = squad.copyWith(playersBySlot: result.playersBySlot),
      );
      final missing = result.unfilledPositions;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            missing.isEmpty
                ? '${faDigits(result.filledCount)} جای خالی با بازیکنان کاتالوگ پر شد؛ ترکیب کامل است. ذخیره را فراموش نکن.'
                : '${faDigits(result.filledCount)} جای خالی پر شد؛ برای ${missing.join('، ')} بازیکن مناسبی در کاتالوگ نبود.',
          ),
        ),
      );
    } catch (error) {
      debugPrint('Squad auto fill failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خواندن کاتالوگ بازیکنان ممکن نشد؛ دوباره تلاش کن.'),
        ),
      );
    } finally {
      if (mounted) setState(() => autoFilling = false);
    }
  }

  Future<void> _copySquadText() async {
    if (squad.playersBySlot.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('برای خروجی متنی اول بازیکن‌ها را به ترکیب اضافه کن.'),
        ),
      );
      return;
    }
    final text = const SquadTextExporter().export(squad);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('متن ترکیب کپی شد و آماده اشتراک‌گذاری است.'),
      ),
    );
  }

  Future<void> _pickPlayer(FormationSlot slot) async {
    List<Player> players;
    try {
      players = await playerRepository.getPlayers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
    setState(
      () => squad = squad.copyWith(
        playersBySlot: players,
        playerConfigs: configs,
      ),
    );
  }

  void _replace(String slotId, Player replacement) {
    HapticFeedback.selectionClick();
    final players = Map<String, Player>.from(squad.playersBySlot)
      ..[slotId] = replacement;
    final configs = Map<String, SquadPlayerConfig>.from(squad.playerConfigs)
      ..remove(slotId);
    setState(
      () => squad = squad.copyWith(
        playersBySlot: players,
        playerConfigs: configs,
      ),
    );
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
                      '${formation.name} • ${faDigits('${squad.playersBySlot.length}/11')} بازیکن',
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
              IconButton.filledTonal(
                onPressed: sharingSquad ? null : _shareSquad,
                icon: sharingSquad
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                tooltip: 'اشتراک‌گذاری تصویری',
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: _copySquadText,
                icon: const Icon(Icons.copy_all_rounded),
                tooltip: 'کپی متن ترکیب',
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
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed:
                  autoFilling ||
                      squad.playersBySlot.length == formation.slots.length
                  ? null
                  : _autoFill,
              icon: autoFilling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high_rounded),
              label: Text(
                autoFilling
                    ? 'در حال پر کردن جای‌های خالی...'
                    : 'پر کردن خودکار جای‌های خالی',
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
            chemistry: chemistry,
            onTapSlot: _pickPlayer,
            onRemove: _removePlayer,
          ),
          if (squad.bench.isNotEmpty) ...[
            const SizedBox(height: 18),
            const SectionHeading(title: 'نیمکت', eyebrow: 'BENCH'),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: squad.bench.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) =>
                    _BenchCard(player: squad.bench[index]),
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
    required this.chemistry,
    required this.onTapSlot,
    required this.onRemove,
  });

  final FormationDefinition formation;
  final Map<String, Player> players;
  final ChemistryResult chemistry;
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
          builder: (context, c) {
            final links = buildChemistryLinks(
              formation: formation,
              players: players,
              chemistryBySlot: chemistry.bySlot,
              size: Size(c.maxWidth, c.maxHeight),
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _PitchLinesPainter(color: scheme.primary),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ChemistryLinks(
                    links: links,
                    strongColor: scheme.primary,
                    weakColor: scheme.secondary,
                  ),
                ),
                for (final slot in formation.slots)
                  Positioned(
                    left: (c.maxWidth - 74) * slot.x,
                    top: (c.maxHeight - 86) * slot.y,
                    child: _SlotCard(
                      slot: slot,
                      player: players[slot.id],
                      chemistry: chemistry.bySlot[slot.id] ?? 0,
                      onTap: () => onTapSlot(slot),
                      onRemove: () => onRemove(slot.id),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PitchLinesPainter extends CustomPainter {
  const _PitchLinesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: .16);

    const inset = 12.0;
    final field = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    if (field.width <= 0 || field.height <= 0) return;

    canvas.drawRRect(
      RRect.fromRectAndRadius(field, Radius.circular(field.shortestSide * .07)),
      stroke,
    );
    canvas.drawLine(
      Offset(field.left, field.center.dy),
      Offset(field.right, field.center.dy),
      stroke,
    );
    canvas.drawCircle(field.center, field.width * .11, stroke);
    canvas.drawCircle(
      field.center,
      1.8,
      Paint()..color = color.withValues(alpha: .22),
    );

    final boxWidth = field.width * .5;
    final boxHeight = field.height * .11;
    final goalWidth = field.width * .24;
    final goalHeight = boxHeight * .42;
    canvas.drawRect(
      Rect.fromLTWH(
        field.center.dx - boxWidth / 2,
        field.top,
        boxWidth,
        boxHeight,
      ),
      stroke,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        field.center.dx - boxWidth / 2,
        field.bottom - boxHeight,
        boxWidth,
        boxHeight,
      ),
      stroke,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        field.center.dx - goalWidth / 2,
        field.top,
        goalWidth,
        goalHeight,
      ),
      stroke,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        field.center.dx - goalWidth / 2,
        field.bottom - goalHeight,
        goalWidth,
        goalHeight,
      ),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _PitchLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.player,
    required this.chemistry,
    required this.onTap,
    required this.onRemove,
  });

  final FormationSlot slot;
  final Player? player;
  final int chemistry;
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
        child: Stack(
          children: [
            Positioned.fill(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
                onLongPress: player == null
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        onRemove();
                      },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (player == null)
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: scheme.primary,
                        )
                      else
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: player!.imageUrl.isEmpty
                              ? null
                              : NetworkImage(player!.imageUrl),
                          child: player!.imageUrl.isEmpty
                              ? Text(faDigits(player!.rating))
                              : null,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        player?.name ?? slot.position,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (player != null)
                        Text(
                          '${faDigits(player!.rating)} • ${slot.position}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (player != null)
              Positioned(
                top: 4,
                right: 4,
                child: IgnorePointer(
                  child: ChemistryDiamonds(value: chemistry),
                ),
              ),
          ],
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
              Text('${faDigits(player.rating)} • ${player.position}'),
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
  late final String normalizedPosition;
  late final List<Player> candidates;
  String query = '';
  bool onlyFit = false;

  @override
  void initState() {
    super.initState();
    normalizedPosition = widget.slotPosition.toUpperCase();
    candidates =
        widget.players
            .where((player) => !widget.selectedIds.contains(player.id))
            .toList()
          ..sort((a, b) {
            final aFit = _fits(a);
            final bFit = _fits(b);
            if (aFit != bFit) return aFit ? -1 : 1;
            final byRating = b.rating.compareTo(a.rating);
            return byRating != 0 ? byRating : a.name.compareTo(b.name);
          });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool _fits(Player player) {
    if (normalizedPosition.isEmpty) return true;
    return player.position.toUpperCase() == normalizedPosition ||
        player.positions.any((alt) => alt.toUpperCase() == normalizedPosition);
  }

  List<Player> get visible {
    final q = query.trim().toLowerCase();
    return candidates
        .where((player) {
          if (onlyFit && !_fits(player)) return false;
          if (q.isEmpty) return true;
          return player.name.toLowerCase().contains(q) ||
              player.clubName.toLowerCase().contains(q) ||
              player.leagueName.toLowerCase().contains(q) ||
              player.nationName.toLowerCase().contains(q) ||
              player.version.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final players = visible;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.slotPosition.isEmpty
                          ? 'انتخاب بازیکن'
                          : 'انتخاب بازیکن برای ${widget.slotPosition}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text('${faDigits(players.length)} بازیکن'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TextField(
                controller: controller,
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  hintText: 'نام، باشگاه، لیگ یا ملیت...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'پاک کردن جستجو',
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            controller.clear();
                            setState(() => query = '');
                          },
                        ),
                ),
              ),
            ),
            if (widget.slotPosition.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: FilterChip(
                    label: const Text('فقط پست مناسب'),
                    selected: onlyFit,
                    onSelected: (value) => setState(() => onlyFit = value),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Expanded(
              child: players.isEmpty
                  ? const Center(child: Text('بازیکنی با این مشخصات پیدا نشد'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: players.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final player = players[index];
                        final fit = _fits(player);
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            onTap: () => Navigator.pop(context, player),
                            leading: CircleAvatar(
                              backgroundImage: player.imageUrl.isEmpty
                                  ? null
                                  : NetworkImage(player.imageUrl),
                              child: player.imageUrl.isEmpty
                                  ? Text(faDigits(player.rating))
                                  : null,
                            ),
                            title: Text(
                              player.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              '${faDigits(player.rating)} • ${player.position} • ${player.clubName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: widget.slotPosition.isEmpty
                                ? const Icon(Icons.add_rounded)
                                : Icon(
                                    fit
                                        ? Icons.check_circle_rounded
                                        : Icons.warning_amber_rounded,
                                    color: fit
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.error,
                                  ),
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
