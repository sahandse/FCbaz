import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../more/more_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../notifications/notification_repository.dart';
import '../players/players_screen.dart';
import '../search/search_screen.dart';
import '../settings/app_settings_repository.dart';
import '../squad/squad_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.settings,
    required this.onSettingsChanged,
    super.key,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final notificationRepository = NotificationRepository();

  int index = 0;
  int unread = 0;

  @override
  void initState() {
    super.initState();
    _refreshUnread();
  }

  Future<void> _refreshUnread() async {
    final count = await notificationRepository.unreadCount();
    if (!mounted) return;
    setState(() => unread = count);
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationCenterScreen(),
      ),
    );
    await _refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onOpenPlayers: () => setState(() => index = 1),
        onOpenSearch: () => setState(() => index = 2),
        onOpenSquad: () => setState(() => index = 3),
        onOpenMore: () => setState(() => index = 4),
      ),
      const PlayersScreen(),
      const SearchScreen(),
      const SquadScreen(),
      MoreScreen(
        settings: widget.settings,
        onSettingsChanged: widget.onSettingsChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 62,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'FC',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FCBaz',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
                ),
                Text(
                  'همراه فارسی FC27',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : unread.toString()),
            child: IconButton(
              onPressed: _openNotifications,
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: 'اعلان‌ها',
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_2_outlined),
              selectedIcon: Icon(Icons.groups_2_rounded),
              label: 'بازیکنان',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_rounded),
              label: 'جستجو',
            ),
            NavigationDestination(
              icon: Icon(Icons.stadium_outlined),
              selectedIcon: Icon(Icons.stadium_rounded),
              label: 'تیم‌ساز',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'بیشتر',
            ),
          ],
        ),
      ),
    );
  }
}
