import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/news_article.dart';

class NewsRepository {
  NewsRepository();

  List<NewsArticle>? _cachedArticles;

  static const _liveNewsUrl =
      'https://sahandse.github.io/FC27/data/fc27-news.json';

  static const Map<String, ({String title, String summary, String tag})>
  _translations = {
    'fc-27-season-2-fc-heritage': (
      title: 'فصل دوم آلتیمیت تیم: میراث FC',
      summary:
          'فصل دوم با حال‌وهوای نوستالژیک FUT و بازگشت رویدادها و آیتم‌های محبوب گذشته همراه است.',
      tag: '🏆 رویداد FUT',
    ),
    'fc-27-ultimate-scream': (
      title: 'رویداد Ultimate Scream در آلتیمیت تیم FC 27',
      summary:
          'جزئیات رویداد Ultimate Scream و محتوای ویژه آن در آلتیمیت تیم را دنبال کنید.',
      tag: '🎃 رویداد FUT',
    ),
    'fc-27-the-grounds-developer-archetypes-update': (
      title: 'به‌روزرسانی آرکه‌تایپ‌های The Grounds',
      summary:
          'آخرین تغییرات Archetype و امتیازهای Attribute Points در The Grounds و Clubs.',
      tag: '🏟️ The Grounds و Clubs',
    ),
    'fc-27-launch-feedback-update': (
      title: 'گزارش بازخوردهای اولیه FC 27',
      summary:
          'مروری بر بازخوردهای بازیکنان و تغییرات گیم‌پلی، آلتیمیت تیم، کریر مود و Clubs.',
      tag: '🎮 گیم‌پلی و توسعه',
    ),
    'fc-27-future-stars': (
      title: 'ستارگان آینده در آلتیمیت تیم FC 27',
      summary:
          'معرفی استعدادهای جوان و محتوای Future Stars Academy در آلتیمیت تیم.',
      tag: '🌟 رویداد FUT',
    ),
    'fc27-title-update-v1-0-4': (
      title: 'یادداشت‌های به‌روزرسانی نسخه ۱.۰.۴',
      summary:
          'مرور تغییرات و اصلاحات اعلام‌شده در به‌روزرسانی رسمی شماره ۱.۰.۴.',
      tag: '🛠️ به‌روزرسانی بازی',
    ),
    'fc-27-the-grounds-developer-launch-update': (
      title: 'گزارش آغاز به کار The Grounds و Clubs',
      summary:
          'بازخوردهای اولیه و برنامه‌های بهبود The Grounds و Clubs از زبان تیم سازنده.',
      tag: '🏟️ The Grounds و Clubs',
    ),
    'title-update-v1-0-3': (
      title: 'یادداشت‌های به‌روزرسانی نسخه ۱.۰.۳',
      summary:
          'مرور اصلاحات و تغییرات اعلام‌شده در به‌روزرسانی رسمی شماره ۱.۰.۳.',
      tag: '🛠️ به‌روزرسانی بازی',
    ),
    'fc-27-fut-developer-launch-update': (
      title: 'گزارش تیم سازنده آلتیمیت تیم',
      summary: 'بازخوردهای بازیکنان و تغییرات مورد بررسی پس از عرضه بازی.',
      tag: '🏆 آلتیمیت تیم',
    ),
    'fc-27-gameplay-developer-launch-update': (
      title: 'گزارش تیم سازنده درباره گیم‌پلی',
      summary:
          'مرور بازخوردهای اولیه درباره گیم‌پلی و زمینه‌های مورد بررسی تیم سازنده.',
      tag: '🎮 گیم‌پلی و توسعه',
    ),
    'fc-27-career-mode-developer-launch-update': (
      title: 'گزارش تیم سازنده درباره کریر مود',
      summary: 'بازخوردهای اولیه و زمینه‌های بهبود حالت کریر مود بازی.',
      tag: '👔 کریر مود',
    ),
    'fc-27-destined-for-glory': (
      title: 'رویداد Destined for Glory در آلتیمیت تیم',
      summary:
          'بازیکنان منتخب جامعه FC که قرار است در فصل جاری آلتیمیت تیم بدرخشند.',
      tag: '🌟 رویداد FUT',
    ),
  };

  Future<List<NewsArticle>> getArticles({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedArticles != null &&
        _cachedArticles!.isNotEmpty) {
      return _cachedArticles!;
    }

    if (forceRefresh) {
      try {
        final live = await _fetchLiveArticles();
        if (live.isNotEmpty) {
          _cachedArticles = live;
          return live;
        }
      } catch (_) {
        // Keep the bundled snapshot available when the network is unavailable.
      }
    }

    try {
      final jsonStr = await rootBundle.loadString('assets/data/fc27-news.json');
      final data = jsonDecode(jsonStr);
      final rawItems = data is Map
          ? (data['items'] as List? ?? [])
          : (data as List);
      final list = rawItems
          .whereType<Map>()
          .map(
            (m) =>
                NewsArticle.fromJson(_translate(Map<String, dynamic>.from(m))),
          )
          .toList();
      if (list.isNotEmpty) {
        _cachedArticles = list;
        return list;
      }
    } catch (_) {
      // Fallback below
    }

    _cachedArticles = _fallbackArticles;
    return _cachedArticles!;
  }

  Future<List<NewsArticle>> _fetchLiveArticles() async {
    final client = HttpClient();
    try {
      final request = await client
          .getUrl(Uri.parse(_liveNewsUrl))
          .timeout(const Duration(seconds: 8));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('FC27 news HTTP ${response.statusCode}');
      }
      final body = await utf8.decoder.bind(response).join();
      final data = jsonDecode(body);
      final rawItems = data is Map
          ? (data['items'] as List? ?? [])
          : (data as List);
      return rawItems
          .whereType<Map>()
          .map(
            (item) => NewsArticle.fromJson(
              _translate(Map<String, dynamic>.from(item)),
            ),
          )
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  Map<String, dynamic> _translate(Map<String, dynamic> json) {
    final id = (json['url'] ?? '').toString().split('/').last;
    final translated = _translations[id];
    if (translated == null) return json;
    return {
      ...json,
      'titleFA': json['titleFA'] ?? translated.title,
      'summaryFA': json['summaryFA'] ?? translated.summary,
      'tagFA': json['tagFA'] ?? translated.tag,
    };
  }

  List<NewsArticle> filterArticles(
    List<NewsArticle> items, {
    String category = 'all',
    String query = '',
  }) {
    final q = query.trim().toLowerCase();
    return items.where((article) {
      if (category != 'all' && article.tagFa != category) {
        return false;
      }
      if (q.isEmpty) return true;
      return article.displayTitle.toLowerCase().contains(q) ||
          article.displaySummary.toLowerCase().contains(q) ||
          article.tagFa.toLowerCase().contains(q) ||
          article.intro.toLowerCase().contains(q);
    }).toList();
  }

  static final List<NewsArticle> _fallbackArticles = [
    NewsArticle(
      id: 'fc-27-launch-feedback-update',
      title: 'EA SPORTS FC™ 27 | Launch Feedback Update',
      titleFa: 'به‌روزرسانی بازخوردهای زمان عرضهٔ بازی EA SPORTS FC 27',
      url:
          'https://www.ea.com/games/ea-sports-fc/fc-27/news/fc-27-launch-feedback-update',
      published: 'October 13, 2026',
      summary:
          'Explore EA SPORTS FC™ 27 launch feedback and developer updates on gameplay, FUT, Career Mode, The Grounds & Clubs.',
      summaryFa:
          'بررسی بازخوردهای جامعه بازیکنان در زمان عرضه بازی و گزارش به‌روزرسانی‌های تیم سازنده پیرامون گیم‌پلی، آلتیمیت تیم (FUT)، کریر مود و بخش Clubs.',
      tagFa: '🎮 گیم‌پلی و توسعه',
      intro:
          'تیم توسعه‌دهنده EA SPORTS FC 27 نخستین گزارش جامع خود را پس از بررسی گستردهٔ بازخوردهای میلیونی بازیکنان در روزهای افتتاحیه عرضه بین‌المللی بازی منتشر کرد.',
      keyPoints: const [
        'گیم‌پلی و هوش مصنوعی: سرعت و واکنش مدافعان در مواجهه با فرارهای سرعتی مجدداً تنظیم شد تا بازی متعادل‌تر شود.',
        'آلتیمیت تیم (FUT): پاداش‌های رقابت‌های Division Rivals و مسابقات Champions بازنگری شد و نرخ دریافت کارت‌های طلایی ارتقا یافت.',
        'The Grounds و Clubs: پایداری لابی‌های آنلاین چندنفره و جلوگیری از قطع ارتباط در مسابقات تیمی بهبود چشمگیری یافت.',
      ],
      impact:
          'این تغییرات به طور مستقیم باعث روان‌تر شدن مسابقات آنلاین در پلی‌استیشن ۵ و کنسول‌ها شده و زمان مچ‌میکینگ را به زیر ۱۰ ثانیه کاهش می‌دهد.',
      tips:
          'پیشنهاد می‌شود پس از دریافت این به‌روزرسانی، تاکتیک‌های عرضی تیم خود را با عمق دفاعی جدید هماهنگ کنید.',
    ),
    NewsArticle(
      id: 'fc-27-future-stars',
      title: 'Football Ultimate Team™ 27 - Future Stars',
      titleFa:
          'رویداد ستارگان آینده (Future Stars) در Football Ultimate Team 27',
      url:
          'https://www.ea.com/games/ea-sports-fc/fc-27/news/fc-27-future-stars',
      published: 'October 9, 2026',
      summary:
          'See the most exciting Future Stars take over Football Ultimate Team™ and develop your own young talent in the Future Stars Academy.',
      summaryFa:
          'حضور هیجان‌انگیزترین استعدادهای جوان دنیای فوتبال در آلتیمیت تیم؛ معرفی آکادمی ستارگان آینده جهت پرورش ستاره‌های نوظهور ترکیب شما.',
      tagFa: '🌟 رویداد FUT',
      intro:
          'کمپین بزرگ «ستارگان آینده» (Future Stars) رسماً در Football Ultimate Team 27 آغاز شد. این رویداد مختص نخبگان زیر ۲۳ سال فوتبال جهان است.',
      keyPoints: const [
        'معرفی تیم اول و دوم ستارگان آینده: پدیده‌های جوان با بوست‌های عظیم در سرعت، دریبلینگ و پلی‌استایل‌های پلاس (+).',
        'آکادمی ستارگان آینده (Evolutions Academy): قابلیت انتخاب یک استعداد جوان و ارتقای پلکانی کارت او تا ریتینگ ۹۰+.',
        'چالش‌های ساخت ترکیب (SBC) ویژه: عرضه چالش‌های اختصاصی با پاداش کارت‌های Future Stars.',
      ],
      impact:
          'اضافه شدن این کارت‌ها گزینه‌های سرعتی و با تکنیک بالا را با قیمت‌های بسیار مناسب در دسترس همه بازیکنان قرار می‌دهد.',
      tips:
          'قبل از تصمیم‌گیری برای ارتقای کارت آکادمی، مسیرهای تکامل و پلی‌استایل‌های نهایی هر بازیکن را با سیستم شیمی تیم خود مطابقت دهید.',
    ),
    NewsArticle(
      id: 'fc27-title-update-v1-0-4',
      title: 'EA SPORTS FC™ 27 | Title Update v1.0.4',
      titleFa: 'پچ‌نوت و آپدیت رسمی شماره ۱.۰.۴ بازی FC 27',
      url:
          'https://www.ea.com/games/ea-sports-fc/fc-27/news/fc27-title-update-v1-0-4',
      published: 'October 7, 2026',
      summary:
          'Find out the latest EA SPORTS FC™ 27 Update details in the Title Update v.1.0.4 Notes.',
      summaryFa:
          'جزئیات کامل تغییرات و رفع باگ‌های EA SPORTS FC 27 در یادداشت‌های رسمی نسخه ۱.۰.۴؛ بهبود پاسخ‌دهی کنترل‌ها و اصلاح فیزیک توپ.',
      tagFa: '⚙️ پچ و آپدیت',
      intro:
          'به‌روزرسانی جامع نسخه ۱.۰.۴ برای تمام پلتفرم‌ها منتشر شد. این پچ تمرکز ویژه‌ای بر بهبود کنترل‌های دستی و رفع باگ‌های گزارش‌شده دارد.',
      keyPoints: const [
        'رفع مشکل تأخیر در پاس‌های تک‌ضرب در صورت شلوغی محوطه جریمه.',
        'اصلاح نحوه سوئیچ خودکار مدافعین روی توپ‌های هوایی.',
        'بهبود پایداری سرورها در مسابقات آنلاین FUT Champions.',
      ],
      impact:
          'تجربه بازی به مراتب روان‌تر و واکنش دکمه‌ها در دریبلینگ سریع‌تر شده است.',
      tips:
          'تنظیمات سوئیچینگ راست آنالوگ را در بخش Controller Settings مجدداً بررسی فرمایید.',
    ),
  ];
}
