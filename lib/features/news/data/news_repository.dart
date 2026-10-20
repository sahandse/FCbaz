import 'dart:convert';
import 'package:flutter/services.dart';

import '../domain/news_article.dart';

class NewsRepository {
  NewsRepository();

  List<NewsArticle>? _cachedArticles;

  Future<List<NewsArticle>> getArticles({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedArticles != null && _cachedArticles!.isNotEmpty) {
      return _cachedArticles!;
    }

    try {
      final jsonStr = await rootBundle.loadString('assets/data/fc27-news.json');
      final data = jsonDecode(jsonStr);
      final rawItems = data is Map ? (data['items'] as List? ?? []) : (data as List);
      final list = rawItems
          .whereType<Map>()
          .map((m) => NewsArticle.fromJson(Map<String, dynamic>.from(m)))
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
      url: 'https://www.ea.com/games/ea-sports-fc/fc-27/news/fc-27-launch-feedback-update',
      published: 'October 13, 2026',
      summary: 'Explore EA SPORTS FC™ 27 launch feedback and developer updates on gameplay, FUT, Career Mode, The Grounds & Clubs.',
      summaryFa: 'بررسی بازخوردهای جامعه بازیکنان در زمان عرضه بازی و گزارش به‌روزرسانی‌های تیم سازنده پیرامون گیم‌پلی، آلتیمیت تیم (FUT)، کریر مود و بخش Clubs.',
      tagFa: '🎮 گیم‌پلی و توسعه',
      intro: 'تیم توسعه‌دهنده EA SPORTS FC 27 نخستین گزارش جامع خود را پس از بررسی گستردهٔ بازخوردهای میلیونی بازیکنان در روزهای افتتاحیه عرضه بین‌المللی بازی منتشر کرد.',
      keyPoints: const [
        'گیم‌پلی و هوش مصنوعی: سرعت و واکنش مدافعان در مواجهه با فرارهای سرعتی مجدداً تنظیم شد تا بازی متعادل‌تر شود.',
        'آلتیمیت تیم (FUT): پاداش‌های رقابت‌های Division Rivals و مسابقات Champions بازنگری شد و نرخ دریافت کارت‌های طلایی ارتقا یافت.',
        'The Grounds و Clubs: پایداری لابی‌های آنلاین چندنفره و جلوگیری از قطع ارتباط در مسابقات تیمی بهبود چشمگیری یافت.',
      ],
      impact: 'این تغییرات به طور مستقیم باعث روان‌تر شدن مسابقات آنلاین در پلی‌استیشن ۵ و کنسول‌ها شده و زمان مچ‌میکینگ را به زیر ۱۰ ثانیه کاهش می‌دهد.',
      tips: 'پیشنهاد می‌شود پس از دریافت این به‌روزرسانی، تاکتیک‌های عرضی تیم خود را با عمق دفاعی جدید هماهنگ کنید.',
    ),
    NewsArticle(
      id: 'fc-27-future-stars',
      title: 'Football Ultimate Team™ 27 - Future Stars',
      titleFa: 'رویداد ستارگان آینده (Future Stars) در Football Ultimate Team 27',
      url: 'https://www.ea.com/games/ea-sports-fc/fc-27/news/fc-27-future-stars',
      published: 'October 9, 2026',
      summary: 'See the most exciting Future Stars take over Football Ultimate Team™ and develop your own young talent in the Future Stars Academy.',
      summaryFa: 'حضور هیجان‌انگیزترین استعدادهای جوان دنیای فوتبال در آلتیمیت تیم؛ معرفی آکادمی ستارگان آینده جهت پرورش ستاره‌های نوظهور ترکیب شما.',
      tagFa: '🌟 رویداد FUT',
      intro: 'کمپین بزرگ «ستارگان آینده» (Future Stars) رسماً در Football Ultimate Team 27 آغاز شد. این رویداد مختص نخبگان زیر ۲۳ سال فوتبال جهان است.',
      keyPoints: const [
        'معرفی تیم اول و دوم ستارگان آینده: پدیده‌های جوان با بوست‌های عظیم در سرعت، دریبلینگ و پلی‌استایل‌های پلاس (+).',
        'آکادمی ستارگان آینده (Evolutions Academy): قابلیت انتخاب یک استعداد جوان و ارتقای پلکانی کارت او تا ریتینگ ۹۰+.',
        'چالش‌های ساخت ترکیب (SBC) ویژه: عرضه چالش‌های اختصاصی با پاداش کارت‌های Future Stars.',
      ],
      impact: 'اضافه شدن این کارت‌ها گزینه‌های سرعتی و با تکنیک بالا را با قیمت‌های بسیار مناسب در دسترس همه بازیکنان قرار می‌دهد.',
      tips: 'قبل از تصمیم‌گیری برای ارتقای کارت آکادمی، مسیرهای تکامل و پلی‌استایل‌های نهایی هر بازیکن را با سیستم شیمی تیم خود مطابقت دهید.',
    ),
    NewsArticle(
      id: 'fc27-title-update-v1-0-4',
      title: 'EA SPORTS FC™ 27 | Title Update v1.0.4',
      titleFa: 'پچ‌نوت و آپدیت رسمی شماره ۱.۰.۴ بازی FC 27',
      url: 'https://www.ea.com/games/ea-sports-fc/fc-27/news/fc27-title-update-v1-0-4',
      published: 'October 7, 2026',
      summary: 'Find out the latest EA SPORTS FC™ 27 Update details in the Title Update v.1.0.4 Notes.',
      summaryFa: 'جزئیات کامل تغییرات و رفع باگ‌های EA SPORTS FC 27 در یادداشت‌های رسمی نسخه ۱.۰.۴؛ بهبود پاسخ‌دهی کنترل‌ها و اصلاح فیزیک توپ.',
      tagFa: '⚙️ پچ و آپدیت',
      intro: 'به‌روزرسانی جامع نسخه ۱.۰.۴ برای تمام پلتفرم‌ها منتشر شد. این پچ تمرکز ویژه‌ای بر بهبود کنترل‌های دستی و رفع باگ‌های گزارش‌شده دارد.',
      keyPoints: const [
        'رفع مشکل تأخیر در پاس‌های تک‌ضرب در صورت شلوغی محوطه جریمه.',
        'اصلاح نحوه سوئیچ خودکار مدافعین روی توپ‌های هوایی.',
        'بهبود پایداری سرورها در مسابقات آنلاین FUT Champions.',
      ],
      impact: 'تجربه بازی به مراتب روان‌تر و واکنش دکمه‌ها در دریبلینگ سریع‌تر شده است.',
      tips: 'تنظیمات سوئیچینگ راست آنالوگ را در بخش Controller Settings مجدداً بررسی فرمایید.',
    ),
  ];
}
