import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Read-only star rating display (used on musician cards/profiles).
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;

  const StarRatingDisplay({super.key, required this.rating, this.reviewCount = 0, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = i < rating.round();
          return Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.secondary, size: size);
        }),
        const SizedBox(width: 6),
        Text(
          reviewCount > 0 ? '${rating.toStringAsFixed(1)} ($reviewCount)' : 'New',
          style: TextStyle(fontSize: size * 0.8, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Interactive star picker (used in the review modal).
class StarRatingInput extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  const StarRatingInput({super.key, required this.rating, required this.onChanged, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return IconButton(
          onPressed: () => onChanged(i + 1),
          icon: Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.secondary, size: size),
        );
      }),
    );
  }
}
