import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/musician.dart';
import '../../../models/user_profile.dart';
import '../../../shared/widgets/star_rating.dart';

/// Profile summary shown at the top of the Musician Dashboard: avatar,
/// stage name, rating, and quick stats, with a shortcut into the full
/// edit-profile flow. Purely presentational — all data is passed in.
class MusicianProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final Musician? musician;

  const MusicianProfileHeader({super.key, required this.profile, this.musician});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final displayName = musician?.stageName.isNotEmpty == true ? musician!.stageName : (profile.displayName ?? profile.email);

    final avatar = CircleAvatar(
      radius: isMobile ? 32 : 40,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      backgroundImage: profile.profilePictureUrl != null ? CachedNetworkImageProvider(profile.profilePictureUrl!) : null,
      child: profile.profilePictureUrl == null
          ? Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: isMobile ? 22 : 28),
            )
          : null,
    );

    final nameAndMeta = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (profile.verified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
            ],
          ],
        ),
        const SizedBox(height: 4),
        StarRatingDisplay(rating: musician?.avgRating ?? 0, reviewCount: musician?.reviewCount ?? 0),
        if (musician?.location != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(musician!.location!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ],
    );

    final editButton = OutlinedButton.icon(
      onPressed: () => context.go('/profile/edit'),
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: const Text('Edit Profile'),
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.border)),
    );

    final stats = _StatsRow(musician: musician);

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [avatar, const SizedBox(width: 14), Expanded(child: nameAndMeta)]),
                    const SizedBox(height: 16),
                    stats,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: editButton),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    avatar,
                    const SizedBox(width: 18),
                    Expanded(child: nameAndMeta),
                    stats,
                    const SizedBox(width: 16),
                    editButton,
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Musician? musician;
  const _StatsRow({required this.musician});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatChip(label: 'Experience', value: musician?.yearsOfExperience != null ? '${musician!.yearsOfExperience} yrs' : '—'),
        const SizedBox(width: 10),
        _StatChip(
          label: 'From',
          value: musician?.startingPrice != null ? '\$${musician!.startingPrice!.toStringAsFixed(0)}' : '—',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
