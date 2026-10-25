import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fcbaz/features/players/domain/player.dart';

const _hubPortrait = 'https://sahandse.github.io/FC27/img/players/231747.png';
const _eaPortrait =
    'https://ratings-images-prod.pulse.ea.com/FC25/full/player-portraits/p231747.png?padding=0.7';

Player _player({String id = '231747', String imageUrl = _hubPortrait}) => Player(
  id: id,
  name: 'Kylian Mbappé',
  rating: 91,
  position: 'ST',
  positions: const ['ST'],
  clubName: 'Real Madrid',
  leagueName: 'LALIGA EA SPORTS',
  nationName: 'France',
  version: 'Gold',
  imageUrl: imageUrl,
  pace: 96,
  shooting: 91,
  passing: 80,
  dribbling: 92,
  defending: 29,
  physical: 76,
  skillMoves: 5,
  weakFoot: 4,
  pricePs: 2888000,
  pricePc: 3379000,
);

void main() {
  test('numeric EA id resolves to the 512px official portrait', () {
    expect(_player().highResImageUrl, _eaPortrait);
  });

  test('special card ids keep their FC27 snapshot portrait', () {
    const hub = 'https://sahandse.github.io/FC27/img/players/special-1.png';
    final player = _player(id: 'futgg-sbc-64', imageUrl: hub);
    expect(player.highResImageUrl, hub);
  });

  test('large cards use the high resolution portrait with hub fallback', () {
    final source = File(
      'lib/features/players/presentation/player_item_visual.dart',
    ).readAsStringSync();
    expect(
      source,
      contains('compact ? player.imageUrl : player.highResImageUrl'),
    );
    expect(
      source,
      contains('compact ? player.highResImageUrl : player.imageUrl'),
    );
  });
}
