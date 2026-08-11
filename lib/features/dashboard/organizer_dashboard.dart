import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/event_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/notification_bell_button.dart';
import '../../shared/widgets/profile_menu_button.dart';
import '../bookings/widgets/booking_card.dart';

/// Organizer's operational home base: their booking requests plus the
/// events they've published, mirroring the original Django organizer
/// dashboard's two core responsibilities.
class OrganizerDashboard extends ConsumerStatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  ConsumerState<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends ConsumerState<OrganizerDashboard> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).value;
    if (profile == null) return const LoadingIndicator();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Dashboard'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'My Bookings'), Tab(text: 'My Events')]),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: 'New Event', onPressed: () => context.go('/events/create')),
          const NotificationBellButton(),
          const ProfileMenuButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _ServicesRow(onEventsTap: () => _tabController.animateTo(1)),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BookingsTab(organizerId: profile.uid),
                _EventsTab(organizerId: profile.uid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Services row (Musician Booking / Events / E-Cards), added above the
/// existing My Bookings / My Events tabs — additive only, the
/// TabController and its two tabs are untouched. "Events" jumps to the
/// My Events tab already on this screen; "Musician Booking" goes to
/// discovery; "E-Cards" is the new service.
class _ServicesRow extends StatelessWidget {
  final VoidCallback onEventsTap;
  const _ServicesRow({required this.onEventsTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _ServiceTile(
              icon: Icons.library_music_outlined,
              label: 'Musician Booking',
              onTap: () => context.go('/musicians'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ServiceTile(icon: Icons.event_outlined, label: 'Events', onTap: onEventsTap),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ServiceTile(
              icon: Icons.mail_outline_rounded,
              label: 'E-Cards',
              onTap: () => context.go('/e-cards'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ServiceTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingsTab extends ConsumerWidget {
  final String organizerId;
  const _BookingsTab({required this.organizerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsForOrganizerProvider(organizerId));
    return bookingsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => AppErrorWidget(message: 'Could not load bookings'),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const EmptyStateWidget(title: 'No bookings yet', subtitle: 'Requests you send will show up here', icon: Icons.event_note_outlined);
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
      },
    );
  }
}

class _EventsTab extends ConsumerWidget {
  final String organizerId;
  const _EventsTab({required this.organizerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsForOrganizerProvider(organizerId));
    return eventsAsync.when(
      loading: () => const LoadingIndicator(),
      error: (e, _) => AppErrorWidget(message: 'Could not load events'),
      data: (events) {
        if (events.isEmpty) {
          return const EmptyStateWidget(title: 'No events yet', subtitle: 'Publish your first event to get started', icon: Icons.event_outlined);
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final event = events[i];
                return Card(
                  child: ListTile(
                    title: Text(event.title),
                    subtitle: Text(event.location),
                    trailing: event.isCancelled
                        ? const Chip(label: Text('Cancelled'), backgroundColor: Color(0x1AE74C3C))
                        : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onTap: () => context.go('/events/${event.id}'),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
