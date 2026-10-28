import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/contact_config.dart';
import '../services/auth_service.dart';
import '../utils/email_handoff.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const List<FAQItem> _faqItems = [
    FAQItem(
      question: 'How do I add a new inventory item?',
      answer:
          'Open the Items tab and tap Add Item (or use Add Item on the dashboard). Fill in the name, description, category, quantity, price and supplier. You can also add a photo and an expiry date for perishable items.',
    ),
    FAQItem(
      question: 'How do stock predictions work?',
      answer:
          'StockSense studies your recent stock-out movements to estimate how many days of stock you have left for each item. The more movements you record, the more reliable the estimate. Confidence shows High, Medium or Low depending on how much recent data is available.',
    ),
    FAQItem(
      question: 'How will I know when stock is low or expiring?',
      answer:
          'Low-stock and out-of-stock items are flagged on your dashboard and in the Items list, and expiring or expired items appear in Expiry Alerts. During the free trial, alerts are shown inside the app. Email alerts are not part of the trial.',
    ),
    FAQItem(
      question: 'What are reorder levels?',
      answer:
          'A reorder level is the minimum quantity you want to keep of an item. When stock falls to that level or below, the item is flagged as Low Stock. You can set a custom level when you add or edit an item.',
    ),
    FAQItem(
      question: 'Can I add my team?',
      answer:
          'Team accounts with Admin and Staff roles are available on full plans and are set up with you when you upgrade. Tap Upgrade in the top bar to compare plans.',
    ),
    FAQItem(
      question: 'Can I export my data or get reports?',
      answer:
          'Reports and exports are part of full plans. Tap Upgrade to compare plans, or Book a Consultation and we will show you what is included.',
    ),
    FAQItem(
      question: 'How do I scan barcodes?',
      answer:
          'Scanning needs a phone or tablet camera and is not available in the browser yet. You can add any item with the Add Item form.',
    ),
    FAQItem(
      question: 'What happens when items expire?',
      answer:
          'Perishable items with an expiry date appear in Expiry Alerts: expired items in red and items expiring soon in orange, so you can sell or remove them in time.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhone = ContactConfig.phone.isNotEmpty;
    final hasWhatsapp = ContactConfig.whatsapp.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.help_center,
                              color: Theme.of(context).primaryColor, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Need Help?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.grey[800],
                                  )),
                              Text(
                                'Find answers to common questions or contact our team.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Actions',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.grey[800],
                            )),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                  'Contact Us',
                                  Icons.support_agent,
                                  Colors.blue,
                                  _contactSupport),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton('Report a Problem',
                                  Icons.bug_report, Colors.red, _reportBug),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickActionButton(
                                  'Suggest a Feature',
                                  Icons.lightbulb,
                                  Colors.orange,
                                  _requestFeature),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickActionButton(
                                  'User Guide',
                                  Icons.menu_book,
                                  Colors.green,
                                  _showUserGuide),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Frequently Asked Questions',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.grey[800],
                            )),
                        const SizedBox(height: 16),
                        ..._faqItems.map(_buildFAQItem),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contact Information',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.grey[800],
                            )),
                        const SizedBox(height: 16),
                        _buildContactItem(
                            Icons.email,
                            'Email',
                            ContactConfig.email,
                            () => _launchEmail(ContactConfig.email)),
                        if (hasPhone)
                          _buildContactItem(
                              Icons.phone,
                              'Phone',
                              ContactConfig.phone,
                              () => _launch(Uri(
                                  scheme: 'tel',
                                  path: ContactConfig.phone
                                      .replaceAll(' ', '')))),
                        if (hasWhatsapp)
                          _buildContactItem(
                              Icons.chat_outlined,
                              'WhatsApp',
                              'Chat with us',
                              () => _launch(Uri.https(
                                  'wa.me', '/${ContactConfig.whatsapp}'))),
                        _buildContactItem(Icons.location_on_outlined,
                            'Based in', ContactConfig.location, null),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w500, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ExpansionTile(
      title: Text(faq.question,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.grey[800],
          )),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(faq.answer,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.grey[600],
              )),
        ),
      ],
    );
  }

  Widget _buildContactItem(
      IconData icon, String title, String value, VoidCallback? onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.grey[800],
          )),
      subtitle: Text(value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey[600],
          )),
      trailing: onTap != null
          ? Icon(Icons.arrow_forward_ios,
              size: 16, color: isDark ? Colors.white54 : Colors.grey[600])
          : null,
      onTap: onTap,
    );
  }

  void _contactSupport() {
    final hasPhone = ContactConfig.phone.isNotEmpty;
    final hasWhatsapp = ContactConfig.whatsapp.isNotEmpty;

    // Only email is configured: go straight to it.
    if (!hasPhone && !hasWhatsapp) {
      _launchEmail(ContactConfig.email);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Contact Us',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildContactOption('Email', Icons.email, Colors.blue, () {
              Navigator.pop(dialogContext);
              _launchEmail(ContactConfig.email);
            }),
            if (hasPhone)
              _buildContactOption('Phone', Icons.phone, Colors.green, () {
                Navigator.pop(dialogContext);
                _launch(Uri(
                    scheme: 'tel',
                    path: ContactConfig.phone.replaceAll(' ', '')));
              }),
            if (hasWhatsapp)
              _buildContactOption('WhatsApp', Icons.chat_outlined, Colors.teal,
                  () {
                Navigator.pop(dialogContext);
                _launch(Uri.https('wa.me', '/${ContactConfig.whatsapp}'));
              }),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  Widget _buildContactOption(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }

  void _reportBug() => _askForDetails(
        title: 'Report a Problem',
        kind: 'Problem report',
        subjectLabel: 'What went wrong?',
        descriptionLabel: 'Details',
        hint:
            'Describe what happened, the steps to reproduce it and what you expected.',
        icon: Icons.bug_report,
        color: Colors.red,
      );

  void _requestFeature() => _askForDetails(
        title: 'Suggest a Feature',
        kind: 'Feature suggestion',
        subjectLabel: 'Feature title',
        descriptionLabel: 'Description',
        hint: 'Describe the feature you would like to see.',
        icon: Icons.lightbulb,
        color: Colors.orange,
      );

  void _askForDetails({
    required String title,
    required String kind,
    required String subjectLabel,
    required String descriptionLabel,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: subjectLabel,
                    prefixIcon: Icon(icon),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: descriptionLabel,
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    hintText: hint,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Continuing opens an email to ${ContactConfig.email}. Nothing is sent until you press Send.',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final subject = subjectController.text.trim();
              final description = descriptionController.text.trim();
              if (subject.isEmpty || description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please fill in both fields.')));
                return;
              }
              Navigator.pop(dialogContext);
              _sendByEmail(
                  kind: kind, title: subject, description: description);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: color, foregroundColor: Colors.white),
            child: const Text('Continue by email'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendByEmail({
    required String kind,
    required String title,
    required String description,
  }) async {
    final user = AuthService.currentUser;
    final who = AuthService.isTrialSession
        ? 'Free trial workspace ${user?.id ?? 'unknown'}'
        : ((user?.email ?? '').isNotEmpty ? user!.email : 'Not signed in');

    final body = [
      description,
      '',
      '---',
      'Type: $kind',
      'From: $who',
      'Platform: ${kIsWeb ? 'Web' : Theme.of(context).platform.name}',
      'Time: ${DateTime.now().toLocal()}',
    ].join('\n');

    await EmailHandoff.start(context, subject: '[$kind] $title', body: body);
  }

  void _showUserGuide() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserGuideScreen()),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent('StockSense enquiry')}',
    );
    await _launch(uri,
        failureMessage:
            'Could not open an email app. Please email $email directly.');
  }

  Future<void> _launch(Uri uri, {String? failureMessage}) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(failureMessage ?? 'Could not open that link on this device.'),
        backgroundColor: Colors.orange,
      ));
    }
  }
}

class FAQItem {
  final String question;
  final String answer;

  const FAQItem({required this.question, required this.answer});
}

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Guide',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGuideSection(
                    context, 'Getting Started', Icons.play_arrow, [
                  'Tap Start Free Trial on the home page. No sign-up or password is needed.',
                  'Explore the dashboard for your stock overview and quick actions.',
                  'Move between the Home, Items, Stock, Predict and Profile tabs.',
                ]),
                _buildGuideSection(
                    context, 'Managing Inventory', Icons.inventory_2, [
                  'Add items with the Add Item button.',
                  'Set reorder levels to see low-stock warnings.',
                  'Add a photo to make items easier to recognise.',
                  'Set expiry dates on perishable items.',
                ]),
                _buildGuideSection(context, 'Stock Movements', Icons.history, [
                  'See every stock in, stock out and adjustment in the Stock tab.',
                  'Filter movements by type or date, or search by item or reason.',
                  'Adjust an item\'s stock from the Items tab and give a reason.',
                ]),
                _buildGuideSection(context, 'Predictions', Icons.analytics, [
                  'The Predict tab estimates how many days of stock each item has left.',
                  'Filter by confidence or show only urgent items.',
                  'Use the estimates to plan when to reorder.',
                ]),
                _buildGuideSection(
                    context, 'Upgrading', Icons.workspace_premium_outlined, [
                  'Tap Upgrade in the top bar to compare the Entry, Mid and High plans.',
                  'Team accounts and roles are set up with you when you upgrade.',
                  'Our team contacts you to complete the setup.',
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection(
      BuildContext context, String title, IconData icon, List<String> steps) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isDark ? Colors.blue[300] : Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey[800],
                      )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blue[300] : Colors.blue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Expanded(
                        child: Text(step,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.grey[800],
                            )),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
