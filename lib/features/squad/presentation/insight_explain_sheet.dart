import 'package:flutter/material.dart';

import '../../players/domain/player.dart';
import '../domain/chemistry_engine.dart';
import '../domain/squad_insights_service.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';

class ExplainRow {
  const ExplainRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;
}

class ExplainSection {
  const ExplainSection({required this.title, required this.rows});

  final String title;
  final List<ExplainRow> rows;
}

class InsightExplainSheet extends StatelessWidget {
  const InsightExplainSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeColor,
    this.chips = const [],
    this.sections = const [],
    this.notes = const [],
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final Color badgeColor;
  final List<String> chips;
  final List<ExplainSection> sections;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: .14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: badgeColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(label: badgeLabel, color: badgeColor, emphasized: true),
            for (final chip in chips)
              _Pill(label: chip, color: palette.textMuted),
          ],
        ),
        for (final section in sections) ...[
          const SizedBox(height: 16),
          Text(
            section.title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: palette.surfaceRaised,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < section.rows.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: .8,
                      color: palette.line.withValues(alpha: .7),
                    ),
                  _ExplainRowTile(row: section.rows[i]),
                ],
              ],
            ),
          ),
        ],
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: palette.textMuted,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 11.5,
                        height: 1.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

Future<void> showReplacementExplanation(
  BuildContext context, {
  required SquadReplacementSuggestion suggestion,
  required String slotPosition,
  required String platform,
  required ChemistrySlotDetail? currentSlotChemistry,
  required String currentRole,
}) {
  final service = SquadInsightsService();
  final current = service.explainMetaScore(
    suggestion.currentPlayer,
    slotPosition,
    chemistry: currentSlotChemistry?.chemistry ?? 0,
    selectedRole: currentRole,
  );
  final candidate = service.explainMetaScore(
    suggestion.replacement,
    slotPosition,
    chemistry: 0,
    selectedRole: '',
  );
  final gain = candidate.total - current.total;
  final gainPrefix = gain >= 0 ? '+' : '';
  final per100k = suggestion.price > 0
      ? gain / (suggestion.price / 100000)
      : 0.0;
  final platformLabel = platform.toLowerCase() == 'pc' ? 'PC' : 'کنسول';
  final palette = context.palette;

  return _present(
    context,
    InsightExplainSheet(
      icon: Icons.swap_horiz_rounded,
      title: 'چرا این پیشنهاد؟',
      subtitle:
          '${suggestion.replacement.name} برای پست $slotPosition '
          'به‌جای ${suggestion.currentPlayer.name}',
      badgeLabel: 'Meta $gainPrefix${_one(gain)}',
      badgeColor: palette.success,
      chips: [
        'قیمت ${formatCoinsFa(suggestion.price)} سکه',
        'بازار $platformLabel',
      ],
      sections: [
        ExplainSection(
          title: 'مقایسه امتیاز متا',
          rows: [
            ExplainRow(
              label: 'بازیکن فعلی',
              value:
                  '${suggestion.currentPlayer.name} '
                  '(${faDigits(suggestion.currentPlayer.rating)})',
            ),
            ExplainRow(label: 'امتیاز فعلی', value: _one(current.total)),
            ExplainRow(
              label: 'امتیاز جایگزین',
              value: _one(candidate.total),
              highlight: true,
            ),
            ExplainRow(
              label: 'افزایش متا',
              value: '$gainPrefix${_one(gain)}',
              highlight: true,
            ),
            if (per100k > 0)
              ExplainRow(
                label: 'افزایش به ازای هر ۱۰۰ هزار سکه',
                value: _one(per100k),
              ),
          ],
        ),
        ExplainSection(
          title: 'اجزای امتیاز بازیکن فعلی',
          rows: [
            ExplainRow(label: 'آمار پایه پست', value: _one(current.base)),
            ExplainRow(
              label: 'PlayStyles+ (${faDigits(current.playStylesPlusCount)})',
              value: '+${_one(current.playStylesPlusBonus)}',
            ),
            ExplainRow(
              label: 'PlayStyles (${faDigits(current.playStylesCount)})',
              value: '+${_one(current.playStylesBonus)}',
            ),
            ExplainRow(
              label: 'شیمی (${faDigits(current.chemistry)}/3)',
              value: '+${_one(current.chemistryBonus)}',
            ),
            ExplainRow(
              label: 'Role',
              value: current.roleFit
                  ? '+${_one(current.roleBonus)}'
                  : currentRole.isEmpty
                  ? 'تنظیم نشده'
                  : 'ناسازگار با کارت',
            ),
          ],
        ),
        ExplainSection(
          title: 'اجزای امتیاز بازیکن جایگزین',
          rows: [
            ExplainRow(label: 'آمار پایه پست', value: _one(candidate.base)),
            ExplainRow(
              label: 'PlayStyles+ (${faDigits(candidate.playStylesPlusCount)})',
              value: '+${_one(candidate.playStylesPlusBonus)}',
            ),
            ExplainRow(
              label: 'PlayStyles (${faDigits(candidate.playStylesCount)})',
              value: '+${_one(candidate.playStylesBonus)}',
            ),
            const ExplainRow(
              label: 'شیمی',
              value: '۰ — در این محاسبه لحاظ نشده',
            ),
            const ExplainRow(label: 'Role', value: 'در این محاسبه لحاظ نشده'),
          ],
        ),
      ],
      notes: const [
        'فقط بازیکنانی پیشنهاد می‌شوند که قیمت واقعی ثبت‌شده دارند، از بودجه انتخابی بیشتر نیستند و همین حالا در ترکیب حضور ندارند.',
        'امتیاز بازیکن جایگزین با شیمی صفر و بدون Role محاسبه شده است؛ افزایش واقعی بعد از جایگزینی می‌تواند بیشتر یا کمتر باشد. شیمی ترکیب را بعد از اعمال دوباره بررسی کن.',
        'امتیاز متا یک شاخص ترکیبی محلی از آمار کلیدی پست، PlayStyles و شیمی است و رتبه رسمی EA نیست.',
      ],
    ),
  );
}

Future<void> showWeaknessExplanation(
  BuildContext context, {
  required SquadWeakness issue,
  required Player? player,
  required String? slotPosition,
  required ChemistrySlotDetail? slotDetail,
  required String role,
  required String focus,
}) {
  final palette = context.palette;
  final severity = issue.severity;
  final badgeLabel = severity >= 4
      ? 'بحرانی'
      : severity == 3
      ? 'هشدار'
      : 'بهبود';
  final badgeColor = severity >= 4
      ? palette.danger
      : severity == 3
      ? palette.warning
      : palette.secondary;

  final playerRows = <ExplainRow>[
    if (player != null)
      ExplainRow(
        label: 'بازیکن',
        value: '${player.name} (${faDigits(player.rating)})',
      ),
    if (slotPosition != null) ExplainRow(label: 'پست', value: slotPosition),
    if (slotDetail != null) ...[
      ExplainRow(
        label: 'شیمی این بازیکن',
        value: faDigits('${slotDetail.chemistry}/3'),
        highlight: true,
      ),
      ExplainRow(
        label: 'در پست معتبر',
        value: slotDetail.inPosition ? 'بله' : 'خیر',
      ),
      ExplainRow(
        label: 'باشگاه هم‌نام در ترکیب',
        value: faDigits(slotDetail.clubCount),
      ),
      ExplainRow(
        label: 'لیگ هم‌نام در ترکیب',
        value: faDigits(slotDetail.leagueCount),
      ),
      ExplainRow(
        label: 'کشور هم‌نام در ترکیب',
        value: faDigits(slotDetail.nationCount),
      ),
      ExplainRow(
        label: 'تطابق سرمربی',
        value: slotDetail.managerMatch ? 'بله (+۱)' : 'خیر',
      ),
      if (slotDetail.specialCard)
        const ExplainRow(
          label: 'کارت ویژه',
          value: 'Icon / Hero / Hall of FUT — شیمی ۳',
        ),
    ],
    if (role.isNotEmpty) ExplainRow(label: 'Role انتخابی', value: role),
    if (focus.isNotEmpty) ExplainRow(label: 'Focus انتخابی', value: focus),
  ];

  return _present(
    context,
    InsightExplainSheet(
      icon: Icons.lightbulb_outline_rounded,
      title: 'چرا این نکته؟',
      subtitle: issue.detail,
      badgeLabel: badgeLabel,
      badgeColor: badgeColor,
      chips: const ['تحلیل محلی از داده کارت‌ها'],
      sections: [
        if (playerRows.isNotEmpty)
          ExplainSection(title: 'وضعیت بازیکن', rows: playerRows),
        const ExplainSection(
          title: 'قانون شیمی FC 27',
          rows: [
            ExplainRow(
              label: 'باشگاه',
              value: '۲ / ۴ / ۷ بازیکن هم‌نام ← ۱ / ۲ / ۳ امتیاز',
            ),
            ExplainRow(
              label: 'لیگ',
              value: '۳ / ۵ / ۸ بازیکن هم‌نام ← ۱ / ۲ / ۳ امتیاز',
            ),
            ExplainRow(
              label: 'کشور',
              value: '۲ / ۵ / ۸ بازیکن هم‌نام ← ۱ / ۲ / ۳ امتیاز',
            ),
            ExplainRow(label: 'سرمربی', value: 'تطابق لیگ یا کشور ← +۱ امتیاز'),
          ],
        ),
      ],
      notes: const [
        'فقط بازیکنان در پست معتبر در شمارش شیمی سهیم‌اند؛ بازیکن خارج از پست شیمی ۰ می‌گیرد.',
        'سقف شیمی هر بازیکن ۳ است؛ کارت‌های Icon، Hero و Hall of FUT همیشه ۳ شیمی می‌گیرند.',
      ],
    ),
  );
}

Future<void> _present(BuildContext context, Widget sheet) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: sheet,
        ),
      ),
    ),
  );
}

String _one(double value) => faDigits(value.toStringAsFixed(1));

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    this.emphasized = false,
  });

  final String label;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized
            ? color.withValues(alpha: .16)
            : context.palette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? color.withValues(alpha: .45)
              : context.palette.line,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: emphasized ? color : context.palette.textMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExplainRowTile extends StatelessWidget {
  const _ExplainRowTile({required this.row});

  final ExplainRow row;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.label,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 4,
            child: Text(
              row.value,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: row.highlight ? palette.primary : palette.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                height: 1.4,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
