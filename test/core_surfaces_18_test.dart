import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('1.8 player details uses shared FC item visual', () {
    final source = File('lib/features/players/presentation/player_details_screen.dart').readAsStringSync();
    expect(source, contains('PlayerItemVisual'));
    expect(source, contains('PLAYER ITEM'));
    expect(source, contains('FACE STATS'));
    expect(source, contains('OTHER VERSIONS'));
  });

  test('1.8 My Club is a collection grid', () {
    final source = File('lib/features/club/presentation/my_club_screen.dart').readAsStringSync();
    expect(source, contains('YOUR CLUB'));
    expect(source, contains('COLLECTION'));
    expect(source, contains('GridView.builder'));
    expect(source, contains('PlayerItemVisual'));
    expect(source, contains('UNTRADEABLE'));
  });

  test('1.8 version is production increment', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(RegExp(r'^version: 1\.8\.0\+\d+$', multiLine: true).hasMatch(pubspec), isTrue);
  });
}
