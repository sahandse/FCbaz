part of '../squad_screen.dart';

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
      final aFit =
          a.position == widget.slotPosition ||
          a.positions.contains(widget.slotPosition);
      final bFit =
          b.position == widget.slotPosition ||
          b.positions.contains(widget.slotPosition);

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
                    final fit =
                        widget.slotPosition.isEmpty ||
                        player.position == widget.slotPosition ||
                        player.positions.contains(widget.slotPosition);

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        onTap: () => Navigator.pop(context, player),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .12),
                          backgroundImage: player.imageUrl.isEmpty
                              ? null
                              : NetworkImage(player.imageUrl),
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
