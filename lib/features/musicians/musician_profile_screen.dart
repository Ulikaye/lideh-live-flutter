import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/responsive.dart';
import '../../models/musician.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/musician_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/star_rating.dart';
import '../../shared/widgets/verified_badge.dart';

class MusicianProfileScreen extends ConsumerWidget {
  final String musicianId;
  const MusicianProfileScreen({super.key, required this.musicianId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicianAsync = ref.watch(musicianByIdProvider(musicianId));
    final currentProfile = ref.watch(currentUserProfileProvider).value;
    final isOrganizer = currentProfile?.userType == UserType.organizer;

    return Scaffold(
      appBar: AppBar(title: const Text('Musician Profile')),
      body: musicianAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load profile'),
        data: (musician) {
          if (musician == null) {
            return const EmptyStateWidget(title: 'Musician not found', icon: Icons.person_off_outlined);
          }
          return SingleChildScrollView(
            child: CenteredContent(
              child: Responsive.isDesktopOrTablet(context)
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _ProfileHeader(musician: musician)),
                        const SizedBox(width: 32),
                        Expanded(flex: 1, child: _BookingSidebar(musicianId: musicianId, isOrganizer: isOrganizer)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeader(musician: musician),
                        const SizedBox(height: 24),
                        _BookingSidebar(musicianId: musicianId, isOrganizer: isOrganizer),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final Musician musician;
  const _ProfileHeader({required this.musician});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(_reviewsProvider(musician.uid));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                musician.stageName.isNotEmpty ? musician.stageName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 32),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(musician.stageName, style: Theme.of(context).textTheme.headlineSmall, overflow: TextOverflow.ellipsis),
                      ),
                      if (musician.verified) ...[
                        const SizedBox(width: 6),
                        const VerifiedBadge(size: 20),
                      ],
                    ],
                  ),
                  if (musician.location != null)
                    Text(musician.location!, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  StarRatingDisplay(rating: musician.avgRating, reviewCount: musician.reviewCount),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (musician.skills.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: musician.skills.map<Widget>((s) => Chip(label: Text(s))).toList()),
        const SizedBox(height: 20),
        if (musician.availabilityNotes != null) ...[
          Text('Availability', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(musician.availabilityNotes!),
          const SizedBox(height: 20),
        ],
        if (musician.youtubeVideoId != null) ...[
          Text('Video', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _VideoLinkCard(youtubeId: musician.youtubeVideoId!),
          const SizedBox(height: 20),
        ],
        Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        reviewsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Could not load reviews'),
          data: (reviews) {
            if (reviews.isEmpty) return const Text('No reviews yet.', style: TextStyle(color: AppColors.textSecondary));
            return Column(children: reviews.map((r) => _ReviewTile(review: r)).toList());
          },
        ),
      ],
    );
  }
}

final _reviewsProvider = StreamProvider.family<List<Review>, String>((ref, musicianId) {
  return ref.watch(firestoreServiceProvider).watchReviewsForMusician(musicianId);
});

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StarRatingDisplay(rating: review.rating.toDouble(), size: 14),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review.comment!),
            ],
          ],
        ),
      ),
    );
  }
}

class _VideoLinkCard extends StatelessWidget {
  final String youtubeId;
  const _VideoLinkCard({required this.youtubeId});

  @override
  Widget build(BuildContext context) {
    final url = 'https://www.youtube.com/watch?v=$youtubeId';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 36),
        title: const Text('Watch performance'),
        subtitle: const Text('Opens on YouTube'),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ),
    );
  }
}

class _BookingSidebar extends StatelessWidget {
  final String musicianId;
  final bool isOrganizer;
  const _BookingSidebar({required this.musicianId, required this.isOrganizer});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ready to book?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Send a booking request with your event details and this musician will respond directly.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isOrganizer ? () => context.go('/bookings/create/$musicianId') : null,
              child: const Text('Request Booking'),
            ),
            if (!isOrganizer) ...[
              const SizedBox(height: 8),
              const Text('Only organizer accounts can send booking requests.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
