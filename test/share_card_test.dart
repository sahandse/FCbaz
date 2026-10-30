import 'dart:ui' as ui;

import 'package:fcbaz/src/share/share_card.dart';
import 'package:flutter_test/flutter_test.dart';

const _sample = ShareCardData(
  eyebrow: 'SQUAD BUILDER',
  title: 'ترکیب اصلی',
  subtitle: '4-3-3 • FC 27',
  metrics: [
    ShareCardMetric(label: 'ریتینگ', value: '۸۵'),
    ShareCardMetric(label: 'شیمی', value: '۳۰/۳۳'),
    ShareCardMetric(label: 'بازیکن', value: '۱۱'),
  ],
  rows: [
    ShareCardRow(position: 'GK', name: 'علیرضا بیرانوند', rating: 82),
    ShareCardRow(position: 'RB', name: 'رامین رضاییان', rating: 81),
    ShareCardRow(position: 'CB', name: 'محمدحسین کنعانی‌زادگان', rating: 80),
    ShareCardRow(position: 'CB', name: 'شجاع خلیل‌زاده', rating: 79),
    ShareCardRow(position: 'LB', name: 'میلاد محمدی', rating: 78),
    ShareCardRow(position: 'CDM', name: 'سعید عزت‌اللهی', rating: 79),
    ShareCardRow(position: 'CM', name: 'احمد نوراللهی', rating: 80),
    ShareCardRow(position: 'CAM', name: 'مهدی ترابی', rating: 81),
    ShareCardRow(position: 'RW', name: 'علیرضا جهانبخش', rating: 82),
    ShareCardRow(position: 'ST', name: 'مهدی طارمی', rating: 84),
    ShareCardRow(position: 'LW', name: 'سردار آزمون', rating: 83),
  ],
  footer: 'FCBaz • دستیار فارسی FC 27',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a real 1080x1350 png from the supplied squad data', () async {
    final bytes = await const ShareCardRenderer().renderPng(_sample);

    expect(bytes.length, greaterThan(1000));
    expect(bytes.sublist(0, 8), [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, ShareCardRenderer.cardSize.width.round());
    expect(frame.image.height, ShareCardRenderer.cardSize.height.round());
    frame.image.dispose();
    codec.dispose();
  });

  test('renders long names and a single row without throwing', () async {
    const data = ShareCardData(
      eyebrow: 'FUT DRAFT',
      title: 'درافت FC 27',
      metrics: [ShareCardMetric(label: 'ریتینگ', value: '۸۱')],
      rows: [
        ShareCardRow(
          position: 'ST',
          name: 'بازیکن با نام بسیار بسیار طولانی که باید با سه‌نقطه کوتاه شود',
          rating: 77,
        ),
      ],
    );
    final bytes = await const ShareCardRenderer().renderPng(data);
    expect(bytes.length, greaterThan(1000));
  });

  test('text export lists every metric and every player', () {
    final text = shareCardToText(_sample);

    expect(text, contains('ترکیب اصلی'));
    expect(text, contains('4-3-3 • FC 27'));
    expect(text, contains('ریتینگ: ۸۵'));
    expect(text, contains('شیمی: ۳۰/۳۳'));
    for (final row in _sample.rows) {
      expect(text, contains(row.name));
      expect(text, contains('${row.position} — ${row.name}'));
    }
    expect(text, contains('FCBaz • دستیار فارسی FC 27'));
  });

  test(
    'text export keeps Persian digits for ratings and skips blank subtitle',
    () {
      const data = ShareCardData(
        eyebrow: 'SQUAD',
        title: 'ترکیب من',
        subtitle: '   ',
        rows: [ShareCardRow(position: 'GK', name: 'دروازه‌بان', rating: 90)],
      );
      final text = shareCardToText(data);

      expect(text, isNot(contains('ریتینگ')));
      expect(text, contains('GK — دروازه‌بان (۹۰)'));
      expect(text.split('\n').first, 'ترکیب من');
    },
  );

  test('card renderer keeps the fixed share size', () {
    expect(ShareCardRenderer.cardSize.width, 1080);
    expect(ShareCardRenderer.cardSize.height, 1350);
  });
}
