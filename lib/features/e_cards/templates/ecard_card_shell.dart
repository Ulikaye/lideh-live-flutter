import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart';

/// Shared visual chrome for every occasion's card design — background
/// gradient keyed to the occasion, consistent padding/rounding, and
/// the QR corner.
class EcardCardShell extends StatelessWidget {
  final EcardOccasion occasion;
  final Widget child;
  final String? qrData;
  final Color? accentOverride;

  const EcardCardShell({
    super.key,
    required this.occasion,
    required this.child,
    this.qrData,
    this.accentOverride,
  });

  Color get _accent {
    if (accentOverride != null) return accentOverride!;
    switch (occasion) {
      case EcardOccasion.wedding:
        return const Color(0xFFD4A5A5); // soft rose
      case EcardOccasion.worship:
        return const Color(0xFF6C5B7B); // deep lavender
      case EcardOccasion.conference:
        return const Color(0xFF2C3E50); // navy
      case EcardOccasion.other:
        return AppColors.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 5 / 7,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _accent.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.95),
              _accent.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(
            color: _accent.withValues(alpha: 0.3),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: _accent.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: child),
            const SizedBox(height: 12),
            _QrCorner(accent: _accent, qrData: qrData),
          ],
        ),
      ),
    );
  }
}

class _QrCorner extends StatelessWidget {
  final Color accent;
  final String? qrData;
  const _QrCorner({required this.accent, required this.qrData});

  @override
  Widget build(BuildContext context) {
    if (qrData == null) {
      return Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Icon(
          Icons.qr_code_2_rounded,
          color: accent.withValues(alpha: 0.5),
          size: 34,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child:
          QrImageView(data: qrData!, size: 68, backgroundColor: Colors.white),
    );
  }
}

/// Formats a stored field value for display.
String formatEcardFieldValue(String key, dynamic value) {
  final str = '$value';
  final looksLikeDate =
      key.contains('date') && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(str);
  if (!looksLikeDate) return str;
  try {
    final d = DateTime.parse(str);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  } catch (_) {
    return str;
  }
}
