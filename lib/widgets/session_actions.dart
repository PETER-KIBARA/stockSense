import 'package:flutter/material.dart';
import '../screens/landing_screen.dart';
import '../services/auth_service.dart';
import '../services/trial_service.dart';
import '../utils/feedback_utils.dart';

class SessionActions {
  /// Confirms, then signs out. During a free trial the account and its start
  /// date are kept, so the visitor can come back to the same workspace.
  static Future<void> confirmSignOut(BuildContext context) async {
    final isTrial = AuthService.isTrialSession;
    var feedbackOpened = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isTrial ? 'Leave your workspace?' : 'Sign out'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isTrial
                  ? 'Your free trial keeps running and your items stay saved on this browser. '
                      'Tap Start Free Trial on the home page to come back.\n\n'
                      'Before you go, we would love your feedback.'
                  : 'Are you sure you want to sign out?'),
              if (isTrial && feedbackOpened) ...[
                const SizedBox(height: 12),
                const Text(
                  'Thank you! Once you have submitted the form, close its tab '
                  'and come back here to finish leaving.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          actions: [
            if (isTrial)
              TextButton.icon(
                onPressed: () async {
                  final opened = await FeedbackUtils.openFeedbackForm(context);
                  if (opened && dialogContext.mounted) {
                    setDialogState(() => feedbackOpened = true);
                  }
                },
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Give feedback'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(isTrial ? 'Leave' : 'Sign Out',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (isTrial) {
        await TrialService.leaveTrial();
      } else {
        await AuthService.signOut();
      }
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    } catch (e) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not sign out. Please try again.')));
    }
  }
}
