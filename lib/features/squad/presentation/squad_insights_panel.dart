import 'package:flutter/material.dart';

import '../../players/domain/player.dart';
import '../domain/chemistry_engine.dart';
import '../domain/squad_insights_service.dart';
import '../domain/squad_models.dart';

class SquadInsightsPanel extends StatefulWidget {
  const SquadInsightsPanel({
    required this.squad,
    required this.formation,
    required this.chemistry,
    required this.onReplace,
    super.key,
  });

  final SquadStateModel squad;
  final FormationDefinition formation;
  final ChemistryResult chemistry;
  final void Function(String slotId, Player player) onReplace;

  @override
  State<SquadInsightsPanel> createState() => _SquadInsightsPanelState();
}

class _SquadInsightsPanelState extends State<SquadInsightsPanel> {
  final service = SquadInsightsService();

  int maxBudget = 250000;
  String platform = 'console';
  bool loadingSuggestions = false;
  List<SquadReplacementSuggestion> suggestions = const [];

  SquadInsights get insights => service.analyze(
        squad: widget.squad,
        formation: widget.formation,
        chemistry: widget.chemistry,
      );

  Future<void> _loadSuggestions() async {
    setState(() {
      loadingSuggestions = true;
      suggestions = const [];
    });

    final result = await service.replacementSuggestions(
      squad: widget.squad,
      formation: widget.formation,
      chemistry: widget.chemistry,
      maxBudget: maxBudget,
      platform: platform,
    );

    if (!mounted) return;
    setState(() {
      suggestions = result;
      loadingSuggestions = false;
    });
  }

  String _coins(int value) {
    if (value >= 1000000) {
      final n = value / 1000000;
      return '${n.toStringAsFixed(n >= 10 ? 0 : 1)}M';
    }
    if (value >= 1000) {
      final n = value / 1000;
      return '${n.toStringAsFixed(n >= 100 ? 0 : 1)}K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = insights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تحلیل ترکیب',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.formation.name} • تحلیل محلی با داده واقعی کارت‌ها',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            _ChemistryBadge(chemistry: widget.chemistry),
          ],
        ),
        const SizedBox(height: 14),
        _TacticsSummary(tactics: widget.squad.tactics),
        const SizedBox(height: 12),
        _ChemistryBreakdown(
          squad: widget.squad,
          formation: widget.formation,
          chemistry: widget.chemistry,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ScoreCard(
                label: 'امتیاز متا',
                value: data.metaScore.toStringAsFixed(1),
                icon: Icons.auto_graph_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ScoreCard(
                label: 'حمله',
                value: data.attackScore.toStringAsFixed(0),
                icon: Icons.flash_on_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ScoreCard(
                label: 'میانه',
                value: data.midfieldScore.toStringAsFixed(0),
                icon: Icons.blur_circular_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ScoreCard(
                label: 'دفاع',
                value: data.defenseScore.toStringAsFixed(0),
                icon: Icons.shield_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniMetric(
                label: 'میانگین ریتینگ',
                value: data.averageRating.toStringAsFixed(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniMetric(
                label: 'PlayStyles+',
                value: data.playStylesPlusCount.toString(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniMetric(
                label: 'Role تنظیم‌شده',
                value: data.roleConfiguredCount.toString(),
              ),
            ),
          ],
        ),
        if (data.weaknesses.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('نقاط قابل بهبود', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final issue in data.weaknesses) ...[
            Card(
              child: ListTile(
                leading: Icon(
                  issue.severity >= 3
                      ? Icons.error_outline_rounded
                      : issue.severity == 2
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                ),
                title: Text(
                  issue.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(issue.detail),
              ),
            ),
            const SizedBox(height: 7),
          ],
        ],
        const SizedBox(height: 18),
        Text('پیشنهاد تعویض با قیمت واقعی', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: maxBudget,
                decoration: const InputDecoration(labelText: 'بودجه هر کارت'),
                items: const [
                  DropdownMenuItem(value: 50000, child: Text('50K')),
                  DropdownMenuItem(value: 100000, child: Text('100K')),
                  DropdownMenuItem(value: 250000, child: Text('250K')),
                  DropdownMenuItem(value: 500000, child: Text('500K')),
                  DropdownMenuItem(value: 1000000, child: Text('1M')),
                  DropdownMenuItem(value: 5000000, child: Text('5M')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => maxBudget = value);
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 116,
              child: DropdownButtonFormField<String>(
                initialValue: platform,
                decoration: const InputDecoration(labelText: 'بازار'),
                items: const [
                  DropdownMenuItem(value: 'console', child: Text('کنسول')),
                  DropdownMenuItem(value: 'pc', child: Text('PC')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => platform = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: loadingSuggestions || widget.squad.playersBySlot.isEmpty
                ? null
                : _loadSuggestions,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('پیدا کردن ارتقای واقعی'),
          ),
        ),
        if (loadingSuggestions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final suggestion in suggestions) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _PlayerAvatar(player: suggestion.currentPlayer),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_back_rounded),
                        const SizedBox(width: 8),
                        _PlayerAvatar(player: suggestion.replacement),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion.replacement.name,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                '${suggestion.replacement.rating} • ${suggestion.replacement.position} • ${_coins(suggestion.price)} سکه',
                              ),
                              Text(
                                'Meta +${suggestion.scoreGain.toStringAsFixed(1)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => widget.onReplace(
                          suggestion.slotId,
                          suggestion.replacement,
                        ),
                        child: const Text('جایگزین در ترکیب'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ] else if (!loadingSuggestions)
          Text(
            'هنوز پیشنهادی بارگذاری نشده است. جستجو فقط با داده واقعی بازار انجام می‌شود.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}

class _ChemistryBadge extends StatelessWidget {
  const _ChemistryBadge({required this.chemistry});

  final ChemistryResult chemistry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = chemistry.maxForFilledPlayers;
    final full = max > 0 && chemistry.total == max;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (full ? scheme.primary : scheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            '${chemistry.total}/${max == 0 ? 33 : max}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: full ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
          Text(
            'شیمی',
            style: TextStyle(
              fontSize: 10,
              color: full ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TacticsSummary extends StatelessWidget {
  const _TacticsSummary({required this.tactics});

  final TacticProfile tactics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: .45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tactics.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (tactics.code.trim().isNotEmpty)
                Chip(label: Text(tactics.code.trim())),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.sync_alt_rounded,
                label: 'ساخت بازی',
                value: tactics.buildUpStyle.isEmpty ? 'تنظیم نشده' : tactics.buildUpStyle,
              ),
              _InfoPill(
                icon: Icons.shield_outlined,
                label: 'رویکرد دفاعی',
                value: tactics.defensiveApproach.isEmpty
                    ? 'تنظیم نشده'
                    : tactics.defensiveApproach,
              ),
              _InfoPill(
                icon: Icons.height_rounded,
                label: 'ارتفاع خط',
                value: tactics.lineHeight > 0 ? tactics.lineHeight.toString() : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChemistryBreakdown extends StatelessWidget {
  const _ChemistryBreakdown({
    required this.squad,
    required this.formation,
    required this.chemistry,
  });

  final SquadStateModel squad;
  final FormationDefinition formation;
  final ChemistryResult chemistry;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    for (final slot in formation.slots) {
      final player = squad.playersBySlot[slot.id];
      final detail = chemistry.details[slot.id];
      if (player == null || detail == null) continue;
      final config = squad.playerConfigs[slot.id];
      items.add(
        _ChemistryPlayerRow(
          player: player,
          position: slot.position,
          detail: detail,
          config: config,
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: chemistry.hasOutOfPositionPlayers,
        leading: const Icon(Icons.hub_rounded),
        title: const Text(
          'جزئیات شیمی تیم',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          chemistry.filledSlots == 0
              ? 'بازیکنی در ترکیب نیست'
              : '${chemistry.inPositionSlots} بازیکن در پست معتبر • ${chemistry.missingChemistry} شیمی تا سقف',
        ),
        children: items.isEmpty
            ? const [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('برای دیدن جزئیات، بازیکن به ترکیب اضافه کن.'),
                ),
              ]
            : items,
      ),
    );
  }
}

class _ChemistryPlayerRow extends StatelessWidget {
  const _ChemistryPlayerRow({
    required this.player,
    required this.position,
    required this.detail,
    required this.config,
  });

  final Player player;
  final String position;
  final ChemistrySlotDetail detail;
  final SquadPlayerConfig? config;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final role = config?.role.trim() ?? '';
    final focus = config?.focus.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: player.imageUrl.isEmpty ? null : NetworkImage(player.imageUrl),
            child: player.imageUrl.isEmpty ? Text(player.rating.toString()) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  detail.inPosition
                      ? '$position • باشگاه ${detail.clubCount} • لیگ ${detail.leagueCount} • کشور ${detail.nationCount}'
                      : '$position • خارج از پست معتبر',
                  style: TextStyle(
                    fontSize: 11,
                    color: detail.inPosition
                        ? scheme.onSurfaceVariant
                        : scheme.error,
                  ),
                ),
                if (role.isNotEmpty || focus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (role.isNotEmpty) _TinyTag(text: role),
                        if (focus.isNotEmpty) _TinyTag(text: focus),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${detail.chemistry}/3',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: detail.chemistry == 3 ? scheme.primary : scheme.onSurface,
                ),
              ),
              if (detail.managerMatch)
                Icon(Icons.person_rounded, size: 14, color: scheme.primary),
              if (detail.specialCard)
                Icon(Icons.auto_awesome_rounded, size: 14, color: scheme.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text('$label: $value', style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  const _TinyTag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 19),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundImage: player.imageUrl.isEmpty ? null : NetworkImage(player.imageUrl),
      child: player.imageUrl.isEmpty ? Text(player.rating.toString()) : null,
    );
  }
}
