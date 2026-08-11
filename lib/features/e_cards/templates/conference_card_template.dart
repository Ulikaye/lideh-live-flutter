import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ecard.dart';
import 'ecard_card_shell.dart';

class ConferenceCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const ConferenceCardTemplate({super.key, required this.ecard, this.guestName, this.qrData});

  @override
  Widget build(BuildContext context) {
    final f = ecard.fields;
    return EcardCardShell(
      occasion: ecard.occasion,
      qrData: qrData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups_outlined, color: AppColors.secondary, size: 28),
          const SizedBox(height: 12),
          Text('${f['title'] ?? ''}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          if (f['organizer_name'] != null) ...[
            const SizedBox(height: 4),
            Text('Hosted by ${f['organizer_name']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          if (f['date'] != null) _InfoRow(icon: Icons.calendar_today_outlined, text: formatEcardFieldValue('date', f['date'])),
          if (f['time'] != null) _InfoRow(icon: Icons.access_time_outlined, text: '${f['time']}'),
          if (f['venue'] != null) _InfoRow(icon: Icons.location_on_outlined, text: '${f['venue']}'),
          if (f['description'] != null) ...[
            const SizedBox(height: 12),
            Text('${f['description']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
          if (guestName != null) ...[
            const SizedBox(height: 16),
            Text('Registered: $guestName', style: const TextStyle(fontStyle: FontStyle.italic)),
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
