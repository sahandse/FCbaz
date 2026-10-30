import 'package:fcbaz/core/network/live_fc27_catalog.dart';
import 'package:fcbaz/features/evolutions/data/evolution_repository.dart';
import 'package:fcbaz/features/evolutions/domain/evolution.dart';
import 'package:fcbaz/features/home/content_hub_screen.dart';
import 'package:fcbaz/features/home/home_repository.dart';
import 'package:fcbaz/features/sbc/data/sbc_repository.dart';
import 'package:fcbaz/features/sbc/domain/sbc.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSbcRepository extends SbcRepository {
  _FakeSbcRepository(this.items, {this.error});

  final List<SbcChallenge> items;
  final String? error;

  @override
  Future<List<SbcChallenge>> getActive({bool forceRefresh = false}) async {
    if (error != null) throw error!;
    return items;
  }
}

class _FakeEvolutionRepository extends EvolutionRepository {
  _FakeEvolutionRepository(this.items);

  final List<Evolution> items;

  @override
  Future<List<Evolution>> getActive({bool forceRefresh = false}) async => items;
}

class _FakeHomeRepository extends HomeRepository {
  _FakeHomeRepository(this.items);

  final List<HomeObjective> items;

  @override
  Future<List<HomeObjective>> getObjectives({
    bool forceRefresh = false,
  }) async => items;
}

class _FakeCatalog extends LiveFc27Catalog {
  _FakeCatalog(this.generated);

  final DateTime? generated;

  @override
  Future<DateTime?> generatedAt() async => generated;
}

void main() {
  final now = DateTime(2026, 10, 23, 12);

  SbcChallenge sbc({
    required String id,
    required String title,
    DateTime? expiresAt,
    String reward = '',
  }) => SbcChallenge.fromJson({
    'id': id,
    'title': title,
    'reward': reward,
    'expires_at': expiresAt?.toIso8601String(),
  });

  Evolution evolution({
    required String id,
    required String title,
    DateTime? expiresAt,
    int cost = 0,
  }) => Evolution.fromJson({
    'id': id,
    'title': title,
    'cost': cost,
    'expires_at': expiresAt?.toIso8601String(),
  });

  HomeObjective objective({
    required String id,
    required String title,
    DateTime? expiresAt,
    int taskCount = 0,
  }) => HomeObjective.fromJson({
    'id': id,
    'title': title,
    'expires_at': expiresAt?.toIso8601String(),
    'task_count': taskCount,
  });

  Widget host(Widget child) => MaterialApp(
    theme: FCBazTheme.dark(),
    builder: (context, inner) =>
        Directionality(textDirection: TextDirection.rtl, child: inner!),
    home: child,
  );

  testWidgets('shows real countdowns and every live content section', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      host(
        ContentHubScreen(
          sbcRepository: _FakeSbcRepository([
            sbc(
              id: 'sbc-soon',
              title: 'SBC One',
              expiresAt: now.add(const Duration(hours: 2)),
              reward: 'Rare Pack',
            ),
            sbc(id: 'sbc-open', title: 'SBC Two'),
          ]),
          evolutionRepository: _FakeEvolutionRepository([
            evolution(
              id: 'evo-1',
              title: 'Evo One',
              expiresAt: now.add(const Duration(days: 3)),
              cost: 25000,
            ),
          ]),
          homeRepository: _FakeHomeRepository([
            objective(
              id: 'obj-1',
              title: 'Objective One',
              expiresAt: now.add(const Duration(minutes: 30)),
              taskCount: 3,
            ),
          ]),
          liveCatalog: _FakeCatalog(now.subtract(const Duration(hours: 2))),
          now: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مرکز محتوا'), findsOneWidget);
    expect(find.text('NEXT DEADLINE'), findsOneWidget);
    expect(find.text('۳۰ دقیقه مانده'), findsWidgets);
    expect(find.text('پایان نزدیک'), findsOneWidget);
    expect(find.text('SBCهای فعال (۲)'), findsOneWidget);
    expect(find.text('SBC One'), findsWidgets);
    expect(find.textContaining('زمان پایان اعلام نشده'), findsOneWidget);
    expect(find.textContaining('پاداش: Rare Pack'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Objectiveهای فعال (۱)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('۳ تسک'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('never invents a countdown when the source has no deadlines', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      host(
        ContentHubScreen(
          sbcRepository: _FakeSbcRepository([
            sbc(id: 'sbc-open', title: 'SBC Without Deadline'),
          ]),
          evolutionRepository: _FakeEvolutionRepository(const []),
          homeRepository: _FakeHomeRepository(const []),
          liveCatalog: _FakeCatalog(now.subtract(const Duration(hours: 2))),
          now: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('هیچ زمان پایانی در داده فعلی ثبت نشده است.'),
      findsOneWidget,
    );
    expect(find.text('ENDING SOON'), findsNothing);
    expect(find.text('پایان نزدیک'), findsNothing);
    expect(find.textContaining('زمان پایان اعلام نشده'), findsOneWidget);
    expect(find.text('Evolution فعالی از منبع دریافت نشد.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('surfaces a section error instead of fabricated content', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      host(
        ContentHubScreen(
          sbcRepository: _FakeSbcRepository(
            const [],
            error: 'منبع SBC در دسترس نیست',
          ),
          evolutionRepository: _FakeEvolutionRepository(const []),
          homeRepository: _FakeHomeRepository(const []),
          liveCatalog: _FakeCatalog(now.subtract(const Duration(hours: 2))),
          now: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('دریافت این بخش ممکن نشد.'), findsOneWidget);
    expect(find.text('تلاش دوباره'), findsOneWidget);
    expect(find.textContaining('SBC فعالی'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
