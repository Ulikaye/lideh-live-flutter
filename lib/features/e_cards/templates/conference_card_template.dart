import '../../../models/ecard.dart'; // for Ecard model
import 'ecard_card_shell.dart';
import 'ecard_decorations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConferenceCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const ConferenceCardTemplate({
    super.key,
    required this.ecard,
    this.guestName,
    this.qrData,
  });

  static const _navy = Color(0xFF1B2A4A);
  static const _navySoft = Color(0xFF3F5170);
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_navy, Color(0xFF2C3E66)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.business_center_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            '${f['title'] ?? ''}',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 6),
            width: 40,
            height: 3.5,
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (f['organizer_name'] != null)
            Text(
              'Hosted by ${f['organizer_name']}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _navySoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (f['date'] != null)
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  text: formatEcardFieldValue('date', f['date']),
                ),
              if (f['time'] != null)
                _InfoChip(
                    icon: Icons.access_time_outlined, text: '${f['time']}'),
              if (f['venue'] != null)
                _InfoChip(
                    icon: Icons.location_on_outlined, text: '${f['venue']}'),
            ],
          ),
          if (f['description'] != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _navy.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _navy.withValues(alpha: 0.08)),
              ),
              child: Text(
                '${f['description']}',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: _navySoft,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (guestName != null) ...[
            const SizedBox(height: 10),
            Text(
              'Registered Attendee: $guestName',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: _navy,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: ConferenceCardTemplate._navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: ConferenceCardTemplate._navy.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: ConferenceCardTemplate._navy),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: ConferenceCardTemplate._navy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
