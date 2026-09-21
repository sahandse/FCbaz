/// Public media helpers for FCBaz player visuals.
///
/// Prefers catalog Sofifa URLs when present, then open CDN portraits.
class PlayerMedia {
  const PlayerMedia._();

  static String portrait(String playerId, {int year = 26}) {
    final id = playerId.trim();
    if (id.isEmpty) return '';
    return 'https://cdn.futbin.com/content/fifa$year/img/players/$id.png';
  }

  static String sofifa(String playerId, {int year = 26}) {
    final id = playerId.trim();
    if (id.isEmpty || id.length < 3) return '';
    final padded = id.padLeft(6, '0');
    final a = padded.substring(0, 3);
    final b = padded.substring(3);
    return 'https://cdn.sofifa.net/players/$a/$b/${year}_120.png';
  }

  static List<String> portraitCandidates(String playerId, [String? existing]) {
    final id = playerId.trim();
    final current = (existing ?? '').trim();
    final out = <String>[];
    void add(String url) {
      if (url.isNotEmpty && !out.contains(url)) out.add(url);
    }

    add(current);
    if (id.isNotEmpty) {
      add(sofifa(id, year: 26));
      add(portrait(id, year: 26));
      add(portrait(id, year: 25));
      add(portrait(id, year: 24));
      add(sofifa(id, year: 25));
    }
    return out;
  }

  /// Keep a usable catalog/CDN image; only fill gaps with Futbin CDN.
  static String resolve(String playerId, [String? existing]) {
    final current = (existing ?? '').trim();
    if (current.startsWith('http')) return current;
    return portrait(playerId);
  }
}
