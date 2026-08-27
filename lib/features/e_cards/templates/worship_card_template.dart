import '../../../models/ecard.dart'; // for Ecard model
import 'ecard_card_shell.dart';
import 'ecard_decorations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WorshipCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const WorshipCardTemplate({
    super.key,
    required this.ecard,
    this.guestName,
    this.qrData,
  });

  static const _plum = Color(0xFF5B4B8A);
  static const _plumDeep = Color(0xFF2C1F4A);
  static const _gold = Color(0xFFC9A44C);
  static const _plumSoft = Color(0xFF75659B);

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
          const SizedBox(height: 64),
          if (f['church_name'] != null)
            Text(
              '${f['church_name']}'.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _gold,
                letterSpacing: 3.0,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            '${f['service_title'] ?? ''}',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              color: _plumDeep,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          if (f['theme'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '"${f['theme']}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 15.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: _plumSoft,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: _gold.withValues(alpha: 0.45))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.brightness_5, color: _gold, size: 12),
              ),
              Expanded(child: Divider(color: _gold.withValues(alpha: 0.45))),
            ],
          ),
          const SizedBox(height: 14),
          if (f['date'] != null)
            Text(
              formatEcardFieldValue('date', f['date']),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _plumDeep,
              ),
            ),
          if (f['time'] != null)
            Text(
              '${f['time']}',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
            const SizedBox(height: 14),
            Text(
              'Dear $guestName',
              style: GoogleFonts.cormorantGaramond(
                fontStyle: FontStyle.italic,
                fontSize: 14.5,
                color: _plumDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorshipBackground extends StatelessWidget {
  const _WorshipBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: const Alignment(0, -0.80),
          child: SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: RadiantCrossPainter(
                crossColor: WorshipCardTemplate._gold,
                rayColor: WorshipCardTemplate._plum.withValues(alpha: 0.32),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -4,
          left: -4,
          child: LaurelSprig(color: WorshipCardTemplate._plum),
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: LaurelSprig(color: WorshipCardTemplate._gold, flip: true),
        ),
      ],
    );
  }
}
