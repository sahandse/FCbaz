import 'package:flutter/material.dart';

import '../../players/data/player_repository.dart';
import '../../players/domain/player.dart';
import '../data/my_club_repository.dart';

class MyClubScreen extends StatefulWidget {
  const MyClubScreen({super.key});

  @override
  State<MyClubScreen> createState() => _MyClubScreenState();
}

class _MyClubScreenState extends State<MyClubScreen> {
  final clubRepository = MyClubRepository();
  final playerRepository = PlayerRepository();

  List<MyClubItem> items = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await clubRepository.getAll();
    if (!mounted) return;
    setState(() {
      items = data;
      loading = false;
    });
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

    if (selected == null) return;

    final controller = TextEditingController();
    final price = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(selected.name),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'قیمت خرید',
            suffixText: 'Coins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              int.tryParse(controller.text.trim()) ?? 0,
            ),
            child: const Text('افزودن'),
          ),
        ],
      ),
    );

    if (price == null) return;

    await clubRepository.upsert(
      MyClubItem(
        playerId: selected.id,
        playerName: selected.name,
        rating: selected.rating,
        position: selected.position,
        acquisitionPrice: price,
      ),
    );

    await _load();
  }

  int get totalInvestment =>
      items.fold<int>(0, (sum, e) => sum + e.acquisitionPrice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('باشگاه من'),
        actions: [
          IconButton(
            onPressed: _addPlayer,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'افزودن بازیکن',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'بازیکن',
                        value: items.length.toString(),
                        icon: Icons.groups_2_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'سرمایه',
                        value: totalInvestment.toString(),
                        icon: Icons.monetization_on_outlined,
                      ),
                    ),
                  ],
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
                            'بازیکن‌هایی که در Ultimate Team داری اینجا ثبت کن.',
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
                else
                  for (final item in items) ...[
                    Dismissible(
                      key: ValueKey(item.playerId),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) async {
                        await clubRepository.remove(item.playerId);
                        await _load();
                      },
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete_outline_rounded),
                      ),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(item.rating.toString()),
                          ),
                          title: Text(
                            item.playerName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            item.position + ' • خرید ' + item.acquisitionPrice.toString() + ' Coins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
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
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
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
                        title: Text(p.name),
                        subtitle: Text(
                          p.rating.toString() + ' • ' + p.position + ' • ' + p.clubName,
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
