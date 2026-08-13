import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ecard.dart';
import 'ecard_card_shell.dart';

class WorshipCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const WorshipCardTemplate(
      {super.key, required this.ecard, this.guestName, this.qrData});

  @override
  Widget build(BuildContext context) {
    final f = ecard.fields;
    return EcardCardShell(
      occasion: ecard.occasion,
      qrData: qrData,
      accentOverride: const Color(0xFF6C5B7B), // deep lavender
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.church, color: Color(0xFF6C5B7B), size: 36),
          const SizedBox(height: 12),
          if (f['church_name'] != null)
            Text(
              '${f['church_name']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6C5B7B),
                letterSpacing: 2,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            '${f['service_title'] ?? ''}',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3E2C4B),
              shadows: [
                Shadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
          ),
          if (f['theme'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '"${f['theme']}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF8E7A9A),
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Decorative cross divider
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: const Color(0xFF6C5B7B).withValues(alpha: 0.25),
                  thickness: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.circle, color: Color(0xFF6C5B7B), size: 8),
              ),
              Expanded(
                child: Divider(
                  color: const Color(0xFF6C5B7B).withValues(alpha: 0.25),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (f['date'] != null)
            Text(
              formatEcardFieldValue('date', f['date']),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3E2C4B),
              ),
            ),
          if (f['time'] != null)
            Text(
              '${f['time']}',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                color: const Color(0xFF6C5B7B),
              ),
            ),
          if (f['venue'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${f['venue']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                color: const Color(0xFF6C5B7B),
              ),
            ),
          ],
          if (guestName != null) ...[
            const SizedBox(height: 16),
            Text(
              'Dear $guestName',
              style: GoogleFonts.cormorantGaramond(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: const Color(0xFF6C5B7B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
