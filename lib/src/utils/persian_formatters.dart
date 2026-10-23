const _persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
const _jalaliMonths = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];
const _weekdays = [
  'شنبه',
  'یکشنبه',
  'دوشنبه',
  'سه‌شنبه',
  'چهارشنبه',
  'پنجشنبه',
  'جمعه',
];

String faDigits(Object? value) {
  final text = '$value';
  return text.replaceAllMapped(
    RegExp('[0-9]'),
    (match) => _persianDigits[int.parse(match.group(0)!)],
  );
}

int _div(int a, int b) => (a / b).floor();

List<int> _gregorianToJalali(int gy, int gm, int gd) {
  const monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  final gy2 = gm > 2 ? gy + 1 : gy;
  var days =
      355666 +
      (365 * gy) +
      _div(gy2 + 3, 4) -
      _div(gy2 + 99, 100) +
      _div(gy2 + 399, 400) +
      gd +
      monthDays.take(gm - 1).fold<int>(0, (sum, value) => sum + value);
  var jy = -1595 + (33 * _div(days, 12053));
  days %= 12053;
  jy += 4 * _div(days, 1461);
  days %= 1461;
  if (days > 365) {
    jy += _div(days - 1, 365);
    days = (days - 1) % 365;
  }
  final jm = days < 186 ? 1 + _div(days, 31) : 7 + _div(days - 186, 30);
  final jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);
  return [jy, jm, jd];
}

String formatJalaliDate(DateTime value) {
  final local = value.toLocal();
  final jalali = _gregorianToJalali(local.year, local.month, local.day);
  final weekday = _weekdays[(local.weekday + 1) % 7];
  return '$weekday ${faDigits(jalali[2])} ${_jalaliMonths[jalali[1] - 1]} ${faDigits(jalali[0])}';
}

String formatJalaliShort(DateTime value) {
  final local = value.toLocal();
  final jalali = _gregorianToJalali(local.year, local.month, local.day);
  return '${faDigits(jalali[2])} ${_jalaliMonths[jalali[1] - 1]}';
}

String formatJalaliDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${formatJalaliDate(local)} • ${faDigits('$hour:$minute')}';
}

String relativeTimeFa(DateTime value, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(value.toLocal());
  if (difference.inMinutes < 1) return 'همین حالا';
  if (difference.inMinutes < 60) {
    return '${faDigits(difference.inMinutes)} دقیقه پیش';
  }
  if (difference.inHours < 24) {
    return '${faDigits(difference.inHours)} ساعت پیش';
  }
  if (difference.inDays < 7) {
    return '${faDigits(difference.inDays)} روز پیش';
  }
  return formatJalaliDate(value);
}

String relativeDeadlineFa(DateTime expiresAt, {DateTime? now}) {
  final remaining = expiresAt.toLocal().difference(now ?? DateTime.now());
  if (remaining <= Duration.zero) return 'پایان یافته';
  if (remaining.inMinutes < 60) {
    return '${faDigits(remaining.inMinutes.clamp(1, 59))} دقیقه مانده';
  }
  if (remaining.inHours < 24) {
    return '${faDigits(remaining.inHours)} ساعت مانده';
  }
  final days = (remaining.inHours / 24).ceil();
  return '${faDigits(days)} روز مانده';
}

String compactCoinsFa(int value) {
  if (value <= 0) return '—';
  if (value >= 1000000) {
    final amount = value / 1000000;
    return faDigits('${amount.toStringAsFixed(amount >= 10 ? 0 : 1)}M');
  }
  if (value >= 1000) {
    final amount = value / 1000;
    return faDigits('${amount.toStringAsFixed(amount >= 100 ? 0 : 1)}K');
  }
  return faDigits(value);
}
