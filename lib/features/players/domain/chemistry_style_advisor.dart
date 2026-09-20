import 'player.dart';

class ChemistryStyleSuggestion {
  const ChemistryStyleSuggestion({
    required this.name,
    required this.reason,
    required this.focus,
  });

  final String name;
  final String reason;
  final List<String> focus;
}

class ChemistryStyleAdvisor {
  const ChemistryStyleAdvisor();

  List<ChemistryStyleSuggestion> suggest(Player player) {
    final position = player.position.toUpperCase();
    final defensive = {'CB', 'LB', 'RB', 'LWB', 'RWB', 'CDM'};
    final midfield = {'CM', 'CAM', 'LM', 'RM'};
    final wide = {'LW', 'RW', 'LM', 'RM'};
    final forward = {'ST', 'CF', 'LW', 'RW'};

    if (position == 'GK') {
      return const [
        ChemistryStyleSuggestion(
          name: 'Glove',
          reason: 'برای تمرکز روی مهارت‌های اصلی دروازه‌بانی.',
          focus: ['Handling', 'Diving', 'Positioning'],
        ),
        ChemistryStyleSuggestion(
          name: 'Cat',
          reason: 'برای کارت‌هایی که به واکنش و چابکی بیشتر نیاز دارند.',
          focus: ['Reflexes', 'Speed', 'Positioning'],
        ),
      ];
    }

    final out = <ChemistryStyleSuggestion>[];

    if (defensive.contains(position)) {
      if (player.pace < 82) {
        out.add(const ChemistryStyleSuggestion(
          name: 'Shadow',
          reason: 'سرعت و دفاع را هم‌زمان تقویت می‌کند.',
          focus: ['PAC', 'DEF'],
        ));
      }
      if (player.physical < 84) {
        out.add(const ChemistryStyleSuggestion(
          name: 'Anchor',
          reason: 'برای مدافعانی که به فیزیک و سرعت بیشتری نیاز دارند.',
          focus: ['PAC', 'DEF', 'PHY'],
        ));
      }
      out.add(const ChemistryStyleSuggestion(
        name: 'Sentinel',
        reason: 'وقتی سرعت کافی است و تمرکز روی دفاع و فیزیک باشد.',
        focus: ['DEF', 'PHY'],
      ));
    }

    if (midfield.contains(position)) {
      if (player.passing < 88 || player.dribbling < 88) {
        out.add(const ChemistryStyleSuggestion(
          name: 'Engine',
          reason: 'برای بازی‌سازی، کنترل توپ و تحرک بیشتر.',
          focus: ['PAC', 'PAS', 'DRI'],
        ));
      }
      if (player.defending >= 70) {
        out.add(const ChemistryStyleSuggestion(
          name: 'Powerhouse',
          reason: 'برای هافبک‌های مرکزی و دفاعی با تمرکز روی پاس و دفاع.',
          focus: ['PAS', 'DEF'],
        ));
      } else {
        out.add(const ChemistryStyleSuggestion(
          name: 'Maestro',
          reason: 'برای هافبک‌های هجومی و سازنده.',
          focus: ['SHO', 'PAS', 'DRI'],
        ));
      }
    }

    if (forward.contains(position)) {
      if (player.pace < 90 && player.shooting < 90) {
        out.add(const ChemistryStyleSuggestion(
          name: 'Hunter',
          reason: 'برای مهاجمی که هم سرعت و هم تمام‌کنندگی بیشتری می‌خواهد.',
          focus: ['PAC', 'SHO'],
        ));
      }
      if (player.pace >= 88 && player.shooting < 91) {
        out.add(const ChemistryStyleSuggestion(
          name: 'Finisher',
          reason: 'وقتی سرعت کافی است و شوت و دریبل مهم‌ترند.',
          focus: ['SHO', 'DRI'],
        ));
      }
      if (player.physical < 82) {
        out.add(const ChemistryStyleSuggestion(
          name: 'Hawk',
          reason: 'برای ترکیب سرعت، شوت و فیزیک.',
          focus: ['PAC', 'SHO', 'PHY'],
        ));
      }
      if (wide.contains(position) && player.passing < 88) {
        out.add(const ChemistryStyleSuggestion(
          name: 'Catalyst',
          reason: 'برای وینگرهایی که پاس و سرعت بیشتری می‌خواهند.',
          focus: ['PAC', 'PAS'],
        ));
      }
    }

    if (out.isEmpty) {
      out.add(const ChemistryStyleSuggestion(
        name: 'Basic',
        reason: 'کارت متعادل است؛ Basic می‌تواند انتخاب خنثی‌تری باشد.',
        focus: ['Balanced'],
      ));
    }

    final unique = <String, ChemistryStyleSuggestion>{};
    for (final item in out) {
      unique[item.name] = item;
    }
    return unique.values.take(3).toList();
  }
}
