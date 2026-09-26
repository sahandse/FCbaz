import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/notifications/background_price_worker.dart';

void main() {
  test('Phase 20 background price task has stable identifiers', () {
    expect(backgroundPriceCheckUniqueName, 'fcbaz-background-price-check');
    expect(backgroundPriceCheckTask, 'fcbaz.price_check');
  });

  test('Phase 20 does not poll more frequently than Android minimum', () {
    expect(
      backgroundPriceCheckFrequency,
      greaterThanOrEqualTo(const Duration(minutes: 15)),
    );
  });
}
