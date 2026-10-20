import 'package:fcbaz/features/news/data/news_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('News Feature Tests', () {
    final repository = NewsRepository();

    test('Loads articles and provides fallback if asset unbundled', () async {
      final articles = await repository.getArticles();
      expect(articles.isNotEmpty, isTrue);

      final launchUpdate = articles.firstWhere((a) => a.id.contains('launch-feedback'));
      expect(launchUpdate.titleFa, contains('بازخوردهای'));
      expect(launchUpdate.keyPoints.isNotEmpty, isTrue);
    });

    test('Filters news by category and query', () async {
      final articles = await repository.getArticles();
      final filtered = repository.filterArticles(articles, query: 'Future Stars');
      expect(filtered.isNotEmpty, isTrue);
      expect(filtered.first.title, contains('Future Stars'));
    });
  });
}
