import 'package:fcbaz/features/dns/data/dns_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DNS Feature Tests', () {
    const repository = DnsRepository();

    test('Loads 20 verified DNS servers', () {
      final all = repository.getAll();
      expect(all.length, 20);
    });

    test('Contains essential anti-sanction gaming DNS servers for Iran', () {
      final antiSanction = repository.filter(category: 'anti-sanction');
      expect(antiSanction.length, 5);

      final ids = antiSanction.map((s) => s.id).toSet();
      expect(ids.contains('electro'), isTrue);
      expect(ids.contains('radar'), isTrue);
      expect(ids.contains('shecan'), isTrue);
      expect(ids.contains('403'), isTrue);
      expect(ids.contains('begzar'), isTrue);

      final electro = antiSanction.firstWhere((s) => s.id == 'electro');
      expect(electro.primary, '78.157.42.101');
      expect(electro.secondary, '78.157.42.100');
    });

    test('Filters DNS by search query', () {
      final cloudflare = repository.filter(query: 'cloudflare');
      expect(cloudflare.isNotEmpty, isTrue);
      expect(cloudflare.any((s) => s.primary == '1.1.1.1'), isTrue);

      final electro = repository.filter(query: 'الکترو');
      expect(electro, isNotEmpty);
      expect(electro.first.id, 'electro');
    });
  });
}
