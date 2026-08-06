import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Pending'), Tab(text: 'Upcoming'), Tab(text: 'Past')],
        ),
      ),
      body: bookingsAsync.when(
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
