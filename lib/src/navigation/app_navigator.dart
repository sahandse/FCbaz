import 'package:flutter/material.dart';

import '../../features/evolutions/presentation/evolutions_screen.dart';
import '../../features/home/objectives_screen.dart';
import '../../features/market/presentation/market_screen.dart';
import '../../features/notifications/notification_center_screen.dart';
import '../../features/notifications/notification_settings_screen.dart';
import '../../features/players/domain/player.dart';
import '../../features/players/presentation/player_compare_screen.dart';
import '../../features/players/presentation/player_details_screen.dart';
import '../../features/squad/squad_screen.dart';
import '../app_dependencies.dart';

/// Single entry point for app navigation and notification deep links.
abstract final class AppNavigator {
  static Future<T?> push<T>(BuildContext context, Widget screen) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute<T>(builder: (_) => screen));
  }

  static Future<T?> replace<T>(BuildContext context, Widget screen) {
    return Navigator.of(
      context,
    ).pushReplacement<T, T>(MaterialPageRoute<T>(builder: (_) => screen));
  }

  static Future<void> playerDetails(BuildContext context, Player player) async {
    await push<void>(context, PlayerDetailsScreen(player: player));
  }

  static Future<void> playerById(BuildContext context, String playerId) async {
    final player = await AppDependencies.instance.players.getPlayer(playerId);
    if (!context.mounted) return;
    await playerDetails(context, player);
  }

  static Future<void> compare(BuildContext context, Player player) async {
    await push<void>(
      context,
      PlayerCompareScreen(initialPlayers: [player]),
    );
  }

  static Future<void> objectives(BuildContext context) async {
    await push<void>(context, const ObjectivesScreen());
  }

  static Future<void> evolutions(BuildContext context) async {
    await push<void>(context, const EvolutionsScreen());
  }

  static Future<void> notifications(BuildContext context) async {
    await push<void>(context, const NotificationCenterScreen());
  }

  static Future<void> notificationSettings(BuildContext context) async {
    await push<void>(context, const NotificationSettingsScreen());
  }

  static Future<void> market(BuildContext context) async {
    await push<void>(context, const MarketScreen());
  }

  static Future<void> squad(BuildContext context) async {
    await push<void>(context, const SquadScreen());
  }

  /// Opens the target of a system-notification payload (`type:id`).
  static Future<void> openNotificationPayload(
    BuildContext context,
    String payload,
  ) async {
    final separator = payload.indexOf(':');
    if (separator <= 0 || separator == payload.length - 1) return;
    final type = payload.substring(0, separator);
    final id = payload.substring(separator + 1);

    switch (type) {
      case 'player':
        await playerById(context, id);
      case 'objective':
        await objectives(context);
      case 'evolution':
        await evolutions(context);
    }
  }
}
