import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';

void main() {
  test('faDigits converts every Latin digit and leaves text intact', () {
    expect(faDigits(1234), '۱۲۳۴');
    expect(faDigits('91 • ST'), '۹۱ • ST');
    expect(faDigits(''), '');
  });

  test('formatNewsDateFa localizes English news dates', () {
    expect(formatNewsDateFa('October 26, 2026'), '۲۶ اکتبر ۲۰۲۶');
    expect(formatNewsDateFa('January 3, 2027'), '۳ ژانویه ۲۰۲۷');
  });

  test('formatNewsDateFa falls back to digit conversion only', () {
    expect(formatNewsDateFa('2026/10/26'), '۲۰۲۶/۱۰/۲۶');
    expect(formatNewsDateFa(''), '');
  });

  test('formatCoinsFa groups thousands with Persian digits', () {
    expect(formatCoinsFa(1234567), '۱,۲۳۴,۵۶۷');
    expect(formatCoinsFa(0), '—');
    expect(compactCoinsFa(1500000), '۱.۵M');
  });
}
