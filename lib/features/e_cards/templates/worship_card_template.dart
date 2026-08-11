import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ecard.dart';
import 'ecard_card_shell.dart';

class WorshipCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const WorshipCardTemplate({super.key, required this.ecard, this.guestName, this.qrData});

  @override
  Widget build(BuildContext context) {
    final f = ecard.fields;
    return EcardCardShell(
      occasion: ecard.occasion,
      qrData: qrData,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.church_outlined, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          if (f['church_name'] != null)
            Text('${f['church_name']}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            '${f['service_title'] ?? ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          if (f['theme'] != null) ...[
            const SizedBox(height: 6),
            Text('"${f['theme']}"', textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          if (f['date'] != null) Text(formatEcardFieldValue('date', f['date']), style: const TextStyle(fontWeight: FontWeight.w600)),
          if (f['time'] != null) Text('${f['time']}', style: const TextStyle(color: AppColors.textSecondary)),
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
