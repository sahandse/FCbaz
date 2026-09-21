import '../../core/network/fcbaz_api.dart';

class AppReleaseInfo {
  const AppReleaseInfo({
    required this.tagName,
    required this.name,
    required this.htmlUrl,
    required this.publishedAt,
    required this.prerelease,
    required this.draft,
  });

  final String tagName;
  final String name;
  final String htmlUrl;
  final DateTime? publishedAt;
  final bool prerelease;
  final bool draft;

  String get normalizedVersion =>
      tagName.toLowerCase().startsWith('v') ? tagName.substring(1) : tagName;

  factory AppReleaseInfo.fromJson(Map<String, dynamic> json) => AppReleaseInfo(
        tagName: (json['tag_name'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        htmlUrl: (json['html_url'] ?? '').toString(),
        publishedAt: DateTime.tryParse((json['published_at'] ?? '').toString()),
        prerelease: json['prerelease'] == true,
        draft: json['draft'] == true,
      );
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.release,
    required this.updateAvailable,
  });

  final String currentVersion;
  final AppReleaseInfo? release;
  final bool updateAvailable;
}

class UpdateRepository {
  UpdateRepository({FCBazApi? api}) : api = api ?? FCBazApi();
  final FCBazApi api;

  static const currentVersion =
      String.fromEnvironment('FCBAZ_APP_VERSION', defaultValue: '1.0.5');

  Future<UpdateCheckResult> check() async {
    final json = await api.getJson('/api/v1/app/latest-release');
    final raw = json is Map ? json['data'] : null;

    if (raw is! Map) {
      return const UpdateCheckResult(
        currentVersion: currentVersion,
        release: null,
        updateAvailable: false,
      );
    }

    final release = AppReleaseInfo.fromJson(Map<String, dynamic>.from(raw));
    final available = !release.draft &&
        !release.prerelease &&
        _compareVersions(release.normalizedVersion, currentVersion) > 0;

    return UpdateCheckResult(
      currentVersion: currentVersion,
      release: release,
      updateAvailable: available,
    );
  }

  int _compareVersions(String a, String b) {
    List<int> parse(String value) => value
        .split('+')
        .first
        .split('-')
        .first
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    final av = parse(a);
    final bv = parse(b);
    final length = av.length > bv.length ? av.length : bv.length;

    for (var i = 0; i < length; i++) {
      final ai = i < av.length ? av[i] : 0;
      final bi = i < bv.length ? bv[i] : 0;
      if (ai != bi) return ai.compareTo(bi);
    }

    return 0;
  }
}
