import 'package:flutter/material.dart';

import '../evolutions/presentation/evolutions_screen.dart';
import '../home/home_dashboard_screen.dart';
import '../home/objectives_screen.dart';
import '../players/data/player_repository.dart';
import '../players/presentation/player_details_screen.dart';
import 'app_navigation_repository.dart';
import '../more/more_screen.dart';
import '../notifications/deadline_alert_service.dart';
import '../notifications/notification_center_screen.dart';
import '../notifications/notification_repository.dart';
import '../notifications/price_alert_service.dart';
import '../notifications/system_notification_service.dart';
import '../players/players_screen.dart';
import '../search/search_screen.dart';
import '../settings/app_settings_repository.dart';
import '../squad/squad_screen_pro.dart';

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

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  final notificationRepository = NotificationRepository();
  final priceAlertService = PriceAlertService();
  final deadlineAlertService = DeadlineAlertService();
  final systemNotifications = SystemNotificationService.instance;
  final navigationRepository = AppNavigationRepository();
  final playerRepository = PlayerRepository();

  int index = 0;
  int unread = 0;
  bool checkingLocalAlerts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNavigation();
    _refreshLocalAlerts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _refreshLocalAlerts();
    _openPendingPlayer();
    _openPendingSystemNotification();
  }

  Future<void> _refreshLocalAlerts() async {
    if (checkingLocalAlerts) return;
    checkingLocalAlerts = true;
    try {
      await Future.wait([
        priceAlertService.checkNow(),
        deadlineAlertService.checkNow(),
      ]);
    } catch (_) {
      // Live alert checks are best-effort and never block app usage.
    } finally {
      checkingLocalAlerts = false;
    }
    await _refreshUnread();
  }

  Future<void> _initializeNavigation() async {
    final saved = await navigationRepository.loadTab();
    if (!mounted) return;
    setState(() => index = saved);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingPlayer();
      _openPendingSystemNotification();
    });
  }

  Future<void> _selectTab(int value) async {
    if (!mounted) return;
    setState(() => index = value);
    await navigationRepository.saveTab(value);
  }

  Future<void> _openPendingPlayer() async {
    final playerId = await navigationRepository.takePendingPlayer();
    if (playerId == null || playerId.isEmpty || !mounted) return;

    try {
      final player = await playerRepository.getPlayer(playerId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlayerDetailsScreen(player: player),
        ),
      );
    } catch (_) {
      // If the player cannot be fetched, keep the app usable without fake data.
    }
  }

  Future<void> _openPendingSystemNotification() async {
    final payload = await systemNotifications.consumePendingPayload();
    if (payload == null || payload.isEmpty || !mounted) return;

    final separator = payload.indexOf(':');
    if (separator <= 0 || separator == payload.length - 1) return;
    final type = payload.substring(0, separator);
    final id = payload.substring(separator + 1);

    if (type == 'player') {
      try {
        final player = await playerRepository.getPlayer(id);
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: player)),
        );
      } catch (_) {}
      return;
    }

    if (type == 'objective') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ObjectivesScreen()),
      );
      return;
    }

    if (type == 'evolution') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EvolutionsScreen()),
      );
    }
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
      HomeDashboardScreen(
        onOpenPlayers: () => _selectTab(1),
        onOpenSearch: () => _selectTab(2),
        onOpenSquad: () => _selectTab(3),
        onOpenMore: () => _selectTab(4),
      ),
      const PlayersScreen(),
      const SearchScreen(),
      const SquadScreenPro(),
      MoreScreen(
        settings: widget.settings,
        onSettingsChanged: widget.onSettingsChanged,
      ),
    ];

    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && index != 0) {
          _selectTab(0);
        }
      },
      child: Scaffold(
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
            onDestinationSelected: _selectTab,
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
      ),
    );
  }
}
