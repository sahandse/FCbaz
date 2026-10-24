import 'package:shared_preferences/shared_preferences.dart';

class AppNavigationRepository {
  static const _tabKey = 'fcbaz_last_tab';
  static const _tabSchemaKey = 'fcbaz_tab_schema';
  static const _tabSchema = 2;
  static const _pendingPlayerKey = 'fcbaz_pending_player_id';

  Future<int> loadTab() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_tabKey) ?? 0;
    if ((prefs.getInt(_tabSchemaKey) ?? 1) >= _tabSchema) {
      return _normalize(value);
    }

    // Schema 2 folded the old search tab (2) into Cards (1).
    final migrated = value == 2 ? 1 : _normalize(value);
    await prefs.setInt(_tabKey, migrated);
    await prefs.setInt(_tabSchemaKey, _tabSchema);
    return migrated;
  }

  Future<void> saveTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tabKey, _normalize(index));
    await prefs.setInt(_tabSchemaKey, _tabSchema);
  }

  int _normalize(int value) => value < 0 || value > 4 ? 0 : value;

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
