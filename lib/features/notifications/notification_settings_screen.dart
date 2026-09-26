import 'package:flutter/material.dart';

import '../settings/app_settings_repository.dart';
import 'notification_preferences_repository.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final preferencesRepository = NotificationPreferencesRepository();
  final appSettingsRepository = AppSettingsRepository();

  NotificationPreferences preferences = const NotificationPreferences();
  AppSettings appSettings = const AppSettings();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      preferencesRepository.load(),
      appSettingsRepository.load(),
    ]);
    if (!mounted) return;
    setState(() {
      preferences = values[0] as NotificationPreferences;
      appSettings = values[1] as AppSettings;
      loading = false;
    });
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: preferences.priceAlerts && appSettings.priceAlertsEnabled,
                        onChanged: _setPriceAlerts,
                        secondary: const Icon(Icons.price_check_rounded),
                        title: const Text('هشدار قیمت'),
                        subtitle: const Text('وقتی قیمت واقعی Watchlist به هدف برسد'),
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
                          'قبل از پایان Objective یا Evolution هشدار داخل اپ ساخته شود.',
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
                            'این تنظیمات مربوط به Notification Center داخل FCBaz است. اعلان سیستمی Android در این مرحله فعال نشده و اپ هیچ Push ساختگی ایجاد نمی‌کند.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
