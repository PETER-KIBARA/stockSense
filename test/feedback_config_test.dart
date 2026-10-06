import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/config/feedback_config.dart';

void main() {
  test('feedback link is a secure Google Forms link without account IDs', () {
    final uri = Uri.parse(FeedbackConfig.formUrl);
    expect(uri.scheme, 'https');
    expect(uri.host, 'docs.google.com');
    expect(uri.path, startsWith('/forms/d/e/'));
    expect(uri.path, endsWith('/viewform'));
    expect(FeedbackConfig.formUrl.contains('ouid'), isFalse);
  });
}
