import 'package:fcbaz/features/evolutions/domain/evolution.dart';
import 'package:fcbaz/features/home/home_repository.dart';
import 'package:fcbaz/features/sbc/domain/sbc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FC27 Persian Enrichment Tests', () {
    test('HomeObjective parses camelCase and snake_case Persian fields', () {
      final json = {
        'id': 'obj-1',
        'name': 'Squad Battles: Champions Qualification Points',
        'nameFA': 'Squad Battles: امتیازهای راهیابی به Champions',
        'description': 'Compete in Squad Battles to earn Champions Qualification Points!',
        'descriptionFA': 'در Squad Battles به رقابت بپردازید و امتیازهای راهیابی به Champions را کسب کنید.',
        'reward': 'Packs',
        'rewardFA': 'پک‌های طلایی',
        'tasks': [
          {
            'name': 'Win 15',
            'nameFA': '۱۵ برد',
            'description': 'Win 15 matches in Squad Battles on min. World Class difficulty.',
            'descriptionFA': '۱۵ مسابقه را ببرید، در Squad Battles، روی سختی کلاس جهانی.',
            'reward': '100 Points',
            'rewardFA': '۱۰۰ امتیاز',
            'target': 15,
          }
        ]
      };

      final obj = HomeObjective.fromJson(json);
      expect(obj.title, 'Squad Battles: امتیازهای راهیابی به Champions');
      expect(obj.description, contains('امتیازهای راهیابی'));
      expect(obj.reward, 'پک‌های طلایی');
      expect(obj.tasks.length, 1);
      expect(obj.tasks.first.title, '۱۵ برد');
      expect(obj.tasks.first.description, contains('کلاس جهانی'));
      expect(obj.tasks.first.reward, '۱۰۰ امتیاز');
    });

    test('SbcChallenge parses Persian titles, descriptions, and requirements', () {
      final json = {
        'id': 'sbc-potm-vinicius',
        'name': 'Vinícius Jr. POTM',
        'nameFA': 'وینیسیوس جونیور - بازیکن ماه لالیگا',
        'description': 'Complete this challenge to earn LaLiga POTM Vinícius Jr.',
        'descriptionFA': 'این چالش را برای دریافت کارت بازیکن ماه لالیگا وینیسیوس جونیور تکمیل کنید.',
        'reward': 'POTM Vinicius Jr',
        'rewardFA': 'کارت بازیکن ماه وینیسیوس جونیور',
        'requirementsFA': [
          'حداقل ۱ بازیکن از رئال مادرید',
          'حداقل ریتینگ کلی تیم: ۸۸',
          'حداقل شیمی تیمی: ۲۵'
        ],
      };

      final sbc = SbcChallenge.fromJson(json);
      expect(sbc.titleFa, 'وینیسیوس جونیور - بازیکن ماه لالیگا');
      expect(sbc.primaryTitle, 'وینیسیوس جونیور - بازیکن ماه لالیگا');
      expect(sbc.description, contains('وینیسیوس جونیور'));
      expect(sbc.reward, contains('وینیسیوس'));
      expect(sbc.requirements.length, 3);
      expect(sbc.requirements.first, contains('رئال مادرید'));
    });

    test('Evolution parses levels, tasksFA, and upgradesFA from FC27', () {
      final json = {
        'id': 'evo-zoomaestro',
        'name': 'Zoomaestro',
        'nameFA': 'زوماسترو',
        'description': 'Boost pace and dribbling on your CAM or CM.',
        'descriptionFA': 'سرعت و دریبل هافبک هجومی یا مرکزی خود را تقویت کنید.',
        'levels': [
          {
            'name': 'Level 1',
            'nameFA': 'سطح ۱',
            'tasksFA': [
              '۲ مسابقه را بازی کنید، در Squad Battles، روی سختی نیمه‌حرفه‌ای، با بازیکن فعال تکامل.'
            ],
            'upgradesFA': [
              '+۷ امتیاز کلی (به ۸۳)',
              '+۱۰ دریبل (به ۸۳)'
            ]
          }
        ]
      };

      final evo = Evolution.fromJson(json);
      expect(evo.title, 'زوماسترو');
      expect(evo.description, contains('هافبک'));
      expect(evo.steps.length, 1);
      expect(evo.steps.first.title, 'سطح ۱');
      expect(evo.steps.first.requirements.first, contains('Squad Battles'));
      expect(evo.steps.first.upgrades.first, contains('امتیاز کلی'));
    });
  });
}
