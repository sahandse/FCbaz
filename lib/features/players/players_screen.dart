import 'package:flutter/material.dart';

import '../settings/app_settings_repository.dart';
import 'data/player_repository.dart';
import 'domain/player.dart';
import 'presentation/advanced_player_filter_sheet.dart';
import 'presentation/player_card.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final repository = PlayerRepository();
  final settingsRepository = AppSettingsRepository();

  List<Player> players = const [];
  PlayerFilter filter = const PlayerFilter();
  PlayerFacets facets = const PlayerFacets();
  bool loading = true;
  String? error;
  String quickRarity = 'همه';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final settings = await settingsRepository.load();
    if (!mounted) return;
    setState(() => filter = filter.copyWith(platform: settings.defaultPlatform));
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await repository.advanced(filter);
      if (!mounted) return;
      setState(() {
        players = result.players;
        facets = result.facets;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<PlayerFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AdvancedPlayerFilterSheet(current: filter, facets: facets),
    );
    if (result == null) return;
    setState(() {
      filter = result;
      quickRarity = 'همه';
    });
    await _load();
  }

  Future<void> _applyQuickRarity(String label, String? rarity) async {
    setState(() {
      quickRarity = label;
      filter = filter.copyWith(
        version: rarity,
        clearVersion: rarity == null,
        rarity: rarity,
        clearRarity: rarity == null,
        cardType: rarity,
        clearCardType: rarity == null,
      );
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090E0A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: scheme.primary.withValues(alpha: .28)),
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          scheme.primary.withValues(alpha: .12),
                          const Color(0xFF090E0A),
                          scheme.secondary.withValues(alpha: .05),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FUT COLLECTION',
                                textDirection: TextDirection.ltr,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.2,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'کارت‌های FC27 • Gold • ICON • Hero • Promo',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Badge(
                          isLabelVisible: filter.activeCount > 0,
                          label: Text(filter.activeCount.toString()),
                          child: IconButton.filled(
                            onPressed: _openFilters,
                            icon: const Icon(Icons.tune_rounded),
                            tooltip: 'فیلتر پیشرفته',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _RarityChip(label: 'همه', active: quickRarity == 'همه', onTap: () => _applyQuickRarity('همه', null)),
                        _RarityChip(label: 'Gold', active: quickRarity == 'Gold', onTap: () => _applyQuickRarity('Gold', 'Gold')),
                        _RarityChip(label: 'ICON', active: quickRarity == 'ICON', onTap: () => _applyQuickRarity('ICON', 'Base Icon')),
                        _RarityChip(label: 'Hero', active: quickRarity == 'Hero', onTap: () => _applyQuickRarity('Hero', 'Base Hero')),
                        _RarityChip(label: 'TOTW', active: quickRarity == 'TOTW', onTap: () => _applyQuickRarity('TOTW', 'Team of the week')),
                        _RarityChip(label: 'Hall', active: quickRarity == 'Hall', onTap: () => _applyQuickRarity('Hall', 'Hall of FUT')),
                        _RarityChip(label: 'Holo', active: quickRarity == 'Holo', onTap: () => _applyQuickRarity('Holo', 'Holographic')),
                        _RarityChip(label: 'Silver', active: quickRarity == 'Silver', onTap: () => _applyQuickRarity('Silver', 'Silver')),
                        _RarityChip(label: 'Bronze', active: quickRarity == 'Bronze', onTap: () => _applyQuickRarity('Bronze', 'Bronze')),
                      ],
                    ),
                  ),
                  if (filter.activeCount > 0) ...[
                    const SizedBox(height: 8),
                    _ActiveFilters(
                      filter: filter,
                      onClear: () {
                        setState(() {
                          filter = const PlayerFilter();
                          quickRarity = 'همه';
                        });
                        _load();
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (!loading && error == null && players.isNotEmpty)
                    Row(
                      children: [
                        Text(
                          '${players.length} ITEM',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.verified_rounded, size: 15, color: scheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'FC27 verified catalog',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverToBoxAdapter(
                child: _StateCard(
                  icon: Icons.cloud_off_rounded,
                  title: 'دیتای بازیکنان در دسترس نیست',
                  subtitle: error!,
                  actionLabel: 'تلاش دوباره',
                  onAction: _load,
                ),
              ),
            )
          else if (players.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(14),
              sliver: SliverToBoxAdapter(
                child: _StateCard(
                  icon: Icons.style_rounded,
                  title: 'کارتی پیدا نشد',
                  subtitle: filter.activeCount > 0
                      ? 'فیلتر دیگری را امتحان کن.'
                      : 'Catalog معتبر فعلاً آیتمی برنگرداند.',
                  actionLabel: filter.activeCount > 0 ? 'نمایش همه' : null,
                  onAction: filter.activeCount > 0
                      ? () {
                          setState(() {
                            filter = const PlayerFilter();
                            quickRarity = 'همه';
                          });
                          _load();
                        }
                      : null,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(11, 0, 11, 30),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 7,
                  childAspectRatio: .69,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PlayerCard(
                    player: players[index],
                    pricePlatform: filter.platform,
                  ),
                  childCount: players.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RarityChip extends StatelessWidget {
  const _RarityChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label, textDirection: TextDirection.ltr),
        selected: active,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: scheme.primary,
        labelStyle: TextStyle(
          color: active ? const Color(0xFF11150D) : scheme.onSurface,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.filter, required this.onClear});
  final PlayerFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (filter.position != null) filter.position!,
      if (filter.version != null) filter.version!,
      if (filter.league != null) filter.league!,
      if (filter.club != null) filter.club!,
      if (filter.nation != null) filter.nation!,
      if (filter.minRating != 40 || filter.maxRating != 99) 'OVR ${filter.minRating}–${filter.maxRating}',
      if (filter.platform == 'pc') 'PC',
      if (filter.role != null) 'Role ${filter.role!}',
    ];

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final label in labels) ...[
            Chip(label: Text(label)),
            const SizedBox(width: 5),
          ],
          ActionChip(
            avatar: const Icon(Icons.close_rounded, size: 15),
            label: const Text('پاک کردن'),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 11),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text(subtitle, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 13),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
