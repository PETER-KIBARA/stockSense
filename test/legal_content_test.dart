import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_management_system/config/contact_config.dart';
import 'package:inventory_management_system/config/legal_content.dart';

String _allText(LegalDoc doc) => [
      doc.title,
      doc.productName,
      doc.service,
      doc.overview,
      doc.closing,
      for (final s in doc.sections) ...[
        s.heading,
        s.body,
        for (final sub in s.subsections) ...[sub.heading, sub.body],
      ],
    ].join('\n');

void main() {
  test('Terms and Privacy Policy have every numbered section', () {
    expect(LegalContent.terms.sections.length, 20);
    expect(LegalContent.privacy.sections.length, 14);
    for (final doc in [LegalContent.terms, LegalContent.privacy]) {
      for (var i = 0; i < doc.sections.length; i++) {
        expect(doc.sections[i].heading, startsWith('${i + 1}. '));
        expect(doc.sections[i].body, isNotEmpty);
      }
    }
  });

  test('no placeholders are left in the published text', () {
    for (final doc in [LegalContent.terms, LegalContent.privacy]) {
      final text = _allText(doc);
      expect(text.contains('['), isFalse);
      expect(text.contains(']'), isFalse);
      expect(text.contains('INSERT'), isFalse);
      expect(text.contains('TODO'), isFalse);
    }
  });

  test('contact sections point to the configured addresses', () {
    expect(
        LegalContent.terms.sections.last.body, contains(ContactConfig.email));
    expect(LegalContent.privacy.sections.last.body,
        contains(ContactConfig.privacyEmail));
  });
// test registered address
  test('the registered address sentence appears only when an address is set',
      () {
    final hasAddress = ContactConfig.registeredAddress.isNotEmpty;
    expect(_allText(LegalContent.terms).contains('registered address'),
        hasAddress);
    expect(_allText(LegalContent.privacy).contains('registered address'),
        hasAddress);
  });
}
