import 'package:flutter/material.dart';

import '../domain/rating_combination_solver.dart';
import 'sbc_screen.dart';

class SbcHubScreen extends StatefulWidget {
  const SbcHubScreen({super.key});

  @override
  State<SbcHubScreen> createState() => _SbcHubScreenState();
}

class _SbcHubScreenState extends State<SbcHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SBC Center'),
        bottom: TabBar(
          controller: tabs,
          tabs: const [
            Tab(text: 'فعال'),
            Tab(text: 'ترکیب ریتینگ'),
            Tab(text: 'راهنما'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabs,
        children: const [
          SbcScreen(embedded: true),
          _RatingComboTab(),
          _SbcGuideTab(),
        ],
      ),
    );
  }
}

class _RatingComboTab extends StatefulWidget {
  const _RatingComboTab();

  @override
  State<_RatingComboTab> createState() => _RatingComboTabState();
}

class _RatingComboTabState extends State<_RatingComboTab> {
  final solver = const RatingCombinationSolver();
  double target = 84;
  List<RatingCombination> combos = const [];

  @override
  void initState() {
    super.initState();
    _solve();
  }

  void _solve() {
    setState(() {
      combos = solver.solve(targetRating: target.round());
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text(
          'ترکیب ۱۱ نفره برای رسیدن به ریتینگ اسکادر هدف.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Text('هدف: ${target.round()} OVR'),
        Slider(
          value: target,
          min: 75,
          max: 90,
          divisions: 15,
          label: target.round().toString(),
          onChanged: (value) => setState(() => target = value),
          onChangeEnd: (_) => _solve(),
        ),
        const SizedBox(height: 8),
        for (final combo in combos)
          Card(
            child: ListTile(
              title: Text(combo.summary),
              subtitle: Text('میانگین ${combo.average.toStringAsFixed(2)}'),
            ),
          ),
        if (combos.isEmpty)
          const Card(
            child: ListTile(title: Text('ترکیبی پیدا نشد')),
          ),
      ],
    );
  }
}

class _SbcGuideTab extends StatelessWidget {
  const _SbcGuideTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _GuideTile(
          title: 'Best Value',
          body:
              'پاداش را با هزینه مقایسه کنید. Upgradeهای تکرارشونده معمولاً برای Fodder بهترند.',
        ),
        _GuideTile(
          title: 'Owned Players',
          body:
              'قبل از خرید، باشگاه من را چک کنید تا هزینه باقی‌مانده کمتر شود.',
        ),
        _GuideTile(
          title: 'Rating Combo',
          body:
              'برای Rated Squad از تب ترکیب ریتینگ استفاده کنید، بعد از بخش Fodder کارت بخرید.',
        ),
        _GuideTile(
          title: 'داده زنده',
          body:
              'لیست SBC فعال فقط با منبع واقعی پر می‌شود؛ داده ساختگی نمایش داده نمی‌شود.',
        ),
      ],
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(body),
        ),
      ),
    );
  }
}
