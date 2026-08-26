import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ecard.dart';
import 'ecard_card_shell.dart';
import 'ecard_decorations.dart';

class WorshipCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const WorshipCardTemplate(
      {super.key, required this.ecard, this.guestName, this.qrData});

  static const _plum = Color(0xFF5B4B8A);
  static const _plumDeep = Color(0xFF382B5C);
  static const _gold = Color(0xFFC9A44C);
  static const _plumSoft = Color(0xFF8577AC);

  @override
  Widget build(BuildContext context) {
    final f = ecard.fields;
    return EcardCardShell(
      occasion: ecard.occasion,
      qrData: qrData,
      accentOverride: _plum,
      background: const _WorshipBackground(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 74), // clears the radiant cross art above
          if (f['church_name'] != null)
            Text(
              '${f['church_name']}'.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _gold,
                letterSpacing: 2.4,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '${f['service_title'] ?? ''}',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _plumDeep,
              shadows: [
                Shadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
          ),
          if (f['theme'] != null) ...[
            const SizedBox(height: 5),
            Text(
              '"${f['theme']}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: _plumSoft,
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Decorative divider
          Row(
            children: [
              Expanded(
                child: Divider(color: _gold.withValues(alpha: 0.35)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.brightness_1, color: _gold, size: 7),
              ),
              Expanded(
                child: Divider(color: _gold.withValues(alpha: 0.35)),
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
                color: _plumDeep,
              ),
            ),
          if (f['time'] != null)
            Text(
              '${f['time']}',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                color: _plumSoft,
              ),
            ),
          if (f['venue'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${f['venue']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                color: _plumSoft,
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
                color: _plumSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The radiant cross up top plus quiet laurel sprigs in the lower
/// corners — composed once here so the shell's `background` slot
/// only needs a single widget.
class _WorshipBackground extends StatelessWidget {
  const _WorshipBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: const Alignment(0, -0.78),
          child: SizedBox(
            width: 92,
            height: 92,
            child: CustomPaint(
              painter: RadiantCrossPainter(
                crossColor: WorshipCardTemplate._gold,
                rayColor: WorshipCardTemplate._plum.withValues(alpha: 0.28),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -6,
          left: -6,
          child: LaurelSprig(color: WorshipCardTemplate._plum),
        ),
        Positioned(
          bottom: -6,
          right: -6,
          child: LaurelSprig(color: WorshipCardTemplate._gold, flip: true),
        ),
      ],
    );
  }
}
