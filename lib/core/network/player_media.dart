/// Public media helpers for FCBaz player visuals.
///
/// Uses open CDN portrait paths keyed by player resource id.
class PlayerMedia {
  const PlayerMedia._();

  static String portrait(String playerId, {int year = 26}) {
    final id = playerId.trim();
    if (id.isEmpty) return '';
    return 'https://cdn.futbin.com/content/fifa$year/img/players/$id.png';
  }

  static List<String> portraitCandidates(String playerId) {
    final id = playerId.trim();
    if (id.isEmpty) return const [];
    return [
      portrait(id, year: 26),
      portrait(id, year: 25),
      portrait(id, year: 24),
    ];
  }

  static String resolve(String playerId, [String? existing]) {
    final current = (existing ?? '').trim();
    if (current.contains('cdn.futbin.com/content/fifa') &&
        current.endsWith('.png')) {
      return current;
    }
    return portrait(playerId);
  }
}
