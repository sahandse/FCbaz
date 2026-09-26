import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/notifications/notification_preferences_repository.dart';
import 'package:fcbaz/features/notifications/notification_repository.dart';

void main() {
  test('notification preserves deadline destination metadata', () {
    final source = FCBazNotification(
      id: 'objective_deadline:123',
      type: 'objective_deadline',
      title: 'مهلت Objective',
      body: 'کمتر از یک روز باقی مانده',
      createdAt: DateTime.utc(2026, 9, 26, 12),
      destinationId: '123',
    );

    final restored = FCBazNotification.fromJson(source.toJson());
    expect(restored.type, 'objective_deadline');
    expect(restored.destinationId, '123');
    expect(restored.playerId, isNull);
  });

  test('notification preferences stay separated by category', () {
    const preferences = NotificationPreferences(
      priceAlerts: false,
      objectiveDeadlines: true,
      evolutionDeadlines: false,
      deadlineHours: 48,
    );

    expect(preferences.priceAlerts, isFalse);
    expect(preferences.objectiveDeadlines, isTrue);
    expect(preferences.evolutionDeadlines, isFalse);
    expect(preferences.deadlineHours, 48);
  });

  test('copyWith changes one notification category without changing others', () {
    const preferences = NotificationPreferences();
    final changed = preferences.copyWith(objectiveDeadlines: false);

    expect(changed.priceAlerts, isTrue);
    expect(changed.objectiveDeadlines, isFalse);
    expect(changed.evolutionDeadlines, isTrue);
  });
}
