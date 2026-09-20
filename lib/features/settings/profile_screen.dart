import 'package:flutter/material.dart';

import '../club/data/my_club_repository.dart';
import '../market/data/watchlist_repository.dart';
import '../search/search_history_repository.dart';
import '../squad/data/squad_repository.dart';
import 'local_profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final profileRepository = LocalProfileRepository();
  final favoritesRepository = SearchHistoryRepository();
  final clubRepository = MyClubRepository();
  final squadRepository = SquadRepository();
  final watchlistRepository = WatchlistRepository();

  bool loading = true;
  String displayName = '';
  int favorites = 0;
  int clubPlayers = 0;
  int squads = 0;
  int watchlist = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      profileRepository.load(),
      favoritesRepository.favorites(),
      clubRepository.getAll(),
      squadRepository.getAll(),
      watchlistRepository.getAll(),
    ]);

    if (!mounted) return;

    setState(() {
      displayName = (results[0] as LocalProfile).displayName;
      favorites = (results[1] as List).length;
      clubPlayers = (results[2] as List).length;
      squads = (results[3] as List).length;
      watchlist = (results[4] as List).length;
      loading = false;
    });
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: displayName);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نام نمایشی'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 32,
          decoration: const InputDecoration(
            hintText: 'مثلاً Sahand',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim(),
            ),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (value == null) return;
    await profileRepository.saveName(value);
    if (!mounted) return;
    setState(() => displayName = value);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = displayName.isEmpty ? 'کاربر FCBaz' : displayName;

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      child: Text(
                        name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'پروفایل محلی • اطلاعات روی همین دستگاه',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _editName,
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                _ProfileMetric(
                  label: 'Favorites',
                  value: favorites,
                  icon: Icons.favorite_rounded,
                ),
                _ProfileMetric(
                  label: 'My Club',
                  value: clubPlayers,
                  icon: Icons.inventory_2_rounded,
                ),
                _ProfileMetric(
                  label: 'Squads',
                  value: squads,
                  icon: Icons.stadium_rounded,
                ),
                _ProfileMetric(
                  label: 'Watchlist',
                  value: watchlist,
                  icon: Icons.visibility_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.cloud_off_rounded),
                title: Text('اکانت آنلاین هنوز فعال نیست'),
                subtitle: Text(
                  'این صفحه عمداً پروفایل محلی است تا تا قبل از اضافه‌شدن Login/Backend حساب کاربری، اطلاعات جعلی نمایش داده نشود.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
