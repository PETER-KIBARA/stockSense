import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/auth/widget_tree.dart';
import '../services/auth_service.dart';
import '../services/sample_data_service.dart';

class SampleDataActions {
  /// Asks for confirmation, clears the sample workspace, then reopens the app
  /// on a fresh, empty workspace.
  static Future<void> confirmAndClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear sample data?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'This removes the sample items, their stock movements and predictions, '
          'including any sample item you edited. Items you added yourself are kept. '
          'This cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear sample data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final uid = AuthService.currentUser?.id;
    if (uid == null) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      await SampleDataService.clearSampleData(uid);
      navigator.pop(); // progress dialog
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WidgetTree()),
        (route) => false,
      );
      messenger.showSnackBar(const SnackBar(
        content: Text(
            'Sample data cleared. Your workspace is ready for your own stock.'),
      ));
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not clear the sample data. Please try again.'),
      ));
    }
  }
}

/// Dashboard banner shown while the sample shop is still in the workspace.
class SampleDataBanner extends StatefulWidget {
  const SampleDataBanner({super.key});

  @override
  State<SampleDataBanner> createState() => _SampleDataBannerState();
}

class _SampleDataBannerState extends State<SampleDataBanner> {
  static const String _dismissedKey = 'sample_banner_dismissed';
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final uid = AuthService.currentUser?.id;
    if (uid == null || !AuthService.isTrialSession) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_dismissedKey) ?? false) return;
    final hasSample = await SampleDataService.hasSampleData(uid);
    if (mounted && hasSample) setState(() => _visible = true);
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF1976D2);
    final link = isDark ? const Color(0xFF64B5F6) : accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.storefront_outlined, color: link, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're exploring a sample shop",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Browse, edit or delete anything. When you are ready, clear it and start with your own stock.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => SampleDataActions.confirmAndClear(context),
                    icon: Icon(Icons.cleaning_services_outlined,
                        size: 16, color: link),
                    label: Text(
                      'Clear sample data',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: link,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: _dismiss,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile tab card, so clearing stays available after the banner is dismissed.
class SampleDataProfileCard extends StatefulWidget {
  const SampleDataProfileCard({super.key});

  @override
  State<SampleDataProfileCard> createState() => _SampleDataProfileCardState();
}

class _SampleDataProfileCardState extends State<SampleDataProfileCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final uid = AuthService.currentUser?.id;
    if (uid == null || !AuthService.isTrialSession) return;
    final hasSample = await SampleDataService.hasSampleData(uid);
    if (mounted && hasSample) setState(() => _visible = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.storefront_outlined),
          title: Text('Sample data',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          subtitle: Text(
            'Your workspace includes a sample shop. Clear it to start with your own stock.',
            style: GoogleFonts.poppins(fontSize: 12, height: 1.4),
          ),
          trailing: TextButton(
            onPressed: () => SampleDataActions.confirmAndClear(context),
            child: const Text('Clear'),
          ),
        ),
      ),
    );
  }
}
