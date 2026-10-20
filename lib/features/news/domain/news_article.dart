class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.titleFa,
    required this.url,
    required this.published,
    required this.summary,
    required this.summaryFa,
    required this.tagFa,
    required this.intro,
    required this.keyPoints,
    required this.impact,
    required this.tips,
  });

  final String id;
  final String title;
  final String titleFa;
  final String url;
  final String published;
  final String summary;
  final String summaryFa;
  final String tagFa;
  final String intro;
  final List<String> keyPoints;
  final String impact;
  final String tips;

  String get displayTitle => titleFa.isNotEmpty ? titleFa : title;
  String get displaySummary => summaryFa.isNotEmpty ? summaryFa : summary;

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final fullContent = json['fullContentFA'] as Map<String, dynamic>? ?? {};

    List<String> asStrings(dynamic value) {
      if (value is! List) return const [];
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    final rawTitle = (json['title'] ?? '').toString();
    final rawUrl = (json['url'] ?? '').toString();
    final id = rawUrl.isNotEmpty
        ? rawUrl.split('/').last
        : rawTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

    return NewsArticle(
      id: id,
      title: rawTitle,
      titleFa: (json['titleFA'] ?? json['title_fa'] ?? '').toString(),
      url: rawUrl,
      published: (json['published'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      summaryFa: (json['summaryFA'] ?? json['summary_fa'] ?? '').toString(),
      tagFa: (json['tagFA'] ?? json['tag_fa'] ?? 'اخبار رسمی').toString(),
      intro: (fullContent['intro'] ?? '').toString(),
      keyPoints: asStrings(fullContent['keyPoints'] ?? fullContent['key_points']),
      impact: (fullContent['impact'] ?? '').toString(),
      tips: (fullContent['tips'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'titleFA': titleFa,
        'url': url,
        'published': published,
        'summary': summary,
        'summaryFA': summaryFa,
        'tagFA': tagFa,
        'fullContentFA': {
          'intro': intro,
          'keyPoints': keyPoints,
          'impact': impact,
          'tips': tips,
        },
      };
}
