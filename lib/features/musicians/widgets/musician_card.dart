import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/musician.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../shared/widgets/star_rating.dart';
import '../../../shared/widgets/verified_badge.dart';

class MusicianCard extends StatelessWidget {
  final Musician musician;
  const MusicianCard({super.key, required this.musician});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/musicians/${musician.uid}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      // ✅ Display the profile picture if available
                      backgroundImage: musician.photoURL != null &&
                              musician.photoURL!.isNotEmpty
                          ? NetworkImage(musician.photoURL!)
                          : null,
                      child: musician.photoURL == null ||
                              musician.photoURL!.isEmpty
                          ? Text(
                              musician.stageName.isNotEmpty
                                  ? musician.stageName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20),
                            )
                          : null, // No child when image is displayed
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  musician.stageName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (musician.verified) ...[
                                const SizedBox(width: 4),
                                const VerifiedBadge(size: 15),
                              ],
                            ],
                          ),
                          if (musician.location != null)
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 2),
                                Text(musician.location!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (musician.youtubeVideoId != null)
                      const Icon(Icons.play_circle_fill_rounded,
                          color: AppColors.primary, size: 22),
                  ],
                ),
                const SizedBox(height: 12),
                StarRatingDisplay(
                    rating: musician.avgRating,
                    reviewCount: musician.reviewCount,
                    size: 14),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: musician.skills
                      .take(3)
                      .map((s) => Chip(
                            label:
                                Text(s, style: const TextStyle(fontSize: 11)),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
                const Spacer(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (musician.startingPrice != null)
                      Text(
                          'From \$${musician.startingPrice!.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary))
                    else
                      const Text('Price on request',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    TextButton(
                      onPressed: () => context.go('/musicians/${musician.uid}'),
                      child: const Text('View Profile'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
