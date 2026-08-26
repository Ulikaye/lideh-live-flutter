import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ecard.dart';
import 'ecard_card_shell.dart';
import 'ecard_decorations.dart';

class ConferenceCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const ConferenceCardTemplate(
      {super.key, required this.ecard, this.guestName, this.qrData});

  static const _navy = Color(0xFF1B2A4A);
  static const _navySoft = Color(0xFF4A5B78);
  static const _gold = Color(0xFFC9A44C);

  @override
  Widget build(BuildContext context) {
    final f = ecard.fields;
    return EcardCardShell(
      occasion: ecard.occasion,
      qrData: qrData,
      accentOverride: _navy,
      background: CustomPaint(
        painter: ConferenceAccentPainter(primary: _navy, accent: _gold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.groups_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            '${f['title'] ?? ''}',
            style: GoogleFonts.inter(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF15213A),
              letterSpacing: -0.4,
              height: 1.15,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 4),
            width: 34,
            height: 3,
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (f['organizer_name'] != null)
            Text(
              'Hosted by ${f['organizer_name']}',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: _navySoft,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (f['date'] != null)
                _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    text: formatEcardFieldValue('date', f['date'])),
              if (f['time'] != null)
                _InfoChip(icon: Icons.access_time_outlined, text: '${f['time']}'),
              if (f['venue'] != null)
                _InfoChip(
                    icon: Icons.location_on_outlined, text: '${f['venue']}'),
            ],
          ),
          if (f['description'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _navy.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _navy.withValues(alpha: 0.08)),
              ),
              child: Text(
                '${f['description']}',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: _navySoft,
                  height: 1.45,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (guestName != null) ...[
            const SizedBox(height: 14),
            Text(
              'Registered: $guestName',
              style: GoogleFonts.inter(
                fontStyle: FontStyle.italic,
                fontSize: 12.5,
                color: _navySoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ConferenceCardTemplate._navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: ConferenceCardTemplate._navy.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ConferenceCardTemplate._navy),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: ConferenceCardTemplate._navy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}