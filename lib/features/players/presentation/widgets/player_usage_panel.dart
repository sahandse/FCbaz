import 'package:flutter/material.dart';

import '../../../club/data/my_club_repository.dart';
import '../../../evolutions/domain/evolution.dart';
import '../../../evolutions/domain/evolution_eligibility_engine.dart';
import '../../../evolutions/domain/evolution_projection.dart';
import '../../../sbc/domain/sbc.dart';
import '../../domain/player.dart';
import '../../domain/player_usage_service.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/ui/deadline_chip.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';

class PlayerUsagePanel extends StatelessWidget {
  const PlayerUsagePanel({
    required this.player,
    required this.loading,
    required this.evolutions,
    required this.sbcChallenges,
    required this.evolutionsError,
    required this.sbcError,
    required this.onRetry,
    super.key,
  });

  final Player player;
  final bool loading;
  final List<Evolution> evolutions;
  final List<SbcChallenge> sbcChallenges;
  final String? evolutionsError;
  final String? sbcError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const service = PlayerUsageService();
    final palette = context.palette;
    final clubItem = MyClubItem.fromPlayer(player, acquisitionPrice: 0);

    final evoMatches = [
      for (final evolution in evolutions)
        service.evaluateEvolution(player, evolution),
    ]..sort((a, b) => _evoRank(a.status).compareTo(_evoRank(b.status)));

    final sbcMatches = [
      for (final challenge in sbcChallenges)
        service.evaluateSbc(player, challenge),
    ]..sort((a, b) => _sbcRank(a.fit).compareTo(_sbcRank(b.fit)));

    final eligibleEvo = evoMatches
        .where((m) => m.status == EvoEligibilityStatus.eligible)
        .length;
    final reviewEvo = evoMatches
        .where((m) => m.status == EvoEligibilityStatus.needsReview)
        .length;
    final ineligibleEvo = evoMatches.length - eligibleEvo - reviewEvo;

    final passingSbc = sbcMatches
        .where((m) => m.fit == PlayerSbcFit.cardRulesPassed)
        .length;
    final reviewSbc = sbcMatches
        .where((m) => m.fit == PlayerSbcFit.needsReview)
        .length;
    final blockedSbc = sbcMatches.length - passingSbc - reviewSbc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UsageCard(
          icon: Icons.auto_awesome_rounded,
          title: 'Evolutionها',
          loading: loading,
          error: evolutionsError,
          errorTitle: 'دریافت فهرست Evolution ممکن نشد',
          onRetry: onRetry,
          emptyText: 'Evolution فعالی از منبع دریافت نشد.',
          summary:
              '${faDigits(eligibleEvo)} قابل استفاده • '
              '${faDigits(reviewEvo)} نیازمند بررسی • '
              '${faDigits(ineligibleEvo)} نامناسب',
          rows: [
            for (final match in evoMatches)
              _UsageRow(
                title: match.evolution.title,
                status: switch (match.status) {
                  EvoEligibilityStatus.eligible => 'قابل استفاده',
                  EvoEligibilityStatus.needsReview => 'نیازمند بررسی',
                  EvoEligibilityStatus.ineligible => 'نامناسب',
                },
                statusColor: switch (match.status) {
                  EvoEligibilityStatus.eligible => palette.success,
                  EvoEligibilityStatus.needsReview => palette.warning,
                  EvoEligibilityStatus.ineligible => palette.danger,
                },
                detail: match.reasons.isEmpty
                    ? 'شرط قابل‌تشخیصی برای این Evolution ثبت نشده است.'
                    : faDigits(match.reasons.first),
                extraDetails: _evolutionDetails(clubItem, match.evolution),
                expiresAt: match.evolution.expiresAt,
              ),
          ],
        ),
        const SizedBox(height: 10),
        _UsageCard(
          icon: Icons.extension_rounded,
          title: 'SBCهای فعال',
          loading: loading,
          error: sbcError,
          errorTitle: 'دریافت فهرست SBC ممکن نشد',
          onRetry: onRetry,
          emptyText: 'SBC فعالی از منبع دریافت نشد.',
          summary:
              '${faDigits(passingSbc)} شرط کارتی پاس • '
              '${faDigits(reviewSbc)} وابسته به ترکیب • '
              '${faDigits(blockedSbc)} قابل استفاده نیست',
          rows: [
            for (final match in sbcMatches)
              _UsageRow(
                title: match.challenge.title,
                status: switch (match.fit) {
                  PlayerSbcFit.cardRulesPassed => 'شرط کارتی پاس',
                  PlayerSbcFit.needsReview => 'وابسته به ترکیب',
                  PlayerSbcFit.blocked => 'قابل استفاده نیست',
                },
                statusColor: switch (match.fit) {
                  PlayerSbcFit.cardRulesPassed => palette.success,
                  PlayerSbcFit.needsReview => palette.warning,
                  PlayerSbcFit.blocked => palette.danger,
                },
                detail: switch (match.fit) {
                  PlayerSbcFit.cardRulesPassed =>
                    match.squadRequirements.isEmpty
                        ? 'شرط‌های کارتی این SBC پاس شدند.'
                        : 'شرط‌های کارتی پاس شدند؛ ${faDigits(match.squadRequirements.length)} شرط دیگر به ترکیب بستگی دارد.',
                  _ => faDigits(match.blocker ?? 'بررسی خودکار ممکن نیست.'),
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'SBCهایی که فقط شرط‌های ترکیبی دارند به‌عنوان «وابسته به ترکیب» علامت می‌خورند؛ FCBaz برای آن‌ها نتیجهٔ قطعی نمی‌سازد.',
          style: TextStyle(
            fontSize: 10.5,
            height: 1.6,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'تغییر آمار پس از Evolution فقط از داده ساختاریافتهٔ منبع محاسبه می‌شود؛ اگر منبع آمار نداشته باشد، خطی نمایش داده نمی‌شود.',
          style: TextStyle(
            fontSize: 10.5,
            height: 1.6,
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }

  List<String> _evolutionDetails(MyClubItem item, Evolution evolution) {
    final lines = <String>[];
    final projection = const EvolutionProjectionEngine().project(
      item,
      evolution,
    );
    if (projection != null && projection.hasChanges) {
      final parts = <String>[];
      for (final entry in projection.changes.entries) {
        if (entry.value == 0) continue;
        final label = _statLabel(entry.key);
        if (label == null) continue;
        final sign = entry.value > 0 ? '+' : '−';
        parts.add('$label $sign${faDigits(entry.value.abs())}');
      }
      if (parts.isNotEmpty) {
        lines.add('تغییر آمار طبق داده منبع: ${parts.join(' · ')}');
      }
    }
    if (evolution.cost > 0) {
      lines.add('هزینه: ${formatCoinsFa(evolution.cost)} سکه');
    }
    final stepTitles = [
      for (final step in evolution.steps)
        if (step.title.trim().isNotEmpty) step.title.trim(),
    ];
    if (stepTitles.isNotEmpty) {
      lines.add('مسیر مراحل: ${stepTitles.join(' ← ')}');
    }
    return lines;
  }

  String? _statLabel(String key) => switch (key) {
    'rating' => 'ریتینگ',
    'pace' => 'سرعت',
    'shooting' => 'شوت',
    'passing' => 'پاس',
    'dribbling' => 'دریبل',
    'defending' => 'دفاع',
    'physical' => 'فیزیک',
    'skill_moves' => 'SM',
    'weak_foot' => 'WF',
    _ => null,
  };

  int _evoRank(EvoEligibilityStatus status) => switch (status) {
    EvoEligibilityStatus.eligible => 0,
    EvoEligibilityStatus.needsReview => 1,
    EvoEligibilityStatus.ineligible => 2,
  };

  int _sbcRank(PlayerSbcFit fit) => switch (fit) {
    PlayerSbcFit.cardRulesPassed => 0,
    PlayerSbcFit.needsReview => 1,
    PlayerSbcFit.blocked => 2,
  };
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({
    required this.icon,
    required this.title,
    required this.loading,
    required this.error,
    required this.errorTitle,
    required this.onRetry,
    required this.emptyText,
    required this.summary,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final bool loading;
  final String? error;
  final String errorTitle;
  final VoidCallback onRetry;
  final String emptyText;
  final String summary;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasError = error != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: palette.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        ),
        subtitle: Text(
          loading
              ? 'در حال خواندن از منبع…'
              : hasError
              ? errorTitle
              : summary,
          style: TextStyle(
            fontSize: 11,
            color: hasError ? palette.danger : palette.textMuted,
          ),
        ),
        children: [
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (hasError)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Icon(Icons.cloud_off_rounded, color: palette.danger),
              title: Text(
                error!,
                style: TextStyle(fontSize: 11, color: palette.textMuted),
              ),
              trailing: TextButton(
                onPressed: onRetry,
                child: const Text('تلاش دوباره'),
              ),
            )
          else if (rows.isEmpty)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                emptyText,
                style: TextStyle(fontSize: 12, color: palette.textMuted),
              ),
            )
          else
            ...rows,
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.title,
    required this.status,
    required this.statusColor,
    required this.detail,
    this.extraDetails = const [],
    this.expiresAt,
  });

  final String title;
  final String status;
  final Color statusColor;
  final String detail;
  final List<String> extraDetails;
  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.5,
                    color: palette.textMuted,
                  ),
                ),
                for (final line in extraDetails)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                  ),
                if (expiresAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: DeadlineChip(
                        expiresAt: expiresAt,
                        compact: true,
                        showJalaliDate: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
