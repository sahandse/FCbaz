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
  late String platform = widget.current.platform;
  late PlayerSort sort = widget.current.sort;

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

  PlayerFilter _result() {
    int? price(TextEditingController controller) {
      final text = controller.text.trim();
      return text.isEmpty ? null : int.tryParse(text);
    }

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
      minPrice: price(minPriceController),
      maxPrice: price(maxPriceController),
      platform: platform,
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
            const Text(
              'پلتفرم قیمت',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
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
                if (values.isNotEmpty) {
                  setState(() => platform = values.first);
                }
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'پست',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
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
            const SizedBox(height: 18),
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 12),
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

class _SuggestField extends StatefulWidget {
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
  State<_SuggestField> createState() => _SuggestFieldState();
}

class _SuggestFieldState extends State<_SuggestField> {
  late final TextEditingController controller =
      TextEditingController(text: widget.initialValue ?? '');

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.initialValue ?? ''),
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return widget.options.take(12);
        return widget.options
            .where((item) => item.toLowerCase().contains(q))
            .take(12);
      },
      onSelected: (value) {
        controller.text = value;
        widget.onChanged(value);
      },
      fieldViewBuilder: (
        context,
        textController,
        focusNode,
        onSubmitted,
      ) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          onChanged: (value) => widget.onChanged(value),
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: textController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      textController.clear();
                      widget.onChanged(null);
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        );
      },
    );
  }
}
