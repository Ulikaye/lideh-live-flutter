import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Renders the app's real logo (assets/images/logo.png). Falls back to
/// a simple icon if the asset is ever missing, so a bad build never
/// crashes on this — just looks plain instead.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: size,
      width: size,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.music_note_rounded, color: AppColors.primary, size: size);
      },
    );
  }
}
