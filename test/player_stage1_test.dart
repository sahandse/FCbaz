import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/players/data/player_repository.dart';
import 'package:fcbaz/features/players/domain/player.dart';

void main() {
  test('parses FC27 player payload and filters by position/rating', () {
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
      'pace': 90,
      'shooting': 89,
      'passing': 80,
      'dribbling': 87,
      'defending': 40,
      'physical': 78,
      'skill_moves': 4,
      'weak_foot': 5,
    });

    expect(player.rating, 88);
    expect(player.position, 'ST');
    expect(player.positions, contains('CF'));

    final repository = PlayerRepository();
    final filtered = repository.applyFilter(
      [player],
      const PlayerFilter(position: 'CF', minRating: 85, maxRating: 90),
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.id, 'p1');
  });
}
