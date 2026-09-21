import 'package:flutter/material.dart';

import '../../players/data/player_repository.dart';
import '../../players/domain/player.dart';
import '../../players/presentation/player_portrait.dart';
import '../../settings/app_settings_repository.dart';
import '../../../core/market/tax_calculator.dart';

/// Manual pack value calculator (practical free alternative to camera Pack Scanner).
class PackValueScreen extends StatefulWidget {
  const PackValueScreen({super.key});

  @override
  State<PackValueScreen> createState() => _PackValueScreenState();
}

class _PackValueScreenState extends State<PackValueScreen> {
  final repository = PlayerRepository();
  final settingsRepository = AppSettingsRepository();
  final query = TextEditingController();

  String platform = 'console';
  bool searching = false;
  List<Player> results = const [];
  final List<Player> pack = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final settings = await settingsRepository.load();
    if (!mounted) return;
    setState(() => platform = settings.defaultPlatform);
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    final q = value.trim();
    if (q.length < 2) {
      setState(() => results = const []);
      return;
    }
    setState(() => searching = true);
    try {
      final found = await repository.search(q);
      if (!mounted) return;
      setState(() => results = found.take(20).toList());
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  int _price(Player p) => platform == 'pc' ? p.pricePc : p.pricePs;

  String _coins(int value) {
    if (value <= 0) return '—';
    if (value >= 1000000) {
      final n = value / 1000000;
      return n.toStringAsFixed(n >= 10 ? 0 : 1) + 'M';
    }
    if (value >= 1000) {
      final n = value / 1000;
      return n.toStringAsFixed(n >= 100 ? 0 : 1) + 'K';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final total = pack.fold<int>(0, (sum, p) => sum + _price(p));
    final afterTax = TaxCalculator.netAfterTax(total);

    return Scaffold(
      appBar: AppBar(title: const Text('ارزش پک')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'بازیکن‌های داخل پک را جستجو و اضافه کنید تا مجموع ارزش و دریافتی بعد از مالیات ۵٪ مشخص شود.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: query,
            decoration: const InputDecoration(
              labelText: 'جستجوی بازیکن پک',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _search,
          ),
          if (searching) const LinearProgressIndicator(minHeight: 2),
          for (final player in results)
            ListTile(
              leading: PlayerPortrait(
                player: player,
                width: 40,
                height: 40,
                borderRadius: 10,
              ),
              title: Text(player.name),
              subtitle: Text('${player.rating} • ${_coins(_price(player))}'),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => pack.add(player)),
              ),
            ),
          const Divider(),
          Text('پک فعلی', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (pack.isEmpty)
            const Card(
              child: ListTile(
                title: Text('هنوز کارتی اضافه نشده'),
              ),
            ),
          for (var i = 0; i < pack.length; i++)
            ListTile(
              leading: PlayerPortrait(
                player: pack[i],
                width: 40,
                height: 40,
                borderRadius: 10,
              ),
              title: Text(pack[i].name),
              subtitle: Text(_coins(_price(pack[i]))),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => setState(() => pack.removeAt(i)),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('مجموع ارزش'),
              trailing: Text(
                _coins(total),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('بعد از مالیات فروش'),
              trailing: Text(
                _coins(afterTax),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
