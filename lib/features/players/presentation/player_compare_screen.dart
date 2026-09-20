import 'package:flutter/material.dart';

import '../data/player_repository.dart';
import '../domain/player.dart';

class PlayerCompareScreen extends StatefulWidget {
  const PlayerCompareScreen({
    this.initialPlayers = const [],
    super.key,
  });

  final List<Player> initialPlayers;

  @override
  State<PlayerCompareScreen> createState() => _PlayerCompareScreenState();
}

class _PlayerCompareScreenState extends State<PlayerCompareScreen> {
  final repository = PlayerRepository();
  late List<Player> selected =
      widget.initialPlayers.take(4).toList(growable: true);

  List<Player> allPlayers = const [];
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await repository.getPlayers();
      if (!mounted) return;
      setState(() => allPlayers = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addPlayer() async {
    if (selected.length >= 4 || allPlayers.isEmpty) return;

    final player = await showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ComparePicker(
        players: allPlayers
            .where((p) => !selected.any((s) => s.id == p.id))
            .toList(),
      ),
    );

    if (player == null) return;

    try {
      final full = await repository.getPlayer(player.id);
      if (!mounted) return;
      setState(() => selected.add(full));
    } catch (_) {
      if (!mounted) return;
      setState(() => selected.add(player));
    }
  }

  int _bestValue(int Function(Player p) getter) {
    if (selected.isEmpty) return 0;
    return selected.map(getter).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مقایسه بازیکنان'),
        actions: [
          IconButton(
            onPressed: selected.length < 4 && !loading ? _addPlayer : null,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'مقایسه واقعی ۲ تا ۴ کارت',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Statها و جزئیات مستقیماً از دیتای واقعی هر کارت خوانده می‌شوند.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          if (error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off_rounded),
                title: const Text('لیست بازیکنان کامل در دسترس نیست'),
                subtitle: Text(error!),
              ),
            ),
          if (selected.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.compare_arrows_rounded, size: 44),
                    const SizedBox(height: 10),
                    const Text(
                      'بازیکنی برای مقایسه انتخاب نشده',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: loading ? null : _addPlayer,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('افزودن بازیکن'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 184,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selected.length + (selected.length < 4 ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  if (index == selected.length) {
                    return SizedBox(
                      width: 132,
                      child: Card(
                        child: InkWell(
                          onTap: loading ? null : _addPlayer,
                          borderRadius: BorderRadius.circular(22),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 36),
                              SizedBox(height: 8),
                              Text('افزودن'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final p = selected[index];
                  return SizedBox(
                    width: 132,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundImage: p.imageUrl.isEmpty
                                  ? null
                                  : NetworkImage(p.imageUrl),
                              child: p.imageUrl.isEmpty
                                  ? Text(p.rating.toString())
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(p.rating.toString() + ' • ' + p.position),
                            const Spacer(),
                            IconButton(
                              onPressed: () =>
                                  setState(() => selected.removeAt(index)),
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _CompareRow(
              label: 'OVR',
              players: selected,
              getter: (p) => p.rating,
              best: _bestValue((p) => p.rating),
            ),
            _CompareRow(
              label: 'PAC',
              players: selected,
              getter: (p) => p.pace,
              best: _bestValue((p) => p.pace),
            ),
            _CompareRow(
              label: 'SHO',
              players: selected,
              getter: (p) => p.shooting,
              best: _bestValue((p) => p.shooting),
            ),
            _CompareRow(
              label: 'PAS',
              players: selected,
              getter: (p) => p.passing,
              best: _bestValue((p) => p.passing),
            ),
            _CompareRow(
              label: 'DRI',
              players: selected,
              getter: (p) => p.dribbling,
              best: _bestValue((p) => p.dribbling),
            ),
            _CompareRow(
              label: 'DEF',
              players: selected,
              getter: (p) => p.defending,
              best: _bestValue((p) => p.defending),
            ),
            _CompareRow(
              label: 'PHY',
              players: selected,
              getter: (p) => p.physical,
              best: _bestValue((p) => p.physical),
            ),
            _CompareRow(
              label: 'SM',
              players: selected,
              getter: (p) => p.skillMoves,
              best: _bestValue((p) => p.skillMoves),
              suffix: '★',
            ),
            _CompareRow(
              label: 'WF',
              players: selected,
              getter: (p) => p.weakFoot,
              best: _bestValue((p) => p.weakFoot),
              suffix: '★',
            ),
            const SizedBox(height: 16),
            if (selected.any((p) => p.playStylesPlus.isNotEmpty))
              _TextCompareSection(
                title: 'PlayStyles+',
                players: selected,
                getter: (p) => p.playStylesPlus,
              ),
            if (selected.any((p) => p.playStyles.isNotEmpty))
              _TextCompareSection(
                title: 'PlayStyles',
                players: selected,
                getter: (p) => p.playStyles,
              ),
            if (selected.any((p) => p.roles.isNotEmpty))
              _TextCompareSection(
                title: 'Roles',
                players: selected,
                getter: (p) => p.roles,
              ),
          ],
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.players,
    required this.getter,
    required this.best,
    this.suffix = '',
  });

  final String label;
  final List<Player> players;
  final int Function(Player p) getter;
  final int best;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            for (final p in players)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: getter(p) == best
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    getter(p).toString() + suffix,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: getter(p) == best
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TextCompareSection extends StatelessWidget {
  const _TextCompareSection({
    required this.title,
    required this.players,
    required this.getter,
  });

  final String title;
  final List<Player> players;
  final List<String> Function(Player p) getter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            for (final player in players) ...[
              Text(
                player.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                getter(player).isEmpty ? '—' : getter(player).join(' • '),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComparePicker extends StatefulWidget {
  const _ComparePicker({required this.players});
  final List<Player> players;

  @override
  State<_ComparePicker> createState() => _ComparePickerState();
}

class _ComparePickerState extends State<_ComparePicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final data = widget.players.where((p) {
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.clubName.toLowerCase().contains(q) ||
          p.position.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

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
                  hintText: 'جستجوی کارت...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 10),
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
                          backgroundImage: p.imageUrl.isEmpty
                              ? null
                              : NetworkImage(p.imageUrl),
                          child: p.imageUrl.isEmpty
                              ? Text(p.rating.toString())
                              : null,
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          p.rating.toString() +
                              ' • ' +
                              p.position +
                              ' • ' +
                              p.version,
                        ),
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
