import 'package:flutter_test/flutter_test.dart';

import 'package:fcbaz/features/club/data/my_club_repository.dart';
import 'package:fcbaz/features/club/domain/club_inventory_analysis.dart';

MyClubItem item({
  required String id,
  required String name,
  required int rating,
  required String position,
  String club = 'Club',
  String league = 'League',
  String nation = 'Nation',
  String version = 'Gold',
  int price = 0,
  bool untradeable = false,
}) => MyClubItem(
      playerId: id,
      playerName: name,
      rating: rating,
      position: position,
      positions: [position],
      clubName: club,
      leagueName: league,
      nationName: nation,
      version: version,
      imageUrl: '',
      pace: 80,
      shooting: 80,
      passing: 80,
      dribbling: 80,
      defending: 80,
      physical: 80,
      skillMoves: 4,
      weakFoot: 4,
      acquisitionPrice: price,
      untradeable: untradeable,
    );

void main() {
  const analysis = ClubInventoryAnalysis();

  test('filters locally by query position and trade status', () {
    final source = [
      item(id: '1', name: 'Alpha', rating: 90, position: 'ST', club: 'Madrid'),
      item(id: '2', name: 'Beta', rating: 88, position: 'CM', untradeable: true),
    ];

    expect(
      analysis.filter(source, const ClubInventoryFilter(query: 'madrid')).single.playerId,
      '1',
    );
    expect(
      analysis.filter(source, const ClubInventoryFilter(position: 'CM')).single.playerId,
      '2',
    );
    expect(
      analysis.filter(
        source,
        const ClubInventoryFilter(trade: ClubTradeFilter.untradeable),
      ).single.playerId,
      '2',
    );
  });

  test('detects same card metadata without relying on player id', () {
    final source = [
      item(id: '1', name: 'Alpha', rating: 90, position: 'ST', version: 'Special'),
      item(id: 'different-id', name: 'Alpha', rating: 90, position: 'ST', version: 'Special'),
      item(id: '3', name: 'Alpha', rating: 91, position: 'ST', version: 'Special'),
    ];

    final groups = analysis.duplicateGroups(source);
    expect(groups, hasLength(1));
    expect(groups.single.items, hasLength(2));
  });

  test('sorts by acquisition price when requested', () {
    final source = [
      item(id: '1', name: 'A', rating: 90, position: 'ST', price: 1000),
      item(id: '2', name: 'B', rating: 80, position: 'ST', price: 5000),
    ];

    final result = analysis.filter(
      source,
      const ClubInventoryFilter(sort: ClubSort.acquisitionPrice),
    );
    expect(result.first.playerId, '2');
  });
}
