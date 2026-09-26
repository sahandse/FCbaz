import 'package:flutter/material.dart';

import '../evolutions/presentation/evolutions_screen.dart';
import '../home/home_dashboard_screen.dart';
import '../home/objectives_screen.dart';
import '../more/more_screen.dart';
import '../notifications/deadline_alert_service.dart';
import '../notifications/notification_center_screen.dart';
import '../notifications/notification_repository.dart';
import '../notifications/price_alert_service.dart';
import '../notifications/system_notification_service.dart';
import '../players/data/player_repository.dart';
import '../players/players_screen.dart';
import '../players/presentation/player_details_screen.dart';
import '../search/search_screen.dart';
import '../settings/app_settings_repository.dart';
import '../squad/squad_screen_pro.dart';
import 'app_navigation_repository.dart';

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
      // Best-effort only; app usage must never depend on live alert checks.
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
        MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: player)),
      );
    } catch (_) {}
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
      MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
    );
    await _refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
        if (!didPop && index != 0) _selectTab(0);
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 56,
          titleSpacing: 14,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: .20),
                      blurRadius: 18,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'FC',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: Color(0xFF10140C),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: -.8,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FCBaz', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  Text(
                    'ULTIMATE TEAM • FC27',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: .4),
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
            const SizedBox(width: 5),
          ],
        ),
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF090D0A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outline.withValues(alpha: .75)),
              boxShadow: const [
                BoxShadow(color: Color(0x55000000), blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: _selectTab,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'خانه'),
                NavigationDestination(icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style_rounded), label: 'بازیکنان'),
                NavigationDestination(icon: Icon(Icons.search_rounded), label: 'جستجو'),
                NavigationDestination(icon: Icon(Icons.stadium_outlined), selectedIcon: Icon(Icons.stadium_rounded), label: 'تیم‌ساز'),
                NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view_rounded), label: 'بیشتر'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
