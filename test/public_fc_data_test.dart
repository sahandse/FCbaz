import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:fcbaz/core/network/public_fc_data.dart';

void main() {
  setUp(() {
    PublicFcData.debugResetCatalog();
  });

  test('loads real free catalog without fabricated ratings', () async {
    final slim = [
      {
        'id': '231747',
        'n': 'K. Mbappé',
        'ln': 'Kylian Mbappé Lottin',
        'r': 91,
        'p': 'ST',
        'ps': ['ST', 'LW'],
        'c': 'Real Madrid',
        'l': 'La Liga',
        'na': 'France',
        'pac': 97,
        'sho': 90,
        'pas': 81,
        'dri': 92,
        'defe': 37,
        'phy': 76,
        'sm': 5,
        'wf': 4,
        'img': '',
      },
      {
        'id': '252371',
        'n': 'J. Bellingham',
        'r': 90,
        'p': 'CAM',
        'ps': ['CAM', 'CM'],
        'c': 'Real Madrid',
        'l': 'La Liga',
        'na': 'England',
        'pac': 80,
        'sho': 86,
        'pas': 83,
        'dri': 90,
        'defe': 78,
        'phy': 85,
        'sm': 4,
        'wf': 4,
        'img': '',
      },
    ];

    final bytes = Uint8List.fromList(
      gzip.encode(utf8.encode(jsonEncode(slim))),
    );

    final data = PublicFcData(catalogBytes: bytes);
    final players = await data.getPlayers();
    expect(players.length, 2);
    expect(players.first.name, 'K. Mbappé');
    expect(players.first.rating, 91);
    expect(players.first.pace, 97);

    final search = await data.search('bell');
    expect(search, hasLength(1));
    expect(search.first.id, '252371');

    final filtered = await data.getFiltered(
      params: {
        'position': 'ST',
        'min_rating': '90',
        'max_rating': '99',
        'page': '1',
      },
    );
    expect(filtered, hasLength(1));
    expect(filtered.first.position, 'ST');

    // Free catalog must not invent coin prices.
    final price = await data.getPrice('231747');
    expect(price, isNull);
  });

  test('rejects zero-rating catalog rows', () async {
    final slim = [
      {
        'id': '1',
        'n': 'Fake',
        'r': 0,
        'p': 'ST',
        'ps': ['ST'],
        'c': '',
        'l': '',
        'na': '',
        'pac': 0,
        'sho': 0,
        'pas': 0,
        'dri': 0,
        'defe': 0,
        'phy': 0,
        'sm': 0,
        'wf': 0,
        'img': '',
      },
    ];
    final bytes = Uint8List.fromList(
      gzip.encode(utf8.encode(jsonEncode(slim))),
    );
    final data = PublicFcData(catalogBytes: bytes);
    final players = await data.getPlayers();
    expect(players, isEmpty);
  });
}
