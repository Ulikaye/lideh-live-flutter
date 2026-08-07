import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Drop-in replacement for [Icon] backed by a custom PNG asset instead
/// of a Material glyph. Reads the ambient [IconTheme] for color/size
/// when not explicitly overridden — exactly how [Icon] itself behaves
/// — so a custom icon placed inside a NavigationBar/NavigationRail
/// destination still picks up the correct selected/unselected tint
/// automatically, rather than being stuck at one fixed color.
///
/// Assets live in assets/icons/ as flat black-on-transparent PNGs;
/// tinting is done via BlendMode.srcIn, which recolors every opaque
/// pixel while preserving the original alpha/antialiasing shape.
class AppIconAsset extends StatelessWidget {
  final String name;
  final double? size;
  final Color? color;

  const AppIconAsset(this.name, {super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 24;
    final resolvedColor = color ?? iconTheme.color ?? AppColors.textPrimary;

    return Image.asset(
      'assets/icons/$name.png',
      width: resolvedSize,
      height: resolvedSize,
      color: resolvedColor,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (context, error, stackTrace) {
        // Falls back gracefully if an icon file is ever missing,
        // instead of crashing the whole screen.
        return Icon(Icons.image_not_supported_outlined, size: resolvedSize, color: resolvedColor);
      },
    );
  }
}
