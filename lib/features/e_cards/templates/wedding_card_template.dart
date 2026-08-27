import '../../../models/ecard.dart'; // for Ecard model
import 'ecard_card_shell.dart';
import 'ecard_decorations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class WeddingCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const WeddingCardTemplate({
    super.key,
    required this.ecard,
    this.guestName,
    this.qrData,
  });

  static const _mustard = Color(0xFFC99A2E);
  static const _coral = Color(0xFFE8927C);
  static const _teal = Color(0xFF3F6E5B);
  static const _pink = Color(0xFFD98BB9);
  static const _ink = Color(0xFF32231B);
  static const _inkSoft = Color(0xFF7A6253);

  @override
  Widget build(BuildContext context) {
    final f = ecard.fields;
    return EcardCardShell(
      occasion: ecard.occasion,
      qrData: qrData,
      accentOverride: const Color(0xFFC1694F),
      background:
          const WeddingFloralFrame(palette: [_mustard, _coral, _teal, _pink]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 6),
          Text(
            'PLEASE JOIN US FOR THE WEDDING OF',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _mustard,
              letterSpacing: 3.5,
            ),
          ),
          const SizedBox(height: 12),

          // Dual Bride & Groom Photo Avatars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PhotoCircle(url: f['bride_image_url'] as String?, isBride: true),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _coral.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: _coral, size: 20),
                ),
              ),
              _PhotoCircle(
                  url: f['groom_image_url'] as String?, isBride: false),
            ],
          ),
          const SizedBox(height: 16),

          // Names in High-Luxury Typography
          Text(
            '${f['bride_name'] ?? ''} & ${f['groom_name'] ?? ''}',
            textAlign: TextAlign.center,
            style: GoogleFonts.greatVibes(
              fontSize: 38,
              color: _ink,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'request the honour of your presence',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 14,
              color: _inkSoft,
              letterSpacing: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),

          // Gold Floral Divider
          Row(
            children: [
              Expanded(
                  child: Divider(
                      color: _mustard.withValues(alpha: 0.5), thickness: 0.8)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.local_florist, color: _teal, size: 16),
              ),
              Expanded(
                  child: Divider(
                      color: _mustard.withValues(alpha: 0.5), thickness: 0.8)),
            ],
          ),
          const SizedBox(height: 12),

          // Wedding Date & Venue Details
          if (f['wedding_date'] != null)
            Text(
              formatEcardFieldValue('wedding_date', f['wedding_date'])
                  .toUpperCase(),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ink,
                letterSpacing: 2,
              ),
            ),
          if (f['venue'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${f['venue']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _inkSoft,
              ),
            ),
          ],
          if (guestName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _mustard.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Honoured Guest: $guestName',
                style: GoogleFonts.cormorantGaramond(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: _ink,
                ),
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
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: ringColors),
        boxShadow: [
          BoxShadow(
            color: ringColors.first.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 34,
        backgroundColor: const Color(0xFFFFFBF5),
        backgroundImage:
            (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
        child: (url == null || url!.isEmpty)
            ? Icon(
                isBride ? Icons.female : Icons.male,
                color: AppColors.border,
                size: 34,
              )
            : null,
      ),
    );
  }
}
