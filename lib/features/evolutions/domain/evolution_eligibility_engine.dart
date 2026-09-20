import '../../club/data/my_club_repository.dart';
import '../domain/evolution.dart';

enum EvoEligibilityStatus { eligible, ineligible, needsReview }

class EvoEligibilityResult {
  const EvoEligibilityResult({
    required this.status,
    required this.reasons,
  });

  final EvoEligibilityStatus status;
  final List<String> reasons;
}

class EvolutionEligibilityEngine {
  const EvolutionEligibilityEngine();

  EvoEligibilityResult evaluate(MyClubItem item, Evolution evolution) {
    if (evolution.requirementData.isEmpty) {
      return const EvoEligibilityResult(
        status: EvoEligibilityStatus.needsReview,
        reasons: ['شرایط ساختاریافته از منبع دریافت نشده است.'],
      );
    }

    final reasons = <String>[];
    var unknown = false;
    var failed = false;

    for (final requirement in evolution.requirementData) {
      final result = _checkRequirement(item, requirement);
      if (result == null) {
        unknown = true;
        reasons.add('یک شرط این Evolution نیاز به بررسی دستی دارد.');
      } else if (!result.$1) {
        failed = true;
        reasons.add(result.$2);
      }
    }

    if (failed) {
      return EvoEligibilityResult(
        status: EvoEligibilityStatus.ineligible,
        reasons: reasons,
      );
    }

    if (unknown) {
      return EvoEligibilityResult(
        status: EvoEligibilityStatus.needsReview,
        reasons: reasons,
      );
    }

    return const EvoEligibilityResult(
      status: EvoEligibilityStatus.eligible,
      reasons: ['همه شروط قابل‌تشخیص پاس شده‌اند.'],
    );
  }

  (bool, String)? _checkRequirement(
    MyClubItem item,
    Map<String, dynamic> req,
  ) {
    String norm(dynamic v) => (v ?? '')
        .toString()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll(' ', '');

    int? number(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse((value ?? '').toString());
    }

    final type = norm(req['type'] ?? req['name'] ?? req['key'] ?? req['stat']);
    final operator = (req['operator'] ?? req['op'] ?? '').toString();
    final value = req['value'] ??
        req['max'] ??
        req['min'] ??
        req['limit'] ??
        req['required'];

    bool compare(int actual, int expected) {
      if (operator.contains('>')) return actual >= expected;
      if (operator.contains('<')) return actual <= expected;
      if (req.containsKey('min') || type.startsWith('min')) {
        return actual >= expected;
      }
      return actual <= expected;
    }

    final n = number(value);

    if (type.contains('overall') || type == 'ovr' || type.contains('rating')) {
      if (n == null) return null;
      final ok = compare(item.rating, n);
      return (ok, 'ریتینگ ' + item.rating.toString() + ' با شرط ' + n.toString() + ' سازگار نیست.');
    }

    if (type.contains('pace') || type == 'pac') {
      if (n == null) return null;
      final ok = compare(item.pace, n);
      return (ok, 'PAC ' + item.pace.toString() + ' با شرط ' + n.toString() + ' سازگار نیست.');
    }

    if (type.contains('shoot') || type == 'sho') {
      if (n == null) return null;
      final ok = compare(item.shooting, n);
      return (ok, 'SHO ' + item.shooting.toString() + ' با شرط ' + n.toString() + ' سازگار نیست.');
    }

    if (type.contains('pass') || type == 'pas') {
      if (n == null) return null;
      final ok = compare(item.passing, n);
      return (ok, 'PAS ' + item.passing.toString() + ' با شرط ' + n.toString() + ' سازگار نیست.');
    }

    if (type.contains('drib') || type == 'dri') {
      if (n == null) return null;
      final ok = compare(item.dribbling, n);
      return (ok, 'DRI ' + item.dribbling.toString() + ' با شرط ' + n.toString() + ' سازگار نیست.');
    }

    if (type.contains('defend') || type == 'def') {
      if (n == null) return null;
      final ok = compare(item.defending, n);
      return (ok, 'DEF ' + item.defending.toString() + ' با شرط ' + n.toString() + ' سازگار نیست.');
    }

    if (type.contains('physical') || type == 'phy') {
      if (n == null) return null;
      final ok = compare(item.physical, n);
      return (ok, 'PHY ' + item.physical.toString() + ' با شرط ' + n.toString() + ' سازگار نیست.');
    }

    if (type.contains('skillmove') || type == 'sm') {
      if (n == null) return null;
      final ok = compare(item.skillMoves, n);
      return (ok, 'Skill Moves ' + item.skillMoves.toString() + '★ با شرط ' + n.toString() + '★ سازگار نیست.');
    }

    if (type.contains('weakfoot') || type == 'wf') {
      if (n == null) return null;
      final ok = compare(item.weakFoot, n);
      return (ok, 'Weak Foot ' + item.weakFoot.toString() + '★ با شرط ' + n.toString() + '★ سازگار نیست.');
    }

    if (type.contains('position')) {
      final raw = req['values'] ?? req['positions'] ?? req['value'];
      final values = raw is List
          ? raw.map((e) => e.toString().toUpperCase()).toSet()
          : raw == null
              ? <String>{}
              : {raw.toString().toUpperCase()};
      if (values.isEmpty) return null;

      final ownedPositions = {
        item.position.toUpperCase(),
        ...item.positions.map((e) => e.toUpperCase()),
      };
      final ok = ownedPositions.any(values.contains);
      return (ok, 'پست کارت با پست‌های مجاز Evolution سازگار نیست.');
    }

    if (type.contains('club') || type.contains('league') || type.contains('nation')) {
      final target = (req['value'] ?? req['name'] ?? '').toString();
      if (target.isEmpty) return null;
      final actual = type.contains('club')
          ? item.clubName
          : type.contains('league')
              ? item.leagueName
              : item.nationName;
      final ok = actual.toLowerCase() == target.toLowerCase();
      return (ok, actual + ' با شرط ' + target + ' سازگار نیست.');
    }

    return null;
  }
}
