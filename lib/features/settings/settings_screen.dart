import 'package:flutter/material.dart';

import '../../core/network/live_fc27_catalog.dart';
import '../../src/theme/club_kits.dart';
import '../../src/theme/fcbaz_theme.dart';
import 'app_settings_repository.dart';
import 'update_repository.dart';
import 'package:fcbaz/src/app_dependencies.dart';

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
  final updateRepository = AppDependencies.instance.update;
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
    final activeKit = clubKitFor(settings.accentColorValue);

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('ظاهر و زبان', style: Theme.of(context).textTheme.titleLarge),
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
                  title: const Text('روشن (Paper Pitch)'),
                  subtitle: const Text('کاغذ گرم با خطوط محو زمین فوتبال'),
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
                const Divider(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'کیت رنگی باشگاه (Club Kit)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            activeKit?.label ?? 'کیت سفارشی',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _ClubKitPreview(
                        accent: settings.accentColor,
                        label: activeKit?.label ?? 'کیت سفارشی',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final kit in kClubKits)
                            _ClubKitTile(
                              kit: kit,
                              isSelected:
                                  settings.accentColorValue ==
                                  kit.accent.toARGB32(),
                              onTap: () => _apply(
                                settings.copyWith(
                                  accentColorValue: kit.accent.toARGB32(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
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
          Text('بازار و اعلان', style: Theme.of(context).textTheme.titleLarge),
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
          Text('نسخه برنامه', style: Theme.of(context).textTheme.titleLarge),
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

class _ClubKitPreview extends StatelessWidget {
  const _ClubKitPreview({required this.accent, required this.label});

  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final darkVariant = FCBazTheme.accessibleAccent(accent, Brightness.dark);
    final lightVariant = FCBazTheme.accessibleAccent(accent, Brightness.light);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: .4)),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.alphaBlend(accent.withValues(alpha: .18), scheme.surface),
            scheme.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: .55)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shield_rounded,
                  size: 19,
                  color: FCBazTheme.foregroundOn(accent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'پیش‌نمایش زنده کیت باشگاه',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _KitSwatch(label: 'تم تاریک', color: darkVariant),
              _KitSwatch(label: 'تم روشن', color: lightVariant),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'FCBaz',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KitSwatch extends StatelessWidget {
  const _KitSwatch({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ClubKitTile extends StatelessWidget {
  const _ClubKitTile({
    required this.kit,
    required this.isSelected,
    required this.onTap,
  });

  final ClubKit kit;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      selected: isSelected,
      button: true,
      label: 'کیت ${kit.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Color.alphaBlend(
                    kit.accent.withValues(alpha: .14),
                    scheme.surface,
                  )
                : scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? kit.accent : scheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: kit.accent,
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: FCBazTheme.foregroundOn(kit.accent),
                      )
                    : null,
              ),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kit.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w600,
                    ),
                  ),
                  Text(
                    kit.tagline,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
