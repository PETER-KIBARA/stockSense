import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  /// Optional one-line explanation. Real information only, never decoration.
  final String? caption;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 140.0;

          final double iconBox, valueSize, titleSize, captionSize, pad;
          final bool showCaption;
          if (h >= 190) {
            iconBox = 44;
            valueSize = 28;
            titleSize = 14;
            captionSize = 12;
            pad = 18;
            showCaption = caption != null;
          } else if (h >= 150) {
            iconBox = 36;
            valueSize = 22;
            titleSize = 13;
            captionSize = 11;
            pad = 14;
            showCaption = caption != null;
          } else if (h >= 116) {
            iconBox = 36;
            valueSize = 20;
            titleSize = 12;
            captionSize = 11;
            pad = 14;
            showCaption = false;
          } else {
            iconBox = 28;
            valueSize = 18;
            titleSize = 11;
            captionSize = 10;
            pad = 10;
            showCaption = false;
          }

          return Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: iconBox * 0.55),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: valueSize,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
                if (showCaption) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: captionSize,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
