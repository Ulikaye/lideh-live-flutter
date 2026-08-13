import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ecard.dart';
import 'ecard_card_shell.dart';

class WeddingCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const WeddingCardTemplate(
      {super.key, required this.ecard, this.guestName, this.qrData});

  @override
  Widget build(BuildContext context) {
    final f = ecard.fields;
    return EcardCardShell(
      occasion: ecard.occasion,
      qrData: qrData,
      accentOverride: const Color(0xFFD4A5A5), // soft rose for the shell
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decorative top icon
          const Icon(Icons.auto_awesome, color: Color(0xFFD4A5A5), size: 28),
          const SizedBox(height: 8),
          // Photo circles with gold border
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PhotoCircle(url: f['bride_image_url'] as String?, isBride: true),
              const SizedBox(width: 16),
              const Icon(Icons.favorite, color: Color(0xFFD4A5A5), size: 24),
              const SizedBox(width: 16),
              _PhotoCircle(
                  url: f['groom_image_url'] as String?, isBride: false),
            ],
          ),
          const SizedBox(height: 20),
          // Names in elegant script
          Text(
            '${f['bride_name'] ?? ''} & ${f['groom_name'] ?? ''}',
            textAlign: TextAlign.center,
            style: GoogleFonts.greatVibes(
              fontSize: 32,
              color: const Color(0xFF5D4037),
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
              color: const Color(0xFF8D6E63),
              letterSpacing: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
          // Decorative divider
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: const Color(0xFFD4A5A5).withValues(alpha: 0.5),
                  thickness: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.local_florist,
                    color: Color(0xFFD4A5A5), size: 18),
              ),
              Expanded(
                child: Divider(
                  color: const Color(0xFFD4A5A5).withValues(alpha: 0.5),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date and venue
          if (f['wedding_date'] != null)
            Text(
              formatEcardFieldValue('wedding_date', f['wedding_date']),
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5D4037),
              ),
            ),
          if (f['venue'] != null) ...[
            const SizedBox(height: 4),
            Text(
              '${f['venue']}',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14,
                color: const Color(0xFF8D6E63),
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
                color: const Color(0xFF8D6E63),
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
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD4A5A5), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A5A5).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 34,
        backgroundColor: AppColors.border,
        backgroundImage:
            (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
        child: (url == null || url!.isEmpty)
            ? Icon(
                isBride ? Icons.female : Icons.male,
                color: Colors.grey.shade400,
                size: 34,
              )
            : null,
      ),
    );
  }
}
