import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/config/currency_config.dart';

void main() {
  test('formats Kenyan shillings with separators and no needless decimals', () {
    expect(AppCurrency.format(0), 'KES 0');
    expect(AppCurrency.format(185), 'KES 185');
    expect(AppCurrency.format(1450), 'KES 1,450');
    expect(AppCurrency.format(1450.5), 'KES 1,450.50');
    expect(AppCurrency.format(1234567), 'KES 1,234,567');
  });
}
