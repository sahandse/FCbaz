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
            hintText: 'مثلاً سهند',
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل محلی')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    scheme.primary.withValues(alpha: .16),
                    scheme.secondary.withValues(alpha: .07),
                    scheme.surface,
                  ],
                ),
                border: Border.all(color: scheme.outline),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'اطلاعات شخصی فقط روی همین دستگاه ذخیره می‌شود',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _editName,
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'ویرایش نام',
                  ),
                ],
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
                  label: 'علاقه‌مندی‌ها',
                  value: favorites,
                  icon: Icons.favorite_rounded,
                ),
                _ProfileMetric(
                  label: 'باشگاه من',
                  value: clubPlayers,
                  icon: Icons.inventory_2_rounded,
                ),
                _ProfileMetric(
                  label: 'ترکیب‌ها',
                  value: squads,
                  icon: Icons.stadium_rounded,
                ),
                _ProfileMetric(
                  label: 'واچ‌لیست',
                  value: watchlist,
                  icon: Icons.visibility_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_person_rounded, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'بدون ثبت‌نام و ورود',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'FCBaz حساب کاربری ندارد. باشگاه، ترکیب‌ها، واچ‌لیست، علاقه‌مندی‌ها و پیشرفت‌های شخصی روی خود دستگاه نگهداری می‌شوند.',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
            Expanded(
              child: Column(
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
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
