import 'package:flutter/material.dart';

import 'app_settings_repository.dart';
import 'update_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.settings,
    required this.onChanged,
    super.key,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings settings = widget.settings;
  final updateRepository = UpdateRepository();

  bool checkingUpdate = false;
  UpdateCheckResult? updateResult;
  String? updateError;

  void _apply(AppSettings value) {
    setState(() => settings = value);
    widget.onChanged(value);
  }

  Future<void> _checkUpdate() async {
    setState(() {
      checkingUpdate = true;
      updateError = null;
    });

    try {
      final result = await updateRepository.check();
      if (!mounted) return;
      setState(() => updateResult = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => updateError = e.toString());
    } finally {
      if (mounted) setState(() => checkingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'ظاهر و زبان',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _apply(settings.copyWith(themeMode: value));
                    }
                  },
                  title: const Text('تاریک'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _apply(settings.copyWith(themeMode: value));
                    }
                  },
                  title: const Text('روشن'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _apply(settings.copyWith(themeMode: value));
                    }
                  },
                  title: const Text('مطابق سیستم'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'بازار و اعلان',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: settings.defaultPlatform,
            decoration: const InputDecoration(labelText: 'پلتفرم قیمت پیش‌فرض'),
            items: const [
              DropdownMenuItem(value: 'console', child: Text('Console')),
              DropdownMenuItem(value: 'pc', child: Text('PC')),
            ],
            onChanged: (value) {
              if (value != null) {
                _apply(settings.copyWith(defaultPlatform: value));
              }
            },
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: settings.priceAlertsEnabled,
            onChanged: (value) =>
                _apply(settings.copyWith(priceAlertsEnabled: value)),
            title: const Text('Price Alerts'),
            subtitle: const Text(
              'هشدار فقط وقتی قیمت واقعی به هدف تعیین‌شده برسد ثبت می‌شود.',
            ),
          ),
          SwitchListTile(
            value: settings.marketRefreshOnResume,
            onChanged: (value) =>
                _apply(settings.copyWith(marketRefreshOnResume: value)),
            title: const Text('بررسی بازار هنگام بازگشت به اپ'),
            subtitle: const Text(
              'هنگام Resume شدن اپ، قیمت Watchlist دوباره بررسی می‌شود.',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'نسخه برنامه',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نسخه فعلی: ' + UpdateRepository.currentVersion,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: checkingUpdate ? null : _checkUpdate,
                      icon: const Icon(Icons.system_update_rounded),
                      label: const Text('بررسی بروزرسانی'),
                    ),
                  ),
                  if (checkingUpdate) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (updateError != null) ...[
                    const SizedBox(height: 10),
                    Text(updateError!),
                  ],
                  if (updateResult != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      updateResult!.release == null
                          ? 'هنوز Release عمومی منتشر نشده است.'
                          : updateResult!.updateAvailable
                              ? 'نسخه جدید ' +
                                  updateResult!.release!.normalizedVersion +
                                  ' منتشر شده است.'
                              : 'نسخه نصب‌شده به‌روز است.',
                      style: TextStyle(
                        color: updateResult!.updateAvailable
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security_rounded),
              title: const Text('سیاست داده FCBaz'),
              subtitle: const Text(
                'داده ساختگی برای بازیکن، قیمت، SBC، Evo یا بازار تولید نمی‌شود.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
