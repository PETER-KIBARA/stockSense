import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/feedback_config.dart';

class FeedbackUtils {
  /// Opens the feedback form in a new browser tab (or the external browser on mobile).
  /// Call it straight from a button press so browsers don't block the new tab.
  static Future<void> openFeedbackForm(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(FeedbackConfig.formUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger?.showSnackBar(const SnackBar(
        content: Text('Could not open the feedback form. Please try again.'),
      ));
    }
  }
}