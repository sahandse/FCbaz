import '../evolutions/data/evolution_repository.dart';
import '../home/home_repository.dart';
import 'notification_preferences_repository.dart';
import 'notification_repository.dart';

class DeadlineAlertResult {
  const DeadlineAlertResult({
    required this.checkedObjectives,
    required this.checkedEvolutions,
    required this.triggered,
  });

  final int checkedObjectives;
  final int checkedEvolutions;
  final int triggered;
}

class DeadlineAlertService {
  DeadlineAlertService({
    HomeRepository? homeRepository,
    EvolutionRepository? evolutionRepository,
    NotificationRepository? notificationRepository,
    NotificationPreferencesRepository? preferencesRepository,
  })  : homeRepository = homeRepository ?? HomeRepository(),
        evolutionRepository = evolutionRepository ?? EvolutionRepository(),
        notificationRepository = notificationRepository ?? NotificationRepository(),
        preferencesRepository = preferencesRepository ?? NotificationPreferencesRepository();

  final HomeRepository homeRepository;
  final EvolutionRepository evolutionRepository;
  final NotificationRepository notificationRepository;
  final NotificationPreferencesRepository preferencesRepository;

  Future<DeadlineAlertResult> checkNow() async {
    final preferences = await preferencesRepository.load();
    final now = DateTime.now();
    final threshold = Duration(hours: preferences.deadlineHours);
    var checkedObjectives = 0;
    var checkedEvolutions = 0;
    var triggered = 0;

    if (preferences.objectiveDeadlines) {
      try {
        final objectives = await homeRepository.getObjectives(forceRefresh: true);
        checkedObjectives = objectives.length;
        for (final objective in objectives) {
          final expiresAt = objective.expiresAt;
          if (expiresAt == null) continue;
          final remaining = expiresAt.difference(now);
          if (remaining.isNegative || remaining > threshold) continue;
          final key = 'objective_deadline:${objective.id}:${expiresAt.toIso8601String()}';
          final states = await notificationRepository.alertStates();
          if (states[key] == 'sent') continue;
          await notificationRepository.add(
            FCBazNotification(
              id: key,
              type: 'objective_deadline',
              title: 'مهلت Objective رو به پایان است',
              body: '${objective.title} تا ${_remainingLabel(remaining)} دیگر فعال است.',
              createdAt: now,
              destinationId: objective.id,
            ),
          );
          await notificationRepository.setAlertState(key, 'sent');
          triggered++;
        }
      } catch (_) {
        // No notification is fabricated when live objective data is unavailable.
      }
    }

    if (preferences.evolutionDeadlines) {
      try {
        final evolutions = await evolutionRepository.getActive();
        checkedEvolutions = evolutions.length;
        for (final evolution in evolutions) {
          final expiresAt = evolution.expiresAt;
          if (expiresAt == null) continue;
          final remaining = expiresAt.difference(now);
          if (remaining.isNegative || remaining > threshold) continue;
          final key = 'evolution_deadline:${evolution.id}:${expiresAt.toIso8601String()}';
          final states = await notificationRepository.alertStates();
          if (states[key] == 'sent') continue;
          await notificationRepository.add(
            FCBazNotification(
              id: key,
              type: 'evolution_deadline',
              title: 'مهلت Evolution رو به پایان است',
              body: '${evolution.title} تا ${_remainingLabel(remaining)} دیگر فعال است.',
              createdAt: now,
              destinationId: evolution.id,
            ),
          );
          await notificationRepository.setAlertState(key, 'sent');
          triggered++;
        }
      } catch (_) {
        // No notification is fabricated when live evolution data is unavailable.
      }
    }

    return DeadlineAlertResult(
      checkedObjectives: checkedObjectives,
      checkedEvolutions: checkedEvolutions,
      triggered: triggered,
    );
  }

  String _remainingLabel(Duration value) {
    if (value.inHours < 1) return '${value.inMinutes.clamp(1, 59)} دقیقه';
    if (value.inHours < 24) return '${value.inHours} ساعت';
    final days = (value.inHours / 24).ceil();
    return '$days روز';
  }
}
