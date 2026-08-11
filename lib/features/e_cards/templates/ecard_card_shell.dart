import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart';

/// Shared visual chrome for every occasion's card design — background
/// gradient keyed to the occasion, consistent padding/rounding, and
/// the QR corner. Occasion-specific templates (wedding/worship/
/// conference) supply only their content via [child]; this keeps a
/// 4th/5th occasion's template to "new content builder", never a
/// rewrite of the card shape itself.
class EcardCardShell extends StatelessWidget {
  final EcardOccasion occasion;
  final Widget child;

  /// The QR payload for THIS card. Null when there's no guest yet
  /// (e.g. previewing a template before any guest exists) — shows a
  /// placeholder box instead of generating a code for nothing.
  final String? qrData;

  const EcardCardShell({super.key, required this.occasion, required this.child, this.qrData});

  Color get _accent {
    switch (occasion) {
      case EcardOccasion.wedding:
        return const Color(0xFFB76E79); // dusty rose
      case EcardOccasion.worship:
        return AppColors.primary;
      case EcardOccasion.conference:
        return AppColors.secondary;
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accent.withValues(alpha: 0.25), width: 1.5),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_accent.withValues(alpha: 0.08), AppColors.surface],
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.all(20),
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
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Icon(Icons.qr_code_2_rounded, color: accent.withValues(alpha: 0.5), size: 32),
      );
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: accent.withValues(alpha: 0.3))),
      child: QrImageView(data: qrData!, size: 64, backgroundColor: Colors.white),
    );
  }
}

/// Formats a stored field value for display: dates typed as ISO
/// strings (yyyy-mm-dd) render as "12 Jan 2027"; everything else
/// passes through unchanged. Kept forgiving on purpose since
/// Ecard.fields is a loose map, not a typed model — a malformed date
/// string just falls back to showing itself.
String formatEcardFieldValue(String key, dynamic value) {
  final str = '$value';
  final looksLikeDate = key.contains('date') && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(str);
  if (!looksLikeDate) return str;
  try {
    final d = DateTime.parse(str);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  } catch (_) {
    return str;
  }
}
