import 'package:flutter/material.dart';

import '../domain/news_article.dart';
import 'package:fcbaz/src/app_dependencies.dart';
import 'package:fcbaz/src/theme/fcbaz_theme.dart';
import 'package:fcbaz/src/ui/section_heading.dart';
import 'package:fcbaz/src/ui/stadium_hero.dart';
import 'package:fcbaz/src/utils/persian_formatters.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({this.embedded = false, super.key});

  final bool embedded;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final repository = AppDependencies.instance.news;
  List<NewsArticle> allArticles = const [];
  bool loading = true;
  String? error;
  String selectedCategory = 'all';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch the current feed on first screen open; the repository retains its
    // bundled Persian snapshot if the network is unavailable.
    _loadNews(forceRefresh: true);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNews({bool forceRefresh = false}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final items = await repository.getArticles(forceRefresh: forceRefresh);
      if (!mounted) return;
      final tags = {for (final item in items) item.tagFa};
      setState(() {
        allArticles = items;
        if (selectedCategory != 'all' && !tags.contains(selectedCategory)) {
          selectedCategory = 'all';
        }
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _openDetails(NewsArticle article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewsDetailsSheet(article: article),
    );
  }

  List<(String, String)> _categories() {
    final seen = <String>{};
    final items = <(String, String)>[('all', 'همه')];
    for (final article in allArticles) {
      final tag = article.tagFa.trim();
      if (tag.isEmpty || !seen.add(tag)) continue;
      items.add((tag, tag));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = repository.filterArticles(
      allArticles,
      category: selectedCategory,
      query: searchQuery,
    );

    final content = RefreshIndicator(
      onRefresh: () => _loadNews(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          StadiumHero(
            eyebrow: 'FC 27 NEWSROOM',
            title: 'اخبار و رویدادهای FC 27',
            subtitle:
                'پچ‌نوت‌ها، ایونت‌های FUT، تغییرات گیم‌پلی و راهنماهای کاربردی؛ '
                'همه از اتاق خبر رسمی EA SPORTS FC 27.',
            metric: loading ? '—' : faDigits(filtered.length),
            metricLabel: 'گزارش در فید',
            metricNote: error == null
                ? 'همگام‌سازی زنده با منبع رسمی'
                : 'نسخه آفلاین ذخیره‌شده روی دستگاه',
            trailing: widget.embedded
                ? IconButton(
                    tooltip: 'بروزرسانی اخبار',
                    onPressed: () => _loadNews(forceRefresh: true),
                    icon: const Icon(Icons.refresh_rounded),
                  )
                : null,
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _NewsCategoryTabs(
            categories: _categories(),
            selectedCategory: selectedCategory,
            onSelected: (cat) => setState(() => selectedCategory = cat),
          ),
          const SizedBox(height: 14),
          SectionHeading(
            title: 'آخرین اطلاعیه‌ها',
            eyebrow: 'LATEST BRIEFINGS',
            trailing: Text(
              '${faDigits(filtered.length)} گزارش',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
          if (loading)
            const _NewsSkeleton()
          else if (error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off_rounded),
                title: const Text('اخبار در دسترس نیست'),
                subtitle: Text(error!),
                trailing: IconButton(
                  tooltip: 'تلاش دوباره',
                  onPressed: () => _loadNews(forceRefresh: true),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
            )
          else if (filtered.isEmpty)
            _EmptyNews(
              onReset: () {
                searchController.clear();
                setState(() {
                  searchQuery = '';
                  selectedCategory = 'all';
                });
              },
              onRetry: () => _loadNews(forceRefresh: true),
            )
          else ...[
            _FeaturedNewsCard(
              article: filtered.first,
              onTap: () => _openDetails(filtered.first),
            ),
            const SizedBox(height: 12),
            for (final article in filtered.skip(1)) ...[
              _NewsCard(article: article, onTap: () => _openDetails(article)),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اخبار و رویدادهای FC 27'),
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _loadNews(forceRefresh: true),
          ),
        ],
      ),
      body: content,
    );
  }
}

class _NewsCategoryTabs extends StatelessWidget {
  const _NewsCategoryTabs({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<(String, String)> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
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
        side: BorderSide(color: scheme.outlineVariant),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article.tagFa,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatNewsDateFa(article.published),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              if (article.titleFa.isNotEmpty &&
                  article.title != article.titleFa) ...[
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
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 14,
                    color: scheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedNewsCard extends StatelessWidget {
  const _FeaturedNewsCard({required this.article, required this.onTap});

  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'گزارش ویژه: ${article.displayTitle}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.primary.withValues(alpha: .35)),
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              Color.alphaBlend(
                scheme.primary.withValues(alpha: .18),
                scheme.surface,
              ),
              scheme.surface,
              Color.alphaBlend(
                scheme.secondary.withValues(alpha: .09),
                scheme.surface,
              ),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              PositionedDirectional(
                end: 10,
                bottom: -14,
                child: IgnorePointer(
                  child: Text(
                    'NEWS',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w800,
                      fontSize: 64,
                      height: .8,
                      color: scheme.primary.withValues(alpha: .07),
                    ),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: 13,
                                    color: scheme.onPrimary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'گزارش ویژه',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                article.tagFa.isEmpty
                                    ? formatNewsDateFa(article.published)
                                    : '${article.tagFa} • ${formatNewsDateFa(article.published)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          article.displayTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          article.displaySummary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'مطالعه گزارش ویژه',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_back_rounded,
                              size: 16,
                              color: scheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsSkeleton extends StatelessWidget {
  const _NewsSkeleton();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget bar(double width, double height, {double radius = 4}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Semantics(
      label: 'در حال بارگذاری اخبار',
      child: Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [bar(62, 16, radius: 6), bar(44, 10)],
                  ),
                  const SizedBox(height: 12),
                  bar(double.infinity, 12),
                  const SizedBox(height: 8),
                  bar(210, 12),
                  const SizedBox(height: 12),
                  bar(double.infinity, 9),
                  const SizedBox(height: 6),
                  bar(double.infinity, 9),
                  const SizedBox(height: 6),
                  bar(136, 9),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
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
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: .18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              article.tagFa,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatNewsDateFa(article.published),
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
                    if (article.titleFa.isNotEmpty &&
                        article.title != article.titleFa) ...[
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
                          border: Border.all(color: scheme.outlineVariant),
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
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final point in article.keyPoints) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  point,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.5,
                                  ),
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
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: .2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.insights_rounded,
                              size: 18,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'تأثیر بر بازی و بازار:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    article.impact,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
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
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: .25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 18,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'توصیه کارشناسی برای تیم شما:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    article.tips,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
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
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
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
  const _EmptyNews({required this.onReset, required this.onRetry});
  final VoidCallback onReset;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text(
            'مطلبی در این دسته‌بندی یافت نشد',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text('فیلتر یا عبارت جستجو را تغییر دهید.'),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onReset,
            child: const Text('مشاهده همه اخبار'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onRetry,
            child: const Text('همگام‌سازی دوباره'),
          ),
        ],
      ),
    );
  }
}
