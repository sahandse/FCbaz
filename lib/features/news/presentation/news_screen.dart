import 'package:flutter/material.dart';

import '../data/news_repository.dart';
import '../domain/news_article.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final repository = NewsRepository();
  List<NewsArticle> allArticles = const [];
  bool loading = true;
  String selectedCategory = 'all';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() => loading = true);
    final items = await repository.getArticles();
    if (!mounted) return;
    setState(() {
      allArticles = items;
      loading = false;
    });
  }

  void _openDetails(NewsArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewsDetailsSheet(article: article),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = repository.filterArticles(
      allArticles,
      category: selectedCategory,
      query: searchQuery,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('اخبار و رویدادهای FC 27'),
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadNews(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNews(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A100B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.primary.withValues(alpha: .22)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.newspaper_rounded, color: Color(0xFFCAFF38), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'پایگاه رسمی اخبار EA SPORTS FC 27',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'پچ‌نوت‌ها، ایونت‌های FUT، تغییرات گیم‌پلی و راهنماهای کاربردی.',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'جستجو در اخبار، پچ‌نوت‌ها و رویدادها...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: scheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _NewsCategoryTabs(
              selectedCategory: selectedCategory,
              onSelected: (cat) => setState(() => selectedCategory = cat),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'آخرین اطلاعیه‌ها',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${filtered.length} گزارش',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              _EmptyNews(onReset: () {
                searchController.clear();
                setState(() {
                  searchQuery = '';
                  selectedCategory = 'all';
                });
              })
            else
              for (final article in filtered) ...[
                _NewsCard(article: article, onTap: () => _openDetails(article)),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _NewsCategoryTabs extends StatelessWidget {
  const _NewsCategoryTabs({
    required this.selectedCategory,
    required this.onSelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = const [
      ('all', 'همه'),
      ('🎮 گیم‌پلی و توسعه', '🎮 گیم‌پلی'),
      ('🌟 رویداد FUT', '🌟 رویداد FUT'),
      ('⚙️ پچ و آپدیت', '⚙️ پچ و آپدیت'),
      ('🏆 مسابقات و جوایز', '🏆 مسابقات'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat.$1;
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: FilterChip(
              selected: isSelected,
              label: Text(cat.$2),
              onSelected: (_) => onSelected(cat.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article, required this.onTap});
  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article.tagFa,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFCAFF38),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    article.published,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                article.displayTitle,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.4),
              ),
              if (article.titleFa.isNotEmpty && article.title != article.titleFa) ...[
                const SizedBox(height: 3),
                Text(
                  article.title,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant.withValues(alpha: .8),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                article.displaySummary,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'مطالعه کامل و نکات',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_back_rounded, size: 14, color: scheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsDetailsSheet extends StatelessWidget {
  const _NewsDetailsSheet({required this.article});
  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article.tagFa,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFCAFF38),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          article.published,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      article.displayTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.4,
                      ),
                    ),
                    if (article.titleFa.isNotEmpty && article.title != article.titleFa) ...[
                      const SizedBox(height: 4),
                      Text(
                        article.title,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const Divider(height: 24),
                    if (article.intro.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          article.intro,
                          style: const TextStyle(fontSize: 13, height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (article.keyPoints.isNotEmpty) ...[
                      Text(
                        'نکات کلیدی و تغییرات مهم',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFCAFF38),
                            ),
                      ),
                      const SizedBox(height: 8),
                      for (final point in article.keyPoints) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFFCAFF38)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  point,
                                  style: const TextStyle(fontSize: 12.5, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                    if (article.impact.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withValues(alpha: .2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.insights_rounded, size: 18, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('تأثیر بر بازی و بازار:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(article.impact, style: const TextStyle(fontSize: 12, height: 1.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (article.tips.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: .25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline_rounded, size: 18, color: Colors.amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('توصیه کارشناسی برای تیم شما:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(article.tips, style: const TextStyle(fontSize: 12, height: 1.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (article.url.isNotEmpty)
                      Center(
                        child: Text(
                          'منبع رسمی: Electronic Arts FC 27',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyNews extends StatelessWidget {
  const _EmptyNews({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.article_outlined, size: 48, color: Colors.white38),
          const SizedBox(height: 12),
          const Text('مطلبی در این دسته‌بندی یافت نشد', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('فیلتر یا عبارت جستجو را تغییر دهید.'),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onReset,
            child: const Text('مشاهده همه اخبار'),
          ),
        ],
      ),
    );
  }
}
