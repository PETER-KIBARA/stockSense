import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/config/contact_config.dart';
import 'package:inventory_management_system/config/legal_content.dart';

void main() {
  test('legal pages are complete and name a contact address', () {
    for (final doc in [LegalContent.privacy, LegalContent.terms]) {
      expect(doc.sections, isNotEmpty);
      for (final section in doc.sections) {
        expect(section.heading, isNotEmpty);
        expect(section.body, isNotEmpty);
        expect(section.body.contains('TODO'), isFalse);
      }
    }
    expect(
        LegalContent.privacy.sections
            .any((s) => s.body.contains(ContactConfig.email)),
        isTrue);
  });
}
