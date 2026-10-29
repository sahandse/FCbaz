import 'package:fcbaz/core/network/public_fc_data_v2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('player loading returns the whole live catalog, not one page', () async {
    SharedPreferences.setMockInitialValues({});

    final data = PublicFcData();
    final all = await data.getPlayers();

    expect(all.length, greaterThan(10000));

    final secondPage = await data.getPlayers(page: 2);
    expect(secondPage, hasLength(100));
    expect(secondPage.first.id, all[100].id);
  });
}
