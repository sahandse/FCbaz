import 'package:flutter/material.dart';

import '../../core/network/live_fc27_catalog.dart';
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
  final liveCatalog = LiveFc27Catalog();

  bool checkingUpdate = false;
  UpdateCheckResult? updateResult;
  String? updateError;

  bool checkingData = true;
  LiveCatalogHealth? dataHealth;
  String? dataError;

  @override
  void initState() {
    super.initState();
    _refreshDataHealth();
  }

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

  Future<void> _refreshDataHealth({bool forceRefresh = false}) async {
    setState(() {
      checkingData = true;
      dataError = null;
    });
    try {
      final health = await liveCatalog.health(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() => dataHealth = health);
    } catch (e) {
      if (!mounted) return;
      setState(() => dataError = e.toString());
    } finally {
      if (mounted) setState(() => checkingData = false);
    }
  }

  String _timeLabel(DateTime? value) {
    if (value == null) return 'نامشخص';
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)}  ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final health = dataHealth;
    final scheme = Theme.of(context).colorScheme;

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
            'دیتای زنده FC27',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          health?.isFresh == true
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_sync_rounded,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              health?.isFresh == true
                                  ? 'Catalog زنده و معتبر'
                                  : 'وضعیت Catalog',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              health?.fromPersistentCache == true
                                  ? 'نمایش از آخرین کش سالم دستگاه'
                                  : 'منابع عمومی EA + FUT.GG',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: checkingData
                            ? null
                            : () => _refreshDataHealth(forceRefresh: true),
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'بروزرسانی دیتا',
                      ),
                    ],
                  ),
                  if (checkingData) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  if (dataError != null) ...[
                    const SizedBox(height: 12),
                    Text(dataError!),
                  ],
                  if (health != null) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DataChip(label: '${health.players} بازیکن'),
                        _DataChip(label: '${health.sbcs} SBC'),
                        _DataChip(label: '${health.evolutions} Evo'),
                        _DataChip(label: '${health.objectives} Objective'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'آخرین Sync: ${_timeLabel(health.generatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${health.sources.length} منبع عمومی ثبت‌شده',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
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
                    'نسخه فعلی: ${UpdateRepository.currentVersion}',
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
                              ? 'نسخه جدید ${updateResult!.release!.normalizedVersion} منتشر شده است.'
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
          const Card(
            child: ListTile(
              leading: Icon(Icons.security_rounded),
              title: Text('سیاست داده FCBaz'),
              subtitle: Text(
                'داده ساختگی برای بازیکن، قیمت، SBC، Evo یا بازار تولید نمی‌شود.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}
