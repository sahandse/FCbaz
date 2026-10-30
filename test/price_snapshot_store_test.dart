import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fcbaz/features/market/data/price_snapshot_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 10, 23, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('keeps only real positive observations', () async {
    final store = PriceSnapshotStore(now: () => now);

    expect(await store.record('p1', price: 0, observedAt: now), isEmpty);
    expect(await store.record('', price: 5000, observedAt: now), isEmpty);

    final history = await store.record('p1', price: 5000, observedAt: now);
    expect(history, hasLength(1));
    expect(history.single.price, 5000);
    expect(history.single.time, now);

    expect(await store.getHistory(''), isEmpty);
  });

  test('appends new prices in observation order', () async {
    final store = PriceSnapshotStore(now: () => now);

    await store.record(
      'p1',
      price: 4500,
      observedAt: now.subtract(const Duration(days: 1)),
    );
    await store.record('p1', price: 4800, observedAt: now);

    final history = await store.getHistory('p1');
    expect(history.map((e) => e.price), [4500, 4800]);
    expect(history.first.time.isBefore(history.last.time), isTrue);
  });

  test('collapses repeated unchanged prices inside the minimum gap', () async {
    final store = PriceSnapshotStore(now: () => now);

    await store.record('p1', price: 5000, observedAt: now);
    await store.record(
      'p1',
      price: 5000,
      observedAt: now.add(const Duration(hours: 2)),
    );
    expect(await store.getHistory('p1'), hasLength(1));

    await store.record(
      'p1',
      price: 5000,
      observedAt: now.add(const Duration(hours: 7)),
    );
    expect(await store.getHistory('p1'), hasLength(2));
  });

  test(
    'always records a real price change and ignores time going backwards',
    () async {
      final store = PriceSnapshotStore(now: () => now);

      await store.record('p1', price: 5000, observedAt: now);
      await store.record(
        'p1',
        price: 5100,
        observedAt: now.add(const Duration(minutes: 5)),
      );
      expect(await store.getHistory('p1'), hasLength(2));

      await store.record(
        'p1',
        price: 9000,
        observedAt: now.subtract(const Duration(days: 1)),
      );
      final history = await store.getHistory('p1');
      expect(history, hasLength(2));
      expect(history.last.price, 5100);
    },
  );

  test('separates platforms and players', () async {
    final store = PriceSnapshotStore(now: () => now);

    await store.record('p1', price: 5000, observedAt: now);
    await store.record('p1', price: 7000, platform: 'pc', observedAt: now);
    await store.record('p2', price: 9000, observedAt: now);

    expect((await store.getHistory('p1')).single.price, 5000);
    expect((await store.getHistory('p1', platform: 'pc')).single.price, 7000);
    expect((await store.getHistory('p2')).single.price, 9000);
  });

  test('drops snapshots older than the retention window', () async {
    final store = PriceSnapshotStore(now: () => now);

    await store.record(
      'p1',
      price: 4000,
      observedAt: now.subtract(const Duration(days: 90)),
    );
    await store.record('p1', price: 5000, observedAt: now);

    final history = await store.getHistory('p1');
    expect(history, hasLength(1));
    expect(history.single.price, 5000);
  });

  test('caps stored samples while keeping the newest ones', () async {
    final store = PriceSnapshotStore(now: () => now);
    final start = now.subtract(const Duration(minutes: 300));

    for (var i = 0; i < PriceSnapshotStore.maxSamplesPerPlayer + 5; i++) {
      await store.record(
        'p1',
        price: 1000 + i,
        observedAt: start.add(Duration(minutes: i)),
      );
    }

    final history = await store.getHistory('p1');
    expect(history, hasLength(PriceSnapshotStore.maxSamplesPerPlayer));
    expect(
      history.last.price,
      1000 + PriceSnapshotStore.maxSamplesPerPlayer + 4,
    );
  });

  test('treats corrupt storage as empty instead of inventing points', () async {
    SharedPreferences.setMockInitialValues({
      'fcbaz_price_snapshots_v1_p1_console': 'not-json',
    });
    final store = PriceSnapshotStore(now: () => now);

    expect(await store.getHistory('p1'), isEmpty);

    final history = await store.record('p1', price: 5000, observedAt: now);
    expect(history, hasLength(1));
  });

  test('clear removes only the requested stream', () async {
    final store = PriceSnapshotStore(now: () => now);

    await store.record('p1', price: 5000, observedAt: now);
    await store.record('p1', price: 7000, platform: 'pc', observedAt: now);
    await store.clear('p1');

    expect(await store.getHistory('p1'), isEmpty);
    expect(await store.getHistory('p1', platform: 'pc'), hasLength(1));
  });
}
