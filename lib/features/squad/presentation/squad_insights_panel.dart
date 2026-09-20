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
      return n.toStringAsFixed(n >= 10 ? 0 : 1) + 'M';
    }
    if (value >= 1000) {
      final n = value / 1000;
      return n.toStringAsFixed(n >= 100 ? 0 : 1) + 'K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = insights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Squad Insights',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Meta Score یک امتیاز تحلیلی FCBaz است؛ بر اساس Stat، Chemistry، PlayStyles+ و Role fit.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ScoreCard(
                label: 'Meta',
                value: data.metaScore.toStringAsFixed(1),
                icon: Icons.auto_graph_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ScoreCard(
                label: 'Attack',
                value: data.attackScore.toStringAsFixed(0),
                icon: Icons.flash_on_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ScoreCard(
                label: 'Mid',
                value: data.midfieldScore.toStringAsFixed(0),
                icon: Icons.blur_circular_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ScoreCard(
                label: 'Def',
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
                label: 'AVG OVR',
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
        const SizedBox(height: 16),
        if (data.weaknesses.isNotEmpty) ...[
          Text(
            'نقاط قابل بهبود',
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
                  color: issue.severity >= 3
                      ? Colors.redAccent
                      : issue.severity == 2
                          ? Colors.orangeAccent
                          : Theme.of(context).colorScheme.primary,
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
        Text(
          'پیشنهاد تعویض با قیمت واقعی',
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
                  DropdownMenuItem(
                    value: 'console',
                    child: Text('Console'),
                  ),
                  DropdownMenuItem(
                    value: 'pc',
                    child: Text('PC'),
                  ),
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
            label: const Text('پیدا کردن Upgrade واقعی'),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                suggestion.replacement.rating.toString() +
                                    ' • ' +
                                    suggestion.replacement.position +
                                    ' • ' +
                                    _coins(suggestion.price) +
                                    ' Coins',
                              ),
                              Text(
                                'Meta +' +
                                    suggestion.scoreGain.toStringAsFixed(1),
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary,
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
            'پیشنهادی بارگذاری نشده؛ با دکمه بالا از دیتای واقعی بازار بررسی کن.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
      ],
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
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
  });

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
      backgroundImage:
          player.imageUrl.isEmpty ? null : NetworkImage(player.imageUrl),
      child: player.imageUrl.isEmpty ? Text(player.rating.toString()) : null,
    );
  }
}
