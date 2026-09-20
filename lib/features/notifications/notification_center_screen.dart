import 'package:flutter/material.dart';

import 'notification_repository.dart';
import 'price_alert_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final repository = NotificationRepository();
  final alertService = PriceAlertService();

  bool loading = true;
  bool checking = false;
  List<FCBazNotification> items = const [];

  @override
  void initState() {
    super.initState();
    _load(markRead: true);
  }

  Future<void> _load({bool markRead = false}) async {
    setState(() => loading = true);
    if (markRead) await repository.markAllRead();
    final data = await repository.getAll();

    if (!mounted) return;
    setState(() {
      items = data;
      loading = false;
    });
  }

  Future<void> _checkPrices() async {
    setState(() => checking = true);
    final result = await alertService.checkNow();
    await repository.markAllRead();
    final data = await repository.getAll();

    if (!mounted) return;
    setState(() {
      items = data;
      checking = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.triggered > 0
              ? result.triggered.toString() + ' هشدار جدید ثبت شد'
              : 'قیمت ' + result.checked.toString() + ' کارت بررسی شد',
        ),
      ),
    );
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    return local.year.toString() +
        '/' +
        local.month.toString().padLeft(2, '0') +
        '/' +
        local.day.toString().padLeft(2, '0') +
        '  ' +
        local.hour.toString().padLeft(2, '0') +
        ':' +
        local.minute.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اعلان‌ها'),
        actions: [
          IconButton(
            onPressed: checking ? null : _checkPrices,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'بررسی قیمت‌ها',
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
        onRefresh: _checkPrices,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (checking)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 70),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 42),
                      SizedBox(height: 10),
                      Text(
                        'اعلان جدیدی نداری',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'هشدارهای قیمت واقعی Watchlist اینجا ثبت می‌شوند.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final item in items) ...[
                Card(
                  child: ListTile(
                    leading: Icon(
                      item.type == 'price_alert'
                          ? Icons.price_check_rounded
                          : Icons.notifications_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.body),
                        const SizedBox(height: 4),
                        Text(
                          _time(item.createdAt),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        await repository.delete(item.id);
                        await _load();
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}
