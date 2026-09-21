import 'package:flutter_test/flutter_test.dart';
import 'package:fcbaz/core/network/free_github_content.dart';
import 'package:fcbaz/core/network/player_media.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads bundled free GitHub content', () async {
    final content = FreeGithubContent();
    final news = await content.news();
    final sbcs = await content.sbcs();
    final evos = await content.evolutions();
    final objectives = await content.objectives();
    final scouts = await content.scoutLists();

    expect(news, isNotEmpty);
    expect(sbcs, isNotEmpty);
    expect(evos, isNotEmpty);
    expect(objectives, isNotEmpty);
    expect(scouts, isNotEmpty);
    expect(sbcs.first['source'], 'fcbaz-free-guide');
  });

  test('player media prefers existing http image', () {
    const sofifa =
        'https://cdn.sofifa.net/players/231/747/26_120.png';
    expect(PlayerMedia.resolve('231747', sofifa), sofifa);
    expect(PlayerMedia.sofifa('231747'), contains('231/747'));
    expect(PlayerMedia.portraitCandidates('231747', sofifa).first, sofifa);
  });
}
