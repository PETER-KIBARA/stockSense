import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/config/plans_config.dart';

void main() {
  test('plans use the names the landing page and consultation form expect', () {
    expect(PlansConfig.plans.map((p) => p.name).toList(),
        ['Entry', 'Mid', 'High']);
  });

  test('prices are in KES with thousands separators', () {
    for (final plan in PlansConfig.plans) {
      expect(plan.priceKes, matches(RegExp(r'^KES \d{1,3}(,\d{3})*$')));
    }
  });

  test('exactly one plan is highlighted and every plan lists features', () {
    expect(PlansConfig.plans.where((p) => p.recommended).length, 1);
    for (final plan in PlansConfig.plans) {
      expect(plan.features, isNotEmpty);
    }
  });
}
