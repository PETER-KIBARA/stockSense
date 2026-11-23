import 'contact_config.dart';

class LegalSubsection {
  final String heading;
  final String body;
  const LegalSubsection(this.heading, this.body);
}

class LegalSection {
  final String heading;
  final String body;
  final List<LegalSubsection> subsections;
  const LegalSection(this.heading, this.body, {this.subsections = const []});
}

class LegalDoc {
  final String title;
  final String productName;
  final String service;
  final String overview;
  final List<LegalSection> sections;
  final String closing;

  const LegalDoc({
    required this.title,
    required this.productName,
    required this.service,
    required this.overview,
    required this.sections,
    required this.closing,
  });
}

/// Cloudora's Terms and Conditions and Privacy Policy for the Inventory
class LegalContent {
  /// Set these when Cloudora provides the dates. While empty they are not shown.
  static const String effectiveDate = '';
  static const String lastUpdated = '';

  static String? get metaLine {
    final parts = <String>[
      if (effectiveDate.isNotEmpty) 'Effective date: $effectiveDate',
      if (lastUpdated.isNotEmpty) 'Last updated: $lastUpdated',
    ];
    return parts.isEmpty ? null : parts.join('    |    ');
  }

  static const String _service = 'Service: Stock, sales and procurement SaaS.';
  static const String _overview =
      'Service overview: The Inventory Management System helps businesses maintain product and stock records, record stock movements and sales, monitor stock levels, receive low-stock alerts and review operational reports.';
  static const String _closing =
      'This document is intended to operate alongside the laws of the Republic of Kenya, including the Data Protection Act, 2019 and the Data Protection (General) Regulations, 2021, to the extent applicable.';

  /// "<lead><registered address>." with a leading space, or nothing when unset.
  static String _address(String lead) => ContactConfig.registeredAddress.isEmpty
      ? ''
      : ' $lead${ContactConfig.registeredAddress}.';

  static final LegalDoc terms = LegalDoc(
    title: 'Terms and Conditions',
    productName: 'Inventory Management System',
    service: _service,
    overview: _overview,
    closing: _closing,
    sections: [
      LegalSection('1. Acceptance and parties',
          '''These Terms and Conditions ("Terms") govern access to and use of the service identified in this document, which is provided by Cloudora Limited ("Cloudora", "we", "us" or "our"). By creating an account, accessing or using the service, you agree to these Terms. If you use it for an organisation, you confirm that you are authorised to bind that organisation. If you do not agree, do not access or use the service.'''),
      LegalSection('2. Definitions',
          '''"Customer" means the person or organisation subscribing to or authorised to use the service. "User" means an individual authorised by the Customer to access it. "Customer Data" means information or content submitted to, stored in or generated through the Customer's use of the service. "Subscription" means the paid or otherwise agreed access entitlement.'''),
      LegalSection(
        '3. Service and scope',
        '''The service provides the functions described in its product documentation, selected plan or order. Features may depend on subscription level, configuration, integrations and third-party availability. Cloudora may maintain, update or improve the service, provided it does not disregard express contractual commitments.''',
        subsections: [
          LegalSubsection('Stock and transaction accuracy',
              '''The Customer is responsible for accurate product setup, opening balances, stock counts, units of measure, prices, tax settings, purchases, sales, returns, wastage and stock adjustments. The Customer should perform physical stock checks and reconcile system records regularly.'''),
          LegalSubsection('Alerts and procurement decisions',
              '''Low-stock alerts, reports and analytics are decision-support tools. They depend on the completeness and accuracy of information entered and do not guarantee demand, supplier availability, sales, profit or optimal purchasing outcomes. The Customer remains responsible for procurement and pricing decisions.'''),
          LegalSubsection('User permissions and audit trail',
              '''The Customer is responsible for assigning appropriate access to staff and for reviewing material stock adjustments, voids, returns and other sensitive actions. The Customer should not share administrator credentials or permit unauthorised users to alter records.'''),
        ],
      ),
      LegalSection('4. Accounts and access',
          '''The Customer must provide accurate account information, appoint authorised administrators, manage user permissions and keep credentials confidential. Users must not share credentials or allow unauthorised access. The Customer must promptly notify Cloudora of suspected account compromise. The Customer is responsible for activity carried out through its accounts except to the extent caused by Cloudora's breach or other liability that cannot lawfully be excluded.'''),
      LegalSection('5. Fees, billing and cancellation',
          '''Fees, billing frequency, payment methods, taxes, renewal arrangements, trial terms and cancellation rules are those displayed at checkout or agreed in a written order. The Customer must pay amounts when due. Cloudora may restrict or suspend paid features for overdue undisputed amounts after reasonable notice. Refunds, if any, will be governed by the order, applicable law and any express refund policy. Do not publish a fixed no-refund rule unless it has been reviewed for compliance with consumer law and the actual sales model.'''),
      LegalSection('6. Permitted use and restrictions',
          '''The Customer and Users must use the service lawfully and must not: (a) use it for fraud or unlawful activity; (b) access another account without permission; (c) interfere with security, availability or integrity; (d) upload malware or harmful code; (e) probe, scan or test vulnerabilities without written authorisation; (f) reverse engineer or copy the service except where applicable law permits; (g) resell, sublicense or commercially exploit it without written permission; or (h) upload data they have no right or lawful basis to use.'''),
      LegalSection('7. Customer responsibilities and data',
          '''The Customer is responsible for the accuracy and lawfulness of Customer Data, the notices and permissions required for its collection and use, user access controls, and decisions made using the service. The Customer must maintain appropriate independent records and backups where necessary for its business. The Customer retains its rights in Customer Data and grants Cloudora the limited right to host, process, transmit and display it solely as needed to provide, secure and support the service and comply with law.'''),
      LegalSection('8. Privacy and data processing',
          '''Use of the service is also governed by its Privacy Policy. Where Cloudora processes personal data on behalf of the Customer, the parties must put in place a written DPA where required by law. The DPA should identify the subject matter, duration, purposes, data types, data-subject categories, instructions, confidentiality, security, sub-processing, assistance, audits and return or deletion arrangements. These Terms do not replace that DPA.'''),
      LegalSection('9. Intellectual property',
          '''Cloudora and its licensors retain all rights in the service, software, source code, interfaces, designs, documentation, trademarks and underlying technology. The Customer receives a limited, non-exclusive, non-transferable and revocable right to use the service during the applicable access period. No ownership of the software is transferred. The Customer must not remove proprietary notices or use Cloudora branding without permission.'''),
      LegalSection('10. Third-party services',
          '''The service may connect to third-party platforms, APIs, payment providers, messaging services, calendar tools, hosting providers or other integrations. Their availability and terms are controlled by those providers. The Customer is responsible for reviewing and complying with applicable third-party terms and authorising any integrations. Cloudora is not responsible for independent third-party systems to the extent they are outside Cloudora's reasonable control.'''),
      LegalSection('11. Availability, maintenance and support',
          '''Cloudora will use reasonable efforts to operate and support the service. Access may be interrupted for maintenance, updates, infrastructure or connectivity failures, security events, third-party outages or circumstances beyond reasonable control. Any uptime commitment, support hours, response time or service credit applies only if expressly stated in a separate service-level agreement or order.'''),
      LegalSection('12. Reports and automated outputs',
          '''Reports, calculations, reminders, flags, recommendations and analytics are tools to assist the Customer. Unless expressly agreed otherwise, they are not professional, legal, financial, educational or other regulated advice and should be checked by an appropriately qualified person. The Customer remains responsible for its business decisions, records and compliance obligations.'''),
      LegalSection('13. Suspension and termination',
          '''Cloudora may suspend or terminate access for a material breach, unlawful use, security threat, non-payment or where continued provision is prohibited by law. Where reasonably practicable, Cloudora will give notice and an opportunity to remedy the issue. The Customer may cancel in accordance with its order or subscription settings. On termination, access ends and Customer Data will be made available for export or returned/deleted in accordance with the applicable order, Privacy Policy and DPA, subject to legal retention duties and technical backup cycles.'''),
      LegalSection('14. Warranties and disclaimers',
          '''Except for express commitments in a written order or service-level agreement, the service is provided on an "as available" basis. Cloudora does not warrant that the service will be uninterrupted, error-free or suitable for every purpose, or that all third-party integrations will remain available. Nothing in these Terms excludes a warranty or right that cannot lawfully be excluded.'''),
      LegalSection('15. Limitation of liability',
          '''To the maximum extent permitted by law, neither party is liable to the other for indirect or consequential loss, loss of anticipated profits, or loss of goodwill arising from the service. Subject to liabilities that cannot lawfully be limited, Cloudora's aggregate liability arising from the service will not exceed the fees paid or payable by the Customer for that service in the twelve months before the event giving rise to the claim. This limitation does not apply to fraud, wilful misconduct or any liability that applicable law prohibits limiting. The final clause should be reviewed by Kenyan counsel and aligned with the order and customer type.'''),
      LegalSection('16. Indemnity',
          '''The Customer is responsible for claims arising from its unlawful use of the service, breach of these Terms, infringement of third-party rights or unlawful Customer Data, except to the extent a claim is caused by Cloudora's breach, negligence or unlawful conduct. Any indemnity is subject to applicable law and reasonable notice, cooperation and control of the defence.'''),
      LegalSection('17. Changes to the service or Terms',
          '''Cloudora may update the service and these Terms. Material changes will be notified through the service, website or account contact where reasonably practicable and where required by law. The updated Terms will state their effective date. If a change materially affects an existing paid subscription, the Customer may have rights under its order or applicable law.'''),
      LegalSection('18. Governing law and disputes',
          '''These Terms are governed by the laws of the Republic of Kenya. The parties will first attempt to resolve disputes through good-faith discussions. If they cannot resolve a dispute, either party may refer it to a court of competent jurisdiction in Kenya. Nothing in this clause prevents a party from seeking urgent interim relief where appropriate.'''),
      LegalSection('19. General',
          '''If a provision is unenforceable, the remaining provisions remain effective. A failure to enforce a provision is not a waiver. The Customer may not assign these Terms without Cloudora's written consent, except as permitted by law. These Terms, the applicable order, the Privacy Policy and any DPA or service-level agreement form the contractual framework for the service.'''),
      LegalSection('20. Contact',
          'Questions about the service or these Terms should be sent to ${ContactConfig.email}.${_address("Cloudora Limited's registered address is ")}'),
    ],
  );

  static final LegalDoc privacy = LegalDoc(
    title: 'Privacy Policy',
    productName: 'Inventory Management System',
    service: _service,
    overview: _overview,
    closing: _closing,
    sections: [
      LegalSection('1. Who we are and scope',
          '''Cloudora Limited ("Cloudora", "we", "us" or "our") provides the website or software service identified in this document. This Privacy Policy explains how personal data is collected, used, stored, disclosed and otherwise processed when you visit, register for or use the relevant service. It applies to website visitors, account holders, authorised users and, where applicable, individuals whose information a customer enters into the service.'''),
      LegalSection('2. Our role and the customer\'s role',
          '''The organisation subscribing to or configuring a business account (the "Customer") will generally decide why and how it uses information about its own customers, employees, students, tenants, suppliers or other individuals. For that information, the Customer will generally act as the data controller and Cloudora will generally act as its data processor, processing the information to provide and support the service on the Customer's documented instructions. Cloudora may separately act as a data controller for information it uses for its own account administration, billing, security, support and website operations. The parties' actual roles depend on the processing in question and applicable law.'''),
      LegalSection(
        '3. Information we may process',
        '''Depending on the service and how the Customer configures it, information may include names, contact details, account identifiers, organisation details, records entered by users, transaction or operational records, device and browser details, IP addresses, login records, timestamps, diagnostic information and support correspondence. The exact information collected depends on the features enabled. Customers should not enter sensitive personal data unless the service is intended and configured for that purpose and they have a lawful basis to do so.''',
        subsections: [
          LegalSubsection('Inventory and business records',
              '''The service may process product names and codes, stock quantities, purchase and sales records, supplier details, staff or user identifiers, customer details where entered, prices, transaction dates, stock adjustments and reporting information. Some records may identify sole traders, employees, suppliers or customers and therefore may constitute personal data.'''),
          LegalSubsection('Operational analytics',
              '''The service may generate summaries of stock movement, sales, low-stock levels and purchasing patterns. Reports should be accessed only by authorised users. Cloudora may process technical usage information to maintain and improve the service, subject to applicable law and the Customer's agreement.'''),
        ],
      ),
      LegalSection('4. How information is collected',
          '''Information may be provided by you, entered by a Customer or its authorised users, generated through use of the service, collected through essential cookies or similar technologies, received from integrations enabled by the Customer, or supplied through support and sales communications.'''),
      LegalSection('5. Purposes and lawful basis',
          '''Information may be processed to create and administer accounts; provide the service and its features; store and display Customer records; process subscriptions and payments; provide support; maintain service integrity and security; diagnose faults; communicate service notices; comply with legal obligations; and establish, exercise or defend legal claims. Where consent is relied upon, it will be requested for the relevant purpose and may be withdrawn subject to legal and contractual limitations. The Customer is responsible for identifying and documenting an appropriate lawful basis for personal data it enters into the service.'''),
      LegalSection('6. Customer instructions and data rights',
          '''Where Cloudora processes Customer data as a processor, the Customer is ordinarily the first point of contact for individuals seeking access, correction, deletion, objection or other data-subject rights. Cloudora will provide reasonable assistance in accordance with the applicable service agreement and any Data Processing Agreement (DPA). Where Cloudora is the controller, requests may be sent to the privacy contact listed below. We may need to verify identity and may be unable to comply where a lawful exception applies.'''),
      LegalSection('7. Sharing and service providers',
          '''We may disclose or permit access to information to personnel who need it to operate or support the service, hosting and infrastructure providers, security and backup providers, payment processors, communications providers and other sub-processors authorised under the relevant customer agreement. We may also disclose information where required by law or to protect rights, users, systems or public safety. We do not sell personal data.'''),
      LegalSection('8. International transfers',
          '''Some service providers or infrastructure may process or store information outside Kenya. Before any such transfer, the parties must identify the relevant locations and ensure that the transfer is permitted under applicable Kenyan data protection law and supported by the required safeguards or other lawful transfer condition. The actual hosting and transfer locations for this service must be confirmed and reflected in this notice before publication.'''),
      LegalSection('9. Security',
          '''Cloudora is to apply technical and organisational safeguards appropriate to the nature of the information and risks, which may include access controls, authentication, logging, backup controls, encryption where implemented, vulnerability management and restricted administrative access. No internet service can be guaranteed completely secure. This notice must not be read as a promise that a particular safeguard is active unless it has been verified in the deployed product.'''),
      LegalSection('10. Retention and deletion',
          '''Information is retained only for as long as needed for the purposes for which it was collected, the Customer's instructions, applicable legal obligations, dispute resolution and legitimate operational requirements. The actual retention schedule for active records, backups, logs and terminated accounts must be set and documented by Cloudora and, where relevant, agreed with the Customer. On termination, Customer data will be returned or deleted as provided in the service agreement and DPA, subject to lawful retention requirements and backup-cycle limitations.'''),
      LegalSection('11. Cookies and analytics',
          '''The website or service may use essential cookies or similar technologies to maintain sessions, authenticate users, remember settings and protect the service. Non-essential analytics or advertising technologies should only be deployed with appropriate notice and consent or other lawful basis where required. The deployed cookie tools and preferences must be accurately described before publication.'''),
      LegalSection('12. Children and vulnerable users',
          '''If the service is used by or processes information about children, the Customer must ensure that collection and use comply with applicable law, including requirements concerning parental or guardian involvement and the child's best interests. Cloudora will process such information only for the agreed service purposes and under the applicable customer instructions. This section is particularly relevant to education deployments.'''),
      LegalSection('13. Changes to this policy',
          '''We may update this Privacy Policy to reflect changes to the service, processing practices or legal requirements. The updated version will show its effective or last-updated date. Where required, material changes will be notified to affected users or Customers.'''),
      LegalSection('14. Contact and complaints',
          'Privacy enquiries and requests should be sent to ${ContactConfig.privacyEmail}. Customer users should ordinarily contact their organisation\'s administrator first for records managed by that organisation.${_address("Cloudora's registered address is ")} Individuals may also contact the Office of the Data Protection Commissioner in Kenya where appropriate.'),
    ],
  );
}
