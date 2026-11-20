import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/config/contact_config.dart';

void main() {
  test('support email and social links are set correctly', () {
    expect(ContactConfig.email, 'support@cloudora.africa');
    for (final url in [
      ContactConfig.instagram,
      ContactConfig.tiktok,
      ContactConfig.linkedin,
    ]) {
      final uri = Uri.parse(url);
      expect(uri.scheme, 'https');
      expect(uri.hasQuery, isFalse);
    }
  });
}
