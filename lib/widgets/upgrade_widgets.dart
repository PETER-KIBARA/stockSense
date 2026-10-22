import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/plans_config.dart';
import '../utils/consultation_utils.dart';

/// Plan chooser. Picking a plan continues into the existing consultation form.
class UpgradeSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 720),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _UpgradeSheetContent(
        onChoose: (planName) {
          Navigator.of(sheetContext).pop();
          ConsultationUtils.showConsultationDialog(context, plan: planName);
        },
        onTalk: () {
          Navigator.of(sheetContext).pop();
          ConsultationUtils.showConsultationDialog(context);
        },
      ),
    );
  }
}

class _UpgradeSheetContent extends StatelessWidget {
  final ValueChanged<String> onChoose;
  final VoidCallback onTalk;

  const _UpgradeSheetContent({required this.onChoose, required this.onTalk});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Upgrade to a full plan',
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the plan that fits your business. Our team will contact you to set up your account.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          for (final plan in PlansConfig.plans) ...[
            _PlanTile(plan: plan, onChoose: () => onChoose(plan.name)),
            const SizedBox(height: 12),
          ],
          Center(
            child: TextButton(
              onPressed: onTalk,
              child: Text(
                'Not sure which plan? Talk to us',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final PlanInfo plan;
  final VoidCallback onChoose;

  const _PlanTile({required this.plan, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.primaryColor;
    final muted = isDark ? Colors.white70 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: plan.recommended
            ? accent.withValues(alpha: isDark ? 0.15 : 0.06)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.recommended
              ? accent
              : (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.grey[300]!),
          width: plan.recommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              if (plan.recommended)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Most popular',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(plan.audience,
              style: GoogleFonts.poppins(fontSize: 12, color: muted)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.priceKes,
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(plan.priceUsd,
                  style: GoogleFonts.poppins(fontSize: 13, color: muted)),
            ],
          ),
          const SizedBox(height: 12),
          for (final feature in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child:
                        Text(feature, style: GoogleFonts.poppins(fontSize: 13)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: plan.recommended
                ? ElevatedButton(
                    onPressed: onChoose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Choose ${plan.name}',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  )
                : OutlinedButton(
                    onPressed: onChoose,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Choose ${plan.name}',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Top-bar button: a white "Upgrade" pill, or an icon on narrow phones.
class UpgradeAppBarButton extends StatelessWidget {
  const UpgradeAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 460;

    if (compact) {
      return IconButton(
        tooltip: 'Upgrade',
        onPressed: () => UpgradeSheet.show(context),
        icon: const Icon(Icons.workspace_premium_outlined),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ElevatedButton.icon(
        onPressed: () => UpgradeSheet.show(context),
        icon: const Icon(Icons.workspace_premium_outlined, size: 18),
        label: Text(
          'Upgrade',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: const Size(0, 36),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

/// Shown at the top of the side navigation rail on wide screens.
class UpgradeRailButton extends StatelessWidget {
  const UpgradeRailButton({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => UpgradeSheet.show(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accent,
                child: const Icon(Icons.workspace_premium_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                'Upgrade',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for the Profile tab.
class UpgradeCard extends StatelessWidget {
  const UpgradeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.primaryColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
          color: accent.withValues(alpha: isDark ? 0.12 : 0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.workspace_premium_outlined, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to a full plan',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Keep using StockSense after your free trial with Entry, Mid or High.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => UpgradeSheet.show(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('Upgrade',
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
