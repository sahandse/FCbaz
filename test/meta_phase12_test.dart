import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/features/meta/domain/meta_player_entry.dart';
import 'package:fcbaz/features/players/domain/player.dart';

void main() {
  test('backend meta preserves verified rank tier and reason', () {
    final entry = MetaPlayerEntry.fromBackend({
      'id': '1',
      'name': 'Test Player',
      'rating': 90,
      'position': 'ST',
      'rank': 2,
      'tier': 'S',
      'reason': 'Backend supplied meta reason',
      'role': 'Advanced Forward',
      'meta_score': 94.5,
    });

    expect(entry.isVerifiedMeta, isTrue);
    expect(entry.rank, 2);
    expect(entry.tier, 'S');
    expect(entry.reason, isNotEmpty);
    expect(entry.score, 94.5);
  });

  test('public player fallback is never marked as verified meta', () {
    const player = Player(
      id: '2',
      name: 'Public Player',
      rating: 91,
      position: 'CM',
      positions: ['CM'],
      clubName: 'Club',
      leagueName: 'League',
      nationName: 'Nation',
      version: 'Gold',
      imageUrl: '',
      pace: 80,
      shooting: 80,
      passing: 90,
      dribbling: 88,
      defending: 75,
      physical: 78,
      skillMoves: 4,
      weakFoot: 4,
      roles: ['Playmaker'],
    );

    final entry = MetaPlayerEntry.fromPublic(player);

    expect(entry.isVerifiedMeta, isFalse);
    expect(entry.rank, isNull);
    expect(entry.tier, isEmpty);
    expect(entry.reason, isEmpty);
    expect(entry.score, isNull);
  });
}
