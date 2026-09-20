import 'package:shared_preferences/shared_preferences.dart';

class LocalProfile {
  const LocalProfile({required this.displayName});
  final String displayName;
}

class LocalProfileRepository {
  static const _nameKey = 'fcbaz_profile_display_name';

  Future<LocalProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalProfile(
      displayName: prefs.getString(_nameKey) ?? '',
    );
  }

  Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
  }
}
