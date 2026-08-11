import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart';
import '../../../models/ecard.dart';
import 'conference_card_template.dart';
import 'ecard_card_shell.dart';
import 'wedding_card_template.dart';
import 'worship_card_template.dart';

/// Renders the right visual card for an Ecard's occasion. This is the
/// one place a 5th/6th occasion needs to be registered — everywhere
/// else (create flow, detail screen) just calls EcardPreview and never
/// switches on occasion itself.
class EcardPreview extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const EcardPreview({super.key, required this.ecard, this.guestName, this.qrData});

  @override
  Widget build(BuildContext context) {
    switch (ecard.occasion) {
      case EcardOccasion.wedding:
        return WeddingCardTemplate(ecard: ecard, guestName: guestName, qrData: qrData);
      case EcardOccasion.worship:
        return WorshipCardTemplate(ecard: ecard, guestName: guestName, qrData: qrData);
      case EcardOccasion.conference:
        return ConferenceCardTemplate(ecard: ecard, guestName: guestName, qrData: qrData);
      case EcardOccasion.other:
        return _GenericCardTemplate(ecard: ecard, guestName: guestName, qrData: qrData);
    }
  }
}

/// Fallback for EcardOccasion.other and any occasion without a
/// dedicated design yet — just lists whatever fields are present.
class _GenericCardTemplate extends StatelessWidget {
  final Ecard ecard;
  final String? guestName;
  final String? qrData;
  const _GenericCardTemplate({required this.ecard, this.guestName, this.qrData});

  @override
  Widget build(BuildContext context) {
    return EcardCardShell(
      occasion: ecard.occasion,
      qrData: qrData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_outlined, color: AppColors.primaryDark, size: 28),
          const SizedBox(height: 12),
          Text('${ecard.fields['title'] ?? 'Invitation'}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final entry in ecard.fields.entries)
            if (entry.key != 'title')
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${entry.value}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
          if (guestName != null) ...[
            const SizedBox(height: 12),
            Text('Dear $guestName', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
