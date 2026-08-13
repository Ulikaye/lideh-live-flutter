import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ecard.dart';
import 'ecard_card_shell.dart';

class ConferenceCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const ConferenceCardTemplate(
      {super.key, required this.ecard, this.guestName, this.qrData});

  @override
  Widget build(BuildContext context) {
    final f = ecard.fields;
    return EcardCardShell(
      occasion: ecard.occasion,
      qrData: qrData,
      accentOverride: const Color(0xFF2C3E50), // navy
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups_rounded, color: Color(0xFF2C3E50), size: 30),
          const SizedBox(height: 12),
          Text(
            '${f['title'] ?? ''}',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A2634),
              letterSpacing: -0.5,
            ),
          ),
          if (f['organizer_name'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Hosted by ${f['organizer_name']}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF4A5B6B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Info rows with improved icons and spacing
          if (f['date'] != null)
            _InfoRow(
                icon: Icons.calendar_today_outlined,
                text: formatEcardFieldValue('date', f['date'])),
          if (f['time'] != null)
            _InfoRow(icon: Icons.access_time_outlined, text: '${f['time']}'),
          if (f['venue'] != null)
            _InfoRow(icon: Icons.location_on_outlined, text: '${f['venue']}'),
          if (f['description'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${f['description']}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF4A5B6B),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (guestName != null) ...[
            const SizedBox(height: 16),
            Text(
              'Registered: $guestName',
              style: GoogleFonts.inter(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: const Color(0xFF4A5B6B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2C3E50)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF2C3E50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
