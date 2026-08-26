import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ecard.dart';
import 'ecard_card_shell.dart';
import 'ecard_decorations.dart';

class WeddingCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const WeddingCardTemplate(
      {super.key, required this.ecard, this.guestName, this.qrData});

  static const _mustard = Color(0xFFC99A2E);
  static const _coral = Color(0xFFE8927C);
  static const _teal = Color(0xFF3F6E5B);
  static const _pink = Color(0xFFD98BB9);
  static const _ink = Color(0xFF4A362B);
  static const _inkSoft = Color(0xFF8A6F5E);

  @override
  Widget build(BuildContext context) {
    final f = ecard.fields;
    return EcardCardShell(
      occasion: ecard.occasion,
      qrData: qrData,
      accentOverride: const Color(0xFFC1694F), // warm terracotta rose
      background:
          const WeddingFloralFrame(palette: [_mustard, _coral, _teal, _pink]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PLEASE JOIN US FOR A',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _inkSoft,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          // Photo circles with a warm gradient ring
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PhotoCircle(url: f['bride_image_url'] as String?, isBride: true),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.favorite, color: _coral, size: 22),
              ),
              _PhotoCircle(
                  url: f['groom_image_url'] as String?, isBride: false),
            ],
          ),
          const SizedBox(height: 18),
          // Names in elegant script
          Text(
            '${f['bride_name'] ?? ''} & ${f['groom_name'] ?? ''}',
            textAlign: TextAlign.center,
            style: GoogleFonts.greatVibes(
              fontSize: 36,
              color: _ink,
              shadows: [
                Shadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'request the honour of your presence',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 14,
              color: _inkSoft,
              letterSpacing: 1.2,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          // Decorative divider
          Row(
            children: [
              Expanded(
                child: Divider(color: _mustard.withValues(alpha: 0.45)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.local_florist, color: _teal, size: 18),
              ),
              Expanded(
                child: Divider(color: _mustard.withValues(alpha: 0.45)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Date and venue
          if (f['wedding_date'] != null)
            Text(
              formatEcardFieldValue('wedding_date', f['wedding_date'])
                  .toUpperCase(),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _ink,
                letterSpacing: 1,
              ),
            ),
          if (f['venue'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${f['venue']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                color: _inkSoft,
              ),
            ),
          ],
          if (guestName != null) ...[
            const SizedBox(height: 14),
            Text(
              'Dear $guestName',
              style: GoogleFonts.cormorantGaramond(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: _inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoCircle extends StatelessWidget {
  final String? url;
  final bool isBride;
  const _PhotoCircle({this.url, required this.isBride});

  @override
  Widget build(BuildContext context) {
    final ringColors = isBride
        ? [WeddingCardTemplate._pink, WeddingCardTemplate._coral]
        : [WeddingCardTemplate._mustard, WeddingCardTemplate._teal];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: ringColors),
        boxShadow: [
          BoxShadow(
            color: ringColors.first.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 32,
        backgroundColor: const Color(0xFFFFFBF5),
        backgroundImage:
            (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
        child: (url == null || url!.isEmpty)
            ? Icon(
                isBride ? Icons.female : Icons.male,
                color: AppColors.border,
                size: 32,
              )
            : null,
      ),
    );
  }
}
