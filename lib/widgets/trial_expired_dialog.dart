import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/landing_screen.dart';
import '../services/auth_service.dart';
import '../services/trial_service.dart';
import '../utils/consultation_utils.dart';

class TrialExpiredDialog {
  /// signedIn: true  -> button logs out and returns to the home (landing) page.
  /// signedIn: false -> trial already used in this browser; button just closes.
  static Future<void> show(BuildContext context, {required bool signedIn}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.timer_off_outlined, color: Color(0xFFFF6B00)),
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
          content: Text(
            'Your 14-day free trial of StockSense is over. To keep using the app, '
            'contact Cloudora and we will help you choose a plan.',
            style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  ConsultationUtils.showConsultationDialog(dialogContext),
              child: const Text('Contact Cloudora'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final navigator =
                    Navigator.of(dialogContext, rootNavigator: true);
                if (!signedIn) {
                  navigator.pop();
                  return;
                }
                await TrialService.markTrialUsed();
                await AuthService.signOut();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LandingScreen()),
                  (route) => false,
                );
              },
              child: Text(signedIn ? 'Log out' : 'Close'),
            ),
          ],
        ),
      ),
    );
  }
}
