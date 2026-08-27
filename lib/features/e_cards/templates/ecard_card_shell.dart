import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart'; // ✅ THIS is where EcardOccasion lives

class EcardCardShell extends StatelessWidget {
  final EcardOccasion occasion;
  final Widget child;
  final String? qrData;
  final Color? accentOverride;
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
        return const Color(0xFFC1694F);
      case EcardOccasion.worship:
        return const Color(0xFF5B4B8A);
      case EcardOccasion.conference:
        return const Color(0xFF1B2A4A);
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
            color: const Color(0xFFC9A44C).withValues(alpha: 0.65),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: _accent.withValues(alpha: 0.22),
              blurRadius: 48,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFFFDF9),
                    const Color(0xFFFAF6EE),
                    _accent.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
            if (background != null) Positioned.fill(child: background!),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFC9A44C).withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              child: Column(
                children: [
                  Expanded(child: child),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'OFFICIAL E-INVITATION',
                              style: GoogleFonts.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: _accent.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'www.lideh.co.tz',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: const Color(0xFF2A201C),
                              ),
                            ),
                          ],
                        ),
                        _QrCorner(accent: _accent, qrData: qrData),
                      ],
                    ),
                  ),
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Icon(
          Icons.qr_code_2_rounded,
          color: accent.withValues(alpha: 0.6),
          size: 26,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFC9A44C).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child:
          QrImageView(data: qrData!, size: 42, backgroundColor: Colors.white),
    );
  }
}

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
