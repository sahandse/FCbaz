import 'package:flutter/material.dart';

import '../data/player_repository.dart';

class AdvancedPlayerFilterSheet extends StatefulWidget {
  const AdvancedPlayerFilterSheet({
    required this.current,
    required this.facets,
    super.key,
  });

  final PlayerFilter current;
  final PlayerFacets facets;

  @override
  State<AdvancedPlayerFilterSheet> createState() =>
      _AdvancedPlayerFilterSheetState();
}

class _AdvancedPlayerFilterSheetState
    extends State<AdvancedPlayerFilterSheet> {
  late RangeValues rating = RangeValues(
    widget.current.minRating.toDouble(),
    widget.current.maxRating.toDouble(),
  );

  late final TextEditingController minPriceController =
      TextEditingController(text: widget.current.minPrice?.toString() ?? '');
  late final TextEditingController maxPriceController =
      TextEditingController(text: widget.current.maxPrice?.toString() ?? '');

  late String? position = widget.current.position;
  late String? version = widget.current.version;
  late String? rarity = widget.current.rarity;
  late String? cardType = widget.current.cardType;
  late String? league = widget.current.league;
  late String? club = widget.current.club;
  late String? nation = widget.current.nation;
  late String? playStyle = widget.current.playStyle;
  late String? playStylePlus = widget.current.playStylePlus;
  late String? role = widget.current.role;
  late int? minSkillMoves = widget.current.minSkillMoves;
  late int? minWeakFoot = widget.current.minWeakFoot;
  late String platform = widget.current.platform;
  late PlayerSort sort = widget.current.sort;

  late final Map<String, TextEditingController> statControllers = {
    'minPace': TextEditingController(text: widget.current.minPace?.toString() ?? ''),
    'maxPace': TextEditingController(text: widget.current.maxPace?.toString() ?? ''),
    'minShooting': TextEditingController(text: widget.current.minShooting?.toString() ?? ''),
    'maxShooting': TextEditingController(text: widget.current.maxShooting?.toString() ?? ''),
    'minPassing': TextEditingController(text: widget.current.minPassing?.toString() ?? ''),
    'maxPassing': TextEditingController(text: widget.current.maxPassing?.toString() ?? ''),
    'minDribbling': TextEditingController(text: widget.current.minDribbling?.toString() ?? ''),
    'maxDribbling': TextEditingController(text: widget.current.maxDribbling?.toString() ?? ''),
    'minDefending': TextEditingController(text: widget.current.minDefending?.toString() ?? ''),
    'maxDefending': TextEditingController(text: widget.current.maxDefending?.toString() ?? ''),
    'minPhysical': TextEditingController(text: widget.current.minPhysical?.toString() ?? ''),
    'maxPhysical': TextEditingController(text: widget.current.maxPhysical?.toString() ?? ''),
  };

  static const positions = [
    'GK',
    'CB',
    'LB',
    'RB',
    'CDM',
    'CM',
    'CAM',
    'LM',
    'RM',
    'LW',
    'RW',
    'CF',
    'ST',
  ];

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    for (final controller in statControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _sortTitle(PlayerSort value) {
    switch (value) {
      case PlayerSort.ratingDesc:
        return 'بیشترین ریتینگ';
      case PlayerSort.ratingAsc:
        return 'کمترین ریتینگ';
      case PlayerSort.priceAsc:
        return 'ارزان‌ترین';
      case PlayerSort.priceDesc:
        return 'گران‌ترین';
      case PlayerSort.pace:
        return 'بیشترین سرعت';
      case PlayerSort.shooting:
        return 'بهترین شوت';
      case PlayerSort.passing:
        return 'بهترین پاس';
      case PlayerSort.dribbling:
        return 'بهترین دریبل';
      case PlayerSort.defending:
        return 'بهترین دفاع';
      case PlayerSort.physical:
        return 'بهترین فیزیک';
    }
  }

  int? _int(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : int.tryParse(text);
  }

  PlayerFilter _result() {
    return PlayerFilter(
      query: widget.current.query,
      position: position,
      version: _clean(version),
      rarity: _clean(rarity),
      cardType: _clean(cardType),
      league: _clean(league),
      club: _clean(club),
      nation: _clean(nation),
      minRating: rating.start.round(),
      maxRating: rating.end.round(),
      minPrice: _int(minPriceController),
      maxPrice: _int(maxPriceController),
      platform: platform,
      playStyle: _clean(playStyle),
      playStylePlus: _clean(playStylePlus),
      role: _clean(role),
      minSkillMoves: minSkillMoves,
      minWeakFoot: minWeakFoot,
      minPace: _int(statControllers['minPace']!),
      maxPace: _int(statControllers['maxPace']!),
      minShooting: _int(statControllers['minShooting']!),
      maxShooting: _int(statControllers['maxShooting']!),
      minPassing: _int(statControllers['minPassing']!),
      maxPassing: _int(statControllers['maxPassing']!),
      minDribbling: _int(statControllers['minDribbling']!),
      maxDribbling: _int(statControllers['maxDribbling']!),
      minDefending: _int(statControllers['minDefending']!),
      maxDefending: _int(statControllers['maxDefending']!),
      minPhysical: _int(statControllers['minPhysical']!),
      maxPhysical: _int(statControllers['maxPhysical']!),
      sort: sort,
    );
  }

  String? _clean(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottom),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'فیلتر پیشرفته',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    PlayerFilter(query: widget.current.query),
                  ),
                  child: const Text('پاک کردن همه'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionTitle('پلتفرم و قیمت'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'console',
                  label: Text('Console'),
                  icon: Icon(Icons.sports_esports_rounded),
                ),
                ButtonSegment(
                  value: 'pc',
                  label: Text('PC'),
                  icon: Icon(Icons.computer_rounded),
                ),
              ],
              selected: {platform},
              onSelectionChanged: (values) {
                if (values.isNotEmpty) setState(() => platform = values.first);
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'حداقل قیمت',
                      suffixText: 'Coins',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'حداکثر قیمت',
                      suffixText: 'Coins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _SectionTitle('پست و ریتینگ'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                ChoiceChip(
                  label: const Text('همه'),
                  selected: position == null,
                  onSelected: (_) => setState(() => position = null),
                ),
                for (final item in positions)
                  ChoiceChip(
                    label: Text(item),
                    selected: position == item,
                    onSelected: (_) => setState(() => position = item),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'ریتینگ ' +
                  rating.start.round().toString() +
                  ' تا ' +
                  rating.end.round().toString(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            RangeSlider(
              min: 40,
              max: 99,
              divisions: 59,
              values: rating,
              labels: RangeLabels(
                rating.start.round().toString(),
                rating.end.round().toString(),
              ),
              onChanged: (value) => setState(() => rating = value),
            ),
            const SizedBox(height: 18),
            const _SectionTitle('کارت و لیگ'),
            const SizedBox(height: 8),
            _SuggestField(
              label: 'Version',
              initialValue: version,
              options: widget.facets.versions,
              onChanged: (value) => version = value,
            ),
            const SizedBox(height: 10),
            _SuggestField(
              label: 'Rarity',
              initialValue: rarity,
              options: widget.facets.rarities,
              onChanged: (value) => rarity = value,
            ),
            const SizedBox(height: 10),
            _SuggestField(
              label: 'Card Type',
              initialValue: cardType,
              options: widget.facets.cardTypes,
              onChanged: (value) => cardType = value,
            ),
            const SizedBox(height: 10),
            _SuggestField(
              label: 'League',
              initialValue: league,
              options: widget.facets.leagues,
              onChanged: (value) => league = value,
            ),
            const SizedBox(height: 10),
            _SuggestField(
              label: 'Club',
              initialValue: club,
              options: widget.facets.clubs,
              onChanged: (value) => club = value,
            ),
            const SizedBox(height: 10),
            _SuggestField(
              label: 'Nation',
              initialValue: nation,
              options: widget.facets.nations,
              onChanged: (value) => nation = value,
            ),
            const SizedBox(height: 18),
            const _SectionTitle('PlayStyles و Roles'),
            const SizedBox(height: 8),
            _SuggestField(
              label: 'PlayStyle',
              initialValue: playStyle,
              options: widget.facets.playStyles,
              onChanged: (value) => playStyle = value,
            ),
            const SizedBox(height: 10),
            _SuggestField(
              label: 'PlayStyle+',
              initialValue: playStylePlus,
              options: widget.facets.playStylesPlus,
              onChanged: (value) => playStylePlus = value,
            ),
            const SizedBox(height: 10),
            _SuggestField(
              label: 'Role',
              initialValue: role,
              options: widget.facets.roles,
              onChanged: (value) => role = value,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: minSkillMoves,
                    decoration: const InputDecoration(labelText: 'حداقل SM'),
                    items: const [
                      DropdownMenuItem<int?>(value: null, child: Text('همه')),
                      DropdownMenuItem<int?>(value: 3, child: Text('3★+')),
                      DropdownMenuItem<int?>(value: 4, child: Text('4★+')),
                      DropdownMenuItem<int?>(value: 5, child: Text('5★')),
                    ],
                    onChanged: (value) => setState(() => minSkillMoves = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: minWeakFoot,
                    decoration: const InputDecoration(labelText: 'حداقل WF'),
                    items: const [
                      DropdownMenuItem<int?>(value: null, child: Text('همه')),
                      DropdownMenuItem<int?>(value: 3, child: Text('3★+')),
                      DropdownMenuItem<int?>(value: 4, child: Text('4★+')),
                      DropdownMenuItem<int?>(value: 5, child: Text('5★')),
                    ],
                    onChanged: (value) => setState(() => minWeakFoot = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Advanced Stat Range'),
            const SizedBox(height: 8),
            _StatRangeRow(
              label: 'PAC',
              minController: statControllers['minPace']!,
              maxController: statControllers['maxPace']!,
            ),
            const SizedBox(height: 8),
            _StatRangeRow(
              label: 'SHO',
              minController: statControllers['minShooting']!,
              maxController: statControllers['maxShooting']!,
            ),
            const SizedBox(height: 8),
            _StatRangeRow(
              label: 'PAS',
              minController: statControllers['minPassing']!,
              maxController: statControllers['maxPassing']!,
            ),
            const SizedBox(height: 8),
            _StatRangeRow(
              label: 'DRI',
              minController: statControllers['minDribbling']!,
              maxController: statControllers['maxDribbling']!,
            ),
            const SizedBox(height: 8),
            _StatRangeRow(
              label: 'DEF',
              minController: statControllers['minDefending']!,
              maxController: statControllers['maxDefending']!,
            ),
            const SizedBox(height: 8),
            _StatRangeRow(
              label: 'PHY',
              minController: statControllers['minPhysical']!,
              maxController: statControllers['maxPhysical']!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PlayerSort>(
              initialValue: sort,
              decoration: const InputDecoration(labelText: 'مرتب‌سازی'),
              items: [
                for (final value in PlayerSort.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(_sortTitle(value)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => sort = value);
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, _result()),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('اعمال فیلترها'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w900),
    );
  }
}

class _StatRangeRow extends StatelessWidget {
  const _StatRangeRow({
    required this.label,
    required this.minController,
    required this.maxController,
  });

  final String label;
  final TextEditingController minController;
  final TextEditingController maxController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Expanded(
          child: TextField(
            controller: minController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Min'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: maxController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Max'),
          ),
        ),
      ],
    );
  }
}

class _SuggestField extends StatelessWidget {
  const _SuggestField({
    required this.label,
    required this.initialValue,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? initialValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue ?? ''),
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return options.take(12);
        return options
            .where((item) => item.toLowerCase().contains(q))
            .take(12);
      },
      onSelected: onChanged,
      fieldViewBuilder: (
        context,
        controller,
        focusNode,
        onSubmitted,
      ) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      controller.clear();
                      onChanged(null);
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        );
      },
    );
  }
}
