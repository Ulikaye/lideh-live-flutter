import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ecard.dart';
import 'ecard_card_shell.dart';

class WeddingCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const WeddingCardTemplate({super.key, required this.ecard, this.guestName, this.qrData});

  @override
  Widget build(BuildContext context) {
    final f = ecard.fields;
    return EcardCardShell(
      occasion: ecard.occasion,
      qrData: qrData,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PhotoCircle(url: f['bride_image_url'] as String?),
              const SizedBox(width: 12),
              const Icon(Icons.favorite, color: Color(0xFFB76E79), size: 20),
              const SizedBox(width: 12),
              _PhotoCircle(url: f['groom_image_url'] as String?),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${f['bride_name'] ?? ''} & ${f['groom_name'] ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'serif'),
          ),
          const SizedBox(height: 4),
          const Text('request the pleasure of your company', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          if (f['wedding_date'] != null) Text(formatEcardFieldValue('wedding_date', f['wedding_date']), style: const TextStyle(fontWeight: FontWeight.w600)),
          if (f['venue'] != null) ...[
            const SizedBox(height: 4),
            Text('${f['venue']}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          ],
          if (guestName != null) ...[
            const SizedBox(height: 16),
            Text('Dear $guestName', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

class _PhotoCircle extends StatelessWidget {
  final String? url;
  const _PhotoCircle({this.url});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.border,
      backgroundImage: (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
      child: (url == null || url!.isEmpty) ? const Icon(Icons.person_outline, color: AppColors.textSecondary) : null,
    );
  }
}
