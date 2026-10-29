import 'package:flutter/material.dart';

import '../../players/domain/player.dart';
import '../../players/presentation/player_card.dart';
import '../domain/draft_models.dart';
import 'package:fcbaz/src/app_dependencies.dart';

class DraftScreen extends StatefulWidget {
  const DraftScreen({super.key});

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  final _service = const DraftSimulatorService();
  final _playerRepo = AppDependencies.instance.players;
  DraftState? _draftState;
  List<Player> _allPlayers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayersAndInitDraft();
  }

  Future<void> _loadPlayersAndInitDraft() async {
    setState(() => _isLoading = true);
    final players = await _playerRepo.getPlayers();
    if (mounted) {
      setState(() {
        _allPlayers = players;
        _draftState = _service.createNewDraft(allPlayers: players);
        _isLoading = false;
      });
    }
  }

  void _onSelectPlayer(Player player) {
    if (_draftState == null || _draftState!.isCompleted) return;
    setState(() {
      _service.pickPlayer(_draftState!, player, _allPlayers);
    });
  }

  void _restartDraft() {
    setState(() {
      _draftState = _service.createNewDraft(allPlayers: _allPlayers);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('شبیه‌ساز درافت (FUT Draft)'),
        actions: [
          IconButton(
            tooltip: 'درافت جدید',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _restartDraft,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_draftState == null
                ? const Center(child: Text('خطا در شروع درافت'))
                : _buildDraftContent(scheme)),
    );
  }

  Widget _buildDraftContent(ColorScheme scheme) {
    final state = _draftState!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Live Scoreboard
        _DraftScoreboard(
          formation: state.formation,
          currentSlot: state.currentSlotIndex,
          totalSlots: state.slots.length,
          rating: state.teamRating,
          chemistry: state.teamChemistry,
          isCompleted: state.isCompleted,
        ),
        const SizedBox(height: 16),

        if (state.isCompleted) ...[
          _DraftCompletedSummary(state: state, onRestart: _restartDraft),
        ] else ...[
          // Current Selection Prompt
          _SlotPromptHeader(slot: state.slots[state.currentSlotIndex]),
          const SizedBox(height: 12),
          // 5 Player Cards Choices
          Text(
            'یکی از ۵ بازیکن پیشنهادی را انتخاب کنید:',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          for (final candidate in state.currentChoices) ...[
            InkWell(
              onTap: () => _onSelectPlayer(candidate),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: PlayerCard(player: candidate),
              ),
            ),
          ],
        ],

        const SizedBox(height: 16),
        // Selected Squad Grid preview
        Text(
          'ترکیب انتخاب شده تا الان:',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _PicksList(state: state),
      ],
    );
  }
}

class _DraftScoreboard extends StatelessWidget {
  const _DraftScoreboard({
    required this.formation,
    required this.currentSlot,
    required this.totalSlots,
    required this.rating,
    required this.chemistry,
    required this.isCompleted,
  });

  final String formation;
  final int currentSlot;
  final int totalSlots;
  final int rating;
  final int chemistry;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.primary.withValues(alpha: .28),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سیستم: $formation',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted
                      ? 'تکمیل شد ✓'
                      : 'موقعیت ${currentSlot + 1} از $totalSlots',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 20, color: scheme.outlineVariant),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricItem(
                label: 'ریتینگ تیم (Rating)',
                value: '$rating',
                color: scheme.primary,
                icon: Icons.star_rounded,
              ),
              _MetricItem(
                label: 'شیمی تیم (Chemistry)',
                value: '$chemistry / 33',
                color: scheme.secondary,
                icon: Icons.science_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SlotPromptHeader extends StatelessWidget {
  const _SlotPromptHeader({required this.slot});
  final DraftSlot slot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              slot.position,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: scheme.onPrimary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'انتخاب ${slot.titleFa} (${slot.position})',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftCompletedSummary extends StatelessWidget {
  const _DraftCompletedSummary({required this.state, required this.onRestart});
  final DraftState state;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: .4)),
      ),
      child: Column(
        children: [
          Icon(Icons.emoji_events_rounded, size: 52, color: scheme.primary),
          const SizedBox(height: 10),
          const Text(
            '🎉 درافت با موفقیت بسته شد!',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'ریتینگ نهایی: ${state.teamRating}  |  شیمی نهایی: ${state.teamChemistry} از ۳۳',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('شروع یک درافت دیگر'),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PicksList extends StatelessWidget {
  const _PicksList({required this.state});
  final DraftState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < state.slots.length; i++) ...[
          _PickRow(slot: state.slots[i], player: state.picks[i]),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({required this.slot, this.player});
  final DraftSlot slot;
  final Player? player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: player != null
              ? scheme.primary.withValues(alpha: .2)
              : scheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: player != null
                  ? scheme.primary.withValues(alpha: .15)
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              slot.position,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: player != null
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: player != null
                ? Text(
                    player!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  )
                : Text(
                    'انتخاب نشده (${slot.titleFa})',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
          ),
          if (player != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${player!.rating}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: scheme.onPrimary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
