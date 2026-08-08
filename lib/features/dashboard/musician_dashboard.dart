import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/musician_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/notification_bell_button.dart';
import '../../shared/widgets/profile_menu_button.dart';
import '../../shared/widgets/star_rating.dart';
import '../bookings/widgets/booking_card.dart';

/// Musician's operational home base: everything needed to manage
/// incoming booking requests without leaving one screen, mirroring the
/// original Django musician dashboard.
class MusicianDashboard extends ConsumerStatefulWidget {
  const MusicianDashboard({super.key});

  @override
  ConsumerState<MusicianDashboard> createState() => _MusicianDashboardState();
}

class _MusicianDashboardState extends ConsumerState<MusicianDashboard> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).value;
    if (profile == null) return const LoadingIndicator();

    final bookingsAsync = ref.watch(bookingsForMusicianProvider(profile.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Musician Dashboard'),
        actions: const [NotificationBellButton(), ProfileMenuButton(), SizedBox(width: 8)],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Pending'), Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
      ),
      body: Column(
        children: [
          _MusicianDetailsSummaryCard(uid: profile.uid),
          Expanded(
            child: bookingsAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => AppErrorWidget(message: 'Could not load bookings'),
              data: (bookings) {
                final pending = bookings.where((b) => b.status == BookingStatus.pending).toList();
                final upcoming = bookings.where((b) => b.status == BookingStatus.accepted).toList();
                final past = bookings.where((b) => b.status == BookingStatus.completed || b.status == BookingStatus.declined || b.status == BookingStatus.cancelled).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _BookingListTab(bookings: pending, emptyText: 'No pending requests'),
                    _BookingListTab(bookings: upcoming, emptyText: 'No upcoming bookings'),
                    _BookingListTab(bookings: past, emptyText: 'No past bookings'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact summary of the musician's own professional details, with a
/// clear "Edit" action — makes the previously-hidden edit screen
/// actually discoverable, rather than burying it behind a small icon
/// nobody would think to tap.
class _MusicianDetailsSummaryCard extends ConsumerWidget {
  final String uid;
  const _MusicianDetailsSummaryCard({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicianAsync = ref.watch(musicianByIdProvider(uid));

    return musicianAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (musician) {
        if (musician == null) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    musician.stageName.isNotEmpty ? musician.stageName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(musician.stageName, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      StarRatingDisplay(rating: musician.avgRating, reviewCount: musician.reviewCount, size: 13),
                      const SizedBox(height: 4),
                      Text(
                        musician.startingPrice != null ? 'From \$${musician.startingPrice!.toStringAsFixed(0)} · ${musician.skills.length} skill(s) listed' : 'No price set yet',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/musician-details/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BookingListTab extends StatelessWidget {
  final List<Booking> bookings;
  final String emptyText;
  const _BookingListTab({required this.bookings, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyStateWidget(title: emptyText, icon: Icons.event_note_outlined);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => BookingCard(booking: bookings[i]),
        ),
      ),
    );
  }
}
