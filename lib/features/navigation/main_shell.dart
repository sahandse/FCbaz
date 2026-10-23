import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../club/presentation/my_club_screen.dart';
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
import '../players/presentation/cards_screen.dart';
import '../players/presentation/player_details_screen.dart';
import '../settings/app_settings_repository.dart';
import '../squad/squad_screen_pro.dart';
import '../../src/theme/fcbaz_theme.dart';
import '../../src/ui/fcbaz_top_bar.dart';
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
  static const _titles = ['خانه', 'کارت‌ها', 'باشگاه', 'تیم', 'بیشتر'];

  final notificationRepository = NotificationRepository();
  final priceAlertService = PriceAlertService();
  final deadlineAlertService = DeadlineAlertService();
  final systemNotifications = SystemNotificationService.instance;
  final navigationRepository = AppNavigationRepository();
  final playerRepository = PlayerRepository();
  final searchRequests = ValueNotifier<int>(0);

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
    searchRequests.dispose();
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
    if (!mounted || value == index) return;
    HapticFeedback.selectionClick();
    setState(() => index = value);
    await navigationRepository.saveTab(value);
  }

  Future<void> _openGlobalSearch() async {
    if (index != 1) await _selectTab(1);
    if (!mounted) return;
    searchRequests.value++;
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
    final palette = context.palette;
    final pages = [
      HomeDashboardScreen(
        onOpenPlayers: () => _selectTab(1),
        onOpenSearch: _openGlobalSearch,
        onOpenSquad: () => _selectTab(3),
        onOpenMore: () => _selectTab(4),
      ),
      CardsScreen(focusRequests: searchRequests),
      const MyClubScreen(embedded: true),
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
        appBar: FcbazTopBar(
          title: _titles[index],
          onSearch: _openGlobalSearch,
          onNotifications: _openNotifications,
          unread: unread,
        ),
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border(top: BorderSide(color: palette.line)),
          ),
          child: SafeArea(
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
                  icon: Icon(Icons.style_outlined),
                  selectedIcon: Icon(Icons.style_rounded),
                  label: 'کارت‌ها',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: 'باشگاه',
                ),
                NavigationDestination(
                  icon: Icon(Icons.stadium_outlined),
                  selectedIcon: Icon(Icons.stadium_rounded),
                  label: 'تیم',
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
      ),
    );
  }
}
