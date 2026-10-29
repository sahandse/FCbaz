import 'package:fcbaz/features/players/domain/player.dart';
import 'package:fcbaz/features/squad/domain/squad_models.dart';
import 'package:fcbaz/features/squad/presentation/chemistry_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Player _player({
  required String id,
  required String club,
  required String league,
  required String nation,
}) => Player(
  id: id,
  name: 'Player $id',
  rating: 84,
  position: 'CM',
  positions: const ['CM'],
  clubName: club,
  leagueName: league,
  nationName: nation,
  version: 'FC 27',
  imageUrl: '',
  pace: 80,
  shooting: 80,
  passing: 80,
  dribbling: 80,
  defending: 80,
  physical: 80,
  skillMoves: 3,
  weakFoot: 3,
);

void main() {
  test('links join players that share club, league or nation', () {
    final formation = Formations.byId('433');
    final players = {
      'gk': _player(id: 'a', club: 'Alpha', league: 'L1', nation: 'N1'),
      'lb': _player(id: 'b', club: 'Alpha', league: 'L1', nation: 'N2'),
      'lcb': _player(id: 'c', club: 'Beta', league: 'L1', nation: 'N3'),
    };

    final links = buildChemistryLinks(
      formation: formation,
      players: players,
      chemistryBySlot: const {'gk': 3, 'lb': 3, 'lcb': 3},
      size: const Size(320, 440),
    );

    expect(links, hasLength(3));
    final strong = links.where((link) => link.isStrong);
    expect(strong, hasLength(1));
    expect(strong.single.from, isNot(strong.single.to));
  });

  test('players without chemistry or shared traits create no links', () {
    final formation = Formations.byId('433');
    final players = {
      'gk': _player(id: 'a', club: 'Alpha', league: 'L1', nation: 'N1'),
      'lb': _player(id: 'b', club: 'Beta', league: 'L2', nation: 'N2'),
      'lcb': _player(id: 'c', club: 'Alpha', league: 'L1', nation: 'N1'),
    };

    final links = buildChemistryLinks(
      formation: formation,
      players: players,
      chemistryBySlot: const {'gk': 3, 'lb': 3, 'lcb': 0},
      size: const Size(320, 440),
    );

    expect(links, isEmpty);
  });

  testWidgets('chemistry web renders and respects reduced motion', (
    tester,
  ) async {
    const links = [
      ChemistryLink(from: Offset(40, 40), to: Offset(180, 120), strength: 3),
      ChemistryLink(from: Offset(180, 120), to: Offset(260, 260), strength: 1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Center(
            child: SizedBox(
              width: 300,
              height: 400,
              child: ChemistryLinks(
                links: links,
                strongColor: Colors.lime,
                weakColor: Colors.cyan,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ChemistryLinks), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
