import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/landing_screen.dart';
import '../services/auth_service.dart';
import '../services/trial_service.dart';
import '../utils/feedback_utils.dart';
import 'upgrade_widgets.dart';

class TrialExpiredDialog {
  /// signedIn: true  -> Log out signs out and returns to the home (landing) page.
  /// signedIn: false -> trial already used in this browser; the button just closes.
  static Future<void> show(BuildContext context, {required bool signedIn}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: _TrialExpiredContent(signedIn: signedIn),
      ),
    );
  }
}

class _TrialExpiredContent extends StatefulWidget {
  final bool signedIn;
  const _TrialExpiredContent({required this.signedIn});

  @override
  State<_TrialExpiredContent> createState() => _TrialExpiredContentState();
}

class _TrialExpiredContentState extends State<_TrialExpiredContent> {
  static const Color _orange = Color(0xFFFF6B00);
  bool _feedbackOpened = false;

  Future<void> _openFeedback() async {
    final opened = await FeedbackUtils.openFeedbackForm(context);
    if (opened && mounted) setState(() => _feedbackOpened = true);
  }

  Future<void> _logOut() async {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (!widget.signedIn) {
      navigator.pop();
      return;
    }
    await TrialService.markTrialUsed();
    await AuthService.signOut();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextStep = widget.signedIn
        ? 'tap Log out to return to the home page.'
        : 'tap Close.';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.timer_off_outlined, color: _orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your free trial has ended',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your 14-day free trial of StockSense is over. To keep using the app, '
            'upgrade to a full plan and our team will help you get set up.\n\n'
            'We would also love to hear how the trial went.',
            style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
          ),
          if (_feedbackOpened) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thank you for your feedback! Once you have submitted the '
                      'form, close its tab and come back here, then $nextStep',
                      style: GoogleFonts.poppins(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: _openFeedback,
          icon: const Icon(Icons.rate_review_outlined, size: 18),
          label: const Text('Share feedback'),
        ),
        OutlinedButton(
          onPressed: _logOut,
          child: Text(widget.signedIn ? 'Log out' : 'Close'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
          ),
          onPressed: () => UpgradeSheet.show(context),
          icon: const Icon(Icons.workspace_premium_outlined, size: 18),
          label: const Text('Upgrade'),
        ),
      ],
    );
  }
}
