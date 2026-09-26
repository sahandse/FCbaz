import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  const NotificationPreferences({
    this.priceAlerts = true,
    this.objectiveDeadlines = true,
    this.evolutionDeadlines = true,
    this.deadlineHours = 24,
  });

  final bool priceAlerts;
  final bool objectiveDeadlines;
  final bool evolutionDeadlines;
  final int deadlineHours;

  NotificationPreferences copyWith({
    bool? priceAlerts,
    bool? objectiveDeadlines,
    bool? evolutionDeadlines,
    int? deadlineHours,
  }) => NotificationPreferences(
        priceAlerts: priceAlerts ?? this.priceAlerts,
        objectiveDeadlines: objectiveDeadlines ?? this.objectiveDeadlines,
        evolutionDeadlines: evolutionDeadlines ?? this.evolutionDeadlines,
        deadlineHours: deadlineHours ?? this.deadlineHours,
      );
}

class NotificationPreferencesRepository {
  static const _priceKey = 'fcbaz_notify_price';
  static const _objectiveKey = 'fcbaz_notify_objective_deadline';
  static const _evolutionKey = 'fcbaz_notify_evolution_deadline';
  static const _hoursKey = 'fcbaz_notify_deadline_hours';

  Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      priceAlerts: prefs.getBool(_priceKey) ?? true,
      objectiveDeadlines: prefs.getBool(_objectiveKey) ?? true,
      evolutionDeadlines: prefs.getBool(_evolutionKey) ?? true,
      deadlineHours: (prefs.getInt(_hoursKey) ?? 24).clamp(1, 168),
    );
  }

  Future<void> save(NotificationPreferences value) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_priceKey, value.priceAlerts),
      prefs.setBool(_objectiveKey, value.objectiveDeadlines),
      prefs.setBool(_evolutionKey, value.evolutionDeadlines),
      prefs.setInt(_hoursKey, value.deadlineHours.clamp(1, 168)),
    ]);
  }
}
