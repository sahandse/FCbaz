import 'package:flutter/material.dart';

class Fc27ReferenceScreen extends StatelessWidget {
  const Fc27ReferenceScreen({super.key});

  static const _playStyles = <String, List<String>>{
    'گلزنی': [
      'آکروباتیک',
      'چیپ',
      'ضربه ایستگاهی',
      'شوت کات‌دار',
      'بازی‌ساز لحظه‌ای',
      'شوت زمینی',
      'شوت قدرتی',
      'سرزنی دقیق',
    ],
    'پاس': [
      'پاس عمقی',
      'پاس خلاقانه',
      'پاس بلند',
      'پاس تیز',
      'تیکی‌تاکا',
      'ارسال',
    ],
    'کنترل توپ': [
      'لمس اول',
      'مقاوم زیر فشار',
      'شتاب با توپ',
      'تکنیکی',
      'مهارتی',
    ],
    'دفاع': [
      'برتری هوایی',
      'پیش‌بینی',
      'بلاک',
      'قطع پاس',
      'مهار مستقیم',
      'تکل',
    ],
    'فیزیکی': [
      'قدرت بدنی',
      'فشار فیزیکی',
      'پرتاب بلند',
      'شتاب اولیه',
      'استقامت',
    ],
    'دروازه‌بانی': [
      'جمع‌کردن ارسال',
      'دفع واکنشی',
      'پوشش دور',
      'پرتاب بلند',
      'بازی با پا',
      'خروج سریع',
    ],
  };

  static const _roles = <String, List<String>>{
    'مهاجم': ['مهاجم هدف', 'شکارچی گل', 'مهاجم پیشرو', '۹ کاذب'],
    'وینگر': ['وینگر', 'مهاجم داخلی', 'بازی‌ساز کناری'],
    'هافبک هجومی': ['بازی‌ساز', 'مهاجم سایه', 'شماره ۱۰ کلاسیک', 'هاف‌وینگر'],
    'هافبک مرکزی': ['باکس‌تو‌باکس', 'بازی‌ساز', 'بازی‌ساز عقب', 'نگهدارنده', 'هاف‌وینگر'],
    'هافبک دفاعی': ['نگهدارنده', 'بازی‌ساز عقب', 'نفوذ از عقب', 'مدافع میانی', 'هافبک کناری'],
    'مدافع کناری': ['فول‌بک', 'وینگ‌بک', 'فول‌بک کاذب', 'وینگ‌بک معکوس', 'وینگ‌بک هجومی'],
    'مدافع میانی': ['مدافع', 'استاپر', 'مدافع کناری', 'مدافع بازی‌ساز'],
    'دروازه‌بان': ['دروازه‌بان', 'بازی با پا', 'سوئیپر کیپر'],
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('راهنمای سبک‌ها و نقش‌ها')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: scheme.primary.withValues(alpha: .2)),
            ),
            child: const Text(
              'این بخش بر اساس ساختار فعلی FC27 تهیه شده و برای فهم بهتر اطلاعات واقعی بازیکن‌ها در FCBaz استفاده می‌شود. داده نمایشی بازیکن در این صفحه وجود ندارد.',
              style: TextStyle(fontWeight: FontWeight.w700, height: 1.6),
            ),
          ),
          const SizedBox(height: 20),
          Text('سبک‌های بازی', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          for (final entry in _playStyles.entries) ...[
            _GroupCard(title: entry.key, items: entry.value),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          Text('نقش‌های بازیکن', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          for (final entry in _roles.entries) ...[
            _GroupCard(title: entry.key, items: entry.value),
            const SizedBox(height: 10),
          ],
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('نکته'),
              subtitle: const Text(
                'در صفحه هر بازیکن، فقط PlayStyle و Roleهایی نمایش داده می‌شوند که واقعاً از منبع داده همان کارت دریافت شده باشند.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items)
                  Chip(
                    avatar: const Icon(Icons.bolt_rounded, size: 16),
                    label: Text(item),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
