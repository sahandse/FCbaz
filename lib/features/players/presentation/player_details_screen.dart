import 'package:flutter/material.dart';

import '../domain/player.dart';

class PlayerDetailsScreen extends StatelessWidget {
  const PlayerDetailsScreen({required this.player, super.key});
  final Player player;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('PAC', player.pace),
      ('SHO', player.shooting),
      ('PAS', player.passing),
      ('DRI', player.dribbling),
      ('DEF', player.defending),
      ('PHY', player.physical),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('جزئیات بازیکن')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: .18),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                  backgroundImage: player.imageUrl.isEmpty ? null : NetworkImage(player.imageUrl),
                  child: player.imageUrl.isEmpty ? const Icon(Icons.person_rounded, size: 50) : null,
                ),
                const SizedBox(height: 14),
                Text(
                  player.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(player.rating.toString() + ' • ' + player.position + ' • ' + player.version),
                const SizedBox(height: 6),
                Text(
                  player.clubName + ' • ' + player.leagueName + ' • ' + player.nationName,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (_, i) {
              final stat = stats[i];
              return Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat.$2.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(stat.$1),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Skill Moves / Weak Foot'),
              subtitle: Text(player.skillMoves.toString() + '★  /  ' + player.weakFoot.toString() + '★'),
            ),
          ),
          if (player.positions.isNotEmpty)
            Card(
              child: ListTile(
                title: const Text('پست‌های جایگزین'),
                subtitle: Text(player.positions.join('، ')),
              ),
            ),
        ],
      ),
    );
  }
}
