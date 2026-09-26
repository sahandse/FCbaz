import 'package:flutter/material.dart';

import '../settings/app_settings_repository.dart';
import 'background_sync_status_repository.dart';
import 'notification_preferences_repository.dart';
import 'system_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final preferencesRepository = NotificationPreferencesRepository();
  final appSettingsRepository = AppSettingsRepository();
  final syncStatusRepository = BackgroundSyncStatusRepository();
  final systemNotifications = SystemNotificationService.instance;

  NotificationPreferences preferences = const NotificationPreferences();
  AppSettings appSettings = const AppSettings();
  BackgroundSyncStatus syncStatus = const BackgroundSyncStatus();
  bool loading = true;
  bool systemEnabled = false;
  int pendingSystemNotifications = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      preferencesRepository.load(),
      appSettingsRepository.load(),
      systemNotifications.notificationsEnabled(),
      systemNotifications.pendingCount(),
      syncStatusRepository.load(),
    ]);
    if (!mounted) return;
    setState(() {
      preferences = values[0] as NotificationPreferences;
      appSettings = values[1] as AppSettings;
      systemEnabled = values[2] as bool;
      pendingSystemNotifications = values[3] as int;
      syncStatus = values[4] as BackgroundSyncStatus;
      loading = false;
    });
  }

  String _date(DateTime? value) {
    if (value == null) return 'هنوز اجرا نشده';
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)} - ${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _requestSystemPermission() async {
    final granted = await systemNotifications.requestPermission();
    final pending = await systemNotifications.pendingCount();
    if (!mounted) return;
    setState(() {
      systemEnabled = granted;
      pendingSystemNotifications = pending;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'اعلان سیستمی Android فعال شد'
              : 'مجوز اعلان داده نشد؛ هشدارها همچنان داخل FCBaz ثبت می‌شوند',
        ),
      ),
    );
  }

  Future<void> _savePreferences(NotificationPreferences value) async {
    setState(() => preferences = value);
    await preferencesRepository.save(value);
  }

  Future<void> _setPriceAlerts(bool value) async {
    await _savePreferences(preferences.copyWith(priceAlerts: value));
    final next = appSettings.copyWith(priceAlertsEnabled: value);
    setState(() => appSettings = next);
    await appSettingsRepository.save(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات اعلان‌ها')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            systemEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  systemEnabled
                                      ? 'اعلان سیستمی فعال است'
                                      : 'مجوز اعلان سیستمی غیرفعال است',
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  systemEnabled
                                      ? '$pendingSystemNotifications اعلان زمان‌بندی‌شده در Android'
                                      : 'برای دریافت هشدار بیرون از اپ، مجوز Android را فعال کن.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (!systemEnabled)
                            FilledButton.tonal(
                              onPressed: _requestSystemPermission,
                              child: const Text('فعال‌سازی'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                syncStatus.lastError == null
                                    ? Icons.sync_rounded
                                    : Icons.sync_problem_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'وضعیت بررسی پس‌زمینه',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('آخرین اجرا: ${_date(syncStatus.lastRunAt)}'),
                          const SizedBox(height: 4),
                          Text('آخرین موفقیت: ${_date(syncStatus.lastSuccessAt)}'),
                          const SizedBox(height: 4),
                          Text('قیمت‌های بررسی‌شده: ${syncStatus.lastChecked}'),
                          const SizedBox(height: 4),
                          Text('هشدارهای فعال‌شده: ${syncStatus.lastTriggered}'),
                          if (syncStatus.lastError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'خطای آخر: ${syncStatus.lastError}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'بررسی قیمت با WorkManager دوره‌ای و کم‌مصرف انجام می‌شود؛ Android زمان دقیق اجرا را تعیین می‌کند.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: preferences.priceAlerts && appSettings.priceAlertsEnabled,
                          onChanged: _setPriceAlerts,
                          secondary: const Icon(Icons.price_check_rounded),
                          title: const Text('هشدار قیمت'),
                          subtitle: const Text('وقتی قیمت واقعی فهرست پیگیری به هدف برسد'),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: preferences.objectiveDeadlines,
                          onChanged: (value) => _savePreferences(
                            preferences.copyWith(objectiveDeadlines: value),
                          ),
                          secondary: const Icon(Icons.flag_rounded),
                          title: const Text('مهلت Objectiveها'),
                          subtitle: const Text('فقط برای Objective دارای زمان پایان واقعی'),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          value: preferences.evolutionDeadlines,
                          onChanged: (value) => _savePreferences(
                            preferences.copyWith(evolutionDeadlines: value),
                          ),
                          secondary: const Icon(Icons.auto_awesome_rounded),
                          title: const Text('مهلت Evolutionها'),
                          subtitle: const Text('فقط برای Evolution دارای زمان پایان واقعی'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('زمان هشدار مهلت', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'اعلان Android و Notification Center در فاصله انتخاب‌شده قبل از پایان همگام می‌شوند.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: preferences.deadlineHours,
                            decoration: const InputDecoration(labelText: 'فاصله تا پایان'),
                            items: const [
                              DropdownMenuItem(value: 6, child: Text('۶ ساعت')),
                              DropdownMenuItem(value: 12, child: Text('۱۲ ساعت')),
                              DropdownMenuItem(value: 24, child: Text('۱ روز')),
                              DropdownMenuItem(value: 48, child: Text('۲ روز')),
                              DropdownMenuItem(value: 72, child: Text('۳ روز')),
                              DropdownMenuItem(value: 168, child: Text('۷ روز')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              _savePreferences(preferences.copyWith(deadlineHours: value));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'اعلان‌ها کاملاً محلی هستند؛ Firebase، Push Server و حساب کاربری استفاده نمی‌شود. بررسی قیمت در پس‌زمینه فقط با اتصال اینترنت و زمانی که باتری Low نیست اجرا می‌شود.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
