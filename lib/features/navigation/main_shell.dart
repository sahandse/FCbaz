import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../players/players_screen.dart';
import '../search/search_screen.dart';
import '../squad/squad_screen.dart';
import '../more/more_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.themeMode,
    required this.onToggleTheme,
    super.key,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenPlayers: () => setState(() => index = 1)),
      const PlayersScreen(),
      const SearchScreen(),
      const SquadScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                'FC',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('FCBaz', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.themeMode == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.groups_2_outlined), selectedIcon: Icon(Icons.groups_2_rounded), label: 'بازیکنان'),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: 'جستجو'),
          NavigationDestination(icon: Icon(Icons.stadium_outlined), selectedIcon: Icon(Icons.stadium_rounded), label: 'تیم‌ساز'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'بیشتر'),
        ],
      ),
    );
  }
}
