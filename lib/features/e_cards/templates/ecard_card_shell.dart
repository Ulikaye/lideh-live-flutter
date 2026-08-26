import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart';

/// Shared visual chrome for every occasion's card design — background,
/// consistent padding/rounding, an optional decorative [background]
/// layer (florals, cross, geometric accent — see ecard_decorations.dart),
/// and the QR corner.
class EcardCardShell extends StatelessWidget {
  final EcardOccasion occasion;
  final Widget child;
  final String? qrData;
  final Color? accentOverride;

  /// Optional decorative layer painted behind [child] and above the
  /// background gradient, e.g. a [WeddingFloralFrame] or radiant
  /// cross. Purely visual — has no effect on layout or data.
  final Widget? background;

  const EcardCardShell({
    super.key,
    required this.occasion,
    required this.child,
    this.qrData,
    this.accentOverride,
    this.background,
  });

  Color get _accent {
    if (accentOverride != null) return accentOverride!;
    switch (occasion) {
      case EcardOccasion.wedding:
        return const Color(0xFFC1694F); // warm terracotta rose
      case EcardOccasion.worship:
        return const Color(0xFF5B4B8A); // rich plum
      case EcardOccasion.conference:
        return const Color(0xFF1B2A4A); // deep navy
      case EcardOccasion.other:
        return AppColors.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 5 / 7,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _accent.withValues(alpha: 0.35),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 14),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: _accent.withValues(alpha: 0.18),
              blurRadius: 44,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Warm, near-cream base so decorative colors stay the
            // star of the card instead of a tinted wash.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFFDF8),
                    const Color(0xFFFFFDF8),
                    _accent.withValues(alpha: 0.07),
                  ],
                ),
              ),
            ),
            if (background != null) Positioned.fill(child: background!),
            // A slim inner hairline keeps the decorative corners from
            // ever looking like they bleed off the card edge.
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _accent.withValues(alpha: 0.16),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Icon(
          Icons.qr_code_2_rounded,
          color: accent.withValues(alpha: 0.5),
          size: 32,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child:
          QrImageView(data: qrData!, size: 64, backgroundColor: Colors.white),
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
