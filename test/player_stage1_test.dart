import 'package:flutter_test/flutter_test.dart';

import 'package:fcbaz/features/players/data/player_repository.dart';
import 'package:fcbaz/features/players/domain/player.dart';

void main() {
  test('parses full FC27 player payload', () {
    final player = Player.fromJson({
      'id': 'p1',
      'name': 'Test Player',
      'rating': 88,
      'position': 'ST',
      'positions': ['CF'],
      'club_name': 'Club',
      'league_name': 'League',
      'nation_name': 'Nation',
      'version': 'Gold Rare',
      'rarity': 'Rare',
      'card_type': 'Gold',
      'price_ps': 125000,
      'price_pc': 131000,
      'pace': 90,
      'shooting': 89,
      'passing': 80,
      'dribbling': 87,
      'defending': 40,
      'physical': 78,
      'skill_moves': 4,
      'weak_foot': 5,
      'playstyles': ['Finesse Shot'],
      'playstyles_plus': ['Quick Step+'],
      'roles': ['Advanced Forward++'],
      'in_game_stats': {
        'acceleration': 92,
        'sprint_speed': 89,
      },
    });

    expect(player.rating, 88);
    expect(player.position, 'ST');
    expect(player.positions, contains('CF'));
    expect(player.rarity, 'Rare');
    expect(player.cardType, 'Gold');
    expect(player.pricePs, 125000);
    expect(player.playStyles, contains('Finesse Shot'));
    expect(player.playStylesPlus, contains('Quick Step+'));
    expect(player.roles, contains('Advanced Forward++'));
    expect(player.inGameStats['acceleration'], 92);
  });

  test('advanced filter reports active filter count', () {
    const filter = PlayerFilter(
      position: 'ST',
      minRating: 85,
      maxRating: 90,
      minPrice: 10000,
      maxPrice: 200000,
      version: 'Gold Rare',
      platform: 'pc',
      sort: PlayerSort.priceAsc,
    );

    expect(filter.activeCount, 5);
  });
}
