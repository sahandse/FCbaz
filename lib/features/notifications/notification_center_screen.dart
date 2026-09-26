import 'package:flutter/material.dart';

import '../evolutions/presentation/evolutions_screen.dart';
import '../home/objectives_screen.dart';
import '../players/data/player_repository.dart';
import '../players/presentation/player_details_screen.dart';
import 'deadline_alert_service.dart';
import 'notification_repository.dart';
import 'notification_settings_screen.dart';
import 'price_alert_service.dart';

enum _NotificationFilter { all, price, deadline }

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final repository = NotificationRepository();
  final priceAlertService = PriceAlertService();
  final deadlineAlertService = DeadlineAlertService();
  final playerRepository = PlayerRepository();

  bool loading = true;
  bool checking = false;
  List<FCBazNotification> items = const [];
  _NotificationFilter filter = _NotificationFilter.all;

  List<FCBazNotification> get visibleItems {
    if (filter == _NotificationFilter.price) {
      return items.where((e) => e.type == 'price_alert').toList();
    }
    if (filter == _NotificationFilter.deadline) {
      return items.where((e) => e.type.endsWith('_deadline')).toList();
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _load(markRead: true);
  }

  Future<void> _load({bool markRead = false}) async {
    if (mounted) setState(() => loading = true);
    if (markRead) await repository.markAllRead();
    final data = await repository.getAll();
    if (!mounted) return;
    setState(() {
      items = data;
      loading = false;
    });
  }

  Future<void> _checkAll() async {
    setState(() => checking = true);
    final price = await priceAlertService.checkNow();
    final deadlines = await deadlineAlertService.checkNow();
    final data = await repository.getAll();
    if (!mounted) return;
    setState(() {
      items = data;
      checking = false;
    });
    final total = price.triggered + deadlines.triggered;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          total > 0
              ? '$total هشدار جدید ثبت شد'
              : 'بررسی انجام شد؛ هشدار جدیدی وجود ندارد',
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
    );
  }

  Future<void> _openItem(FCBazNotification item) async {
    if (item.type == 'price_alert' && item.playerId != null) {
      try {
        final player = await playerRepository.getPlayer(item.playerId!);
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: player)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }
    if (item.type == 'objective_deadline') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ObjectivesScreen()),
      );
      return;
    }
    if (item.type == 'evolution_deadline') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EvolutionsScreen()),
      );
    }
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}  '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  IconData _icon(FCBazNotification item) {
    if (item.type == 'price_alert') return Icons.price_check_rounded;
    if (item.type == 'objective_deadline') return Icons.flag_rounded;
    if (item.type == 'evolution_deadline') return Icons.auto_awesome_rounded;
    return Icons.notifications_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final data = visibleItems;
    final priceCount = items.where((e) => e.type == 'price_alert').length;
    final deadlineCount = items.where((e) => e.type.endsWith('_deadline')).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مرکز اعلان‌ها'),
        actions: [
          IconButton(
            onPressed: checking ? null : _checkAll,
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'بررسی هشدارها',
          ),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'تنظیمات اعلان‌ها',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'read') {
                await repository.markAllRead();
                await _load();
              } else if (value == 'clear') {
                await repository.clear();
                await _load();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'read', child: Text('خواندن همه')),
              PopupMenuItem(value: 'clear', child: Text('پاک کردن همه')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(child: _Metric(label: 'همه', value: items.length, icon: Icons.notifications_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _Metric(label: 'قیمت', value: priceCount, icon: Icons.price_check_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _Metric(label: 'مهلت', value: deadlineCount, icon: Icons.schedule_rounded)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('همه'),
                  selected: filter == _NotificationFilter.all,
                  onSelected: (_) => setState(() => filter = _NotificationFilter.all),
                ),
                ChoiceChip(
                  label: const Text('قیمت'),
                  selected: filter == _NotificationFilter.price,
                  onSelected: (_) => setState(() => filter = _NotificationFilter.price),
                ),
                ChoiceChip(
                  label: const Text('مهلت‌ها'),
                  selected: filter == _NotificationFilter.deadline,
                  onSelected: (_) => setState(() => filter = _NotificationFilter.deadline),
                ),
              ],
            ),
            if (checking)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            const SizedBox(height: 12),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 70),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (data.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.notifications_none_rounded, size: 42),
                      const SizedBox(height: 10),
                      const Text('اعلانی در این دسته نداری', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Text(
                        'قیمت‌ها و مهلت‌ها فقط با داده واقعی بررسی می‌شوند.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final item in data) ...[
                Card(
                  child: ListTile(
                    onTap: () => _openItem(item),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: .11),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(_icon(item), color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.body),
                        const SizedBox(height: 4),
                        Text(_time(item.createdAt), style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        await repository.delete(item.id);
                        await _load();
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'حذف',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 12),
            Text(
              'هشدارهای این صفحه داخل خود FCBaz هستند و هنگام بازشدن یا بررسی دستی اپ به‌روزرسانی می‌شوند.',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 5),
        Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
