import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/contact_config.dart';

/// StockSense does not send email from the app. This opens the visitor's own
/// email app with the message prepared, and explains the last step clearly.
class EmailHandoff {
  /// Call straight from a button press so browsers allow the mail app to open.
  static Future<void> start(
    BuildContext context, {
    required String subject,
    required String body,
    String? heading,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: ContactConfig.email,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    var opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {
      opened = false;
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _EmailHandoffDialog(
        subject: subject,
        body: body,
        mailOpened: opened,
        heading: heading,
      ),
    );
  }
}

class _EmailHandoffDialog extends StatefulWidget {
  final String subject;
  final String body;
  final bool mailOpened;
  final String? heading;

  const _EmailHandoffDialog({
    required this.subject,
    required this.body,
    required this.mailOpened,
    this.heading,
  });

  @override
  State<_EmailHandoffDialog> createState() => _EmailHandoffDialogState();
}

class _EmailHandoffDialogState extends State<_EmailHandoffDialog> {
  static const Color _orange = Color(0xFFFF6B00);
  bool _copied = false;

  Uri get _gmailUri => Uri.https('mail.google.com', '/mail/', {
        'view': 'cm',
        'fs': '1',
        'to': ContactConfig.email,
        'su': widget.subject,
        'body': widget.body,
      });

  Uri get _whatsappUri => Uri.https('wa.me', '/${ContactConfig.whatsapp}', {
        'text': '${widget.subject}\n\n${widget.body}',
      });

  Future<void> _open(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(
      text:
          'To: ${ContactConfig.email}\nSubject: ${widget.subject}\n\n${widget.body}',
    ));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.heading ??
        (widget.mailOpened
            ? 'One last step: send your email'
            : 'Send your message by email');
    final intro = widget.mailOpened
        ? 'Your email app should have opened with your message ready. Press Send to finish.'
        : 'We could not open an email app on this device. Use one of the options below to send your message to ${ContactConfig.email}.';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined, color: _orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(heading,
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(intro, style: GoogleFonts.poppins(fontSize: 14, height: 1.5)),
            const SizedBox(height: 8),
            Text(
              'Nothing is sent until you press Send in your email app.',
              style: GoogleFonts.poppins(
                  fontSize: 12, height: 1.5, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _open(_gmailUri),
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Text('Open Gmail'),
                ),
                if (ContactConfig.whatsapp.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _open(_whatsappUri),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp'),
                  ),
                OutlinedButton.icon(
                  onPressed: _copy,
                  icon: Icon(_copied ? Icons.check : Icons.copy, size: 18),
                  label: Text(_copied ? 'Copied' : 'Copy details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Or email us directly:',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            SelectableText(
              ContactConfig.email,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600, color: _orange),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
              backgroundColor: _orange, foregroundColor: Colors.white),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
