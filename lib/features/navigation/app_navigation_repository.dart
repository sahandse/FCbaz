import 'package:shared_preferences/shared_preferences.dart';

class AppNavigationRepository {
  static const _tabKey = 'fcbaz_last_tab';
  static const _pendingPlayerKey = 'fcbaz_pending_player_id';

  Future<int> loadTab() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_tabKey) ?? 0;
    return value.clamp(0, 4);
  }

  Future<void> saveTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tabKey, index.clamp(0, 4));
  }

  Future<void> setPendingPlayer(String playerId) async {
    if (playerId.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingPlayerKey, playerId.trim());
  }

  Future<String?> takePendingPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_pendingPlayerKey);
    if (value != null) await prefs.remove(_pendingPlayerKey);
    return value;
  }
}
