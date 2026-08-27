import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../models/booking.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ecard_provider.dart';
import '../../providers/event_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventByIdProvider(eventId));
    final profile = ref.watch(currentUserProfileProvider).value;
    final isMusician = profile?.userType == UserType.musician;
    final isOwner = profile != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: eventAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load event'),
        data: (event) {
          if (event == null)
            return const EmptyStateWidget(title: 'Event not found');
          final ownsThisEvent = isOwner && event.organizerId == profile!.uid;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Event poster
                            if (event.coverImageUrl != null &&
                                event.coverImageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  event.coverImageUrl!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(event.title,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 12),
                            _Row(
                                icon: Icons.calendar_today_outlined,
                                text: DateFormat('EEEE, MMM d, yyyy')
                                    .format(event.date)),
                            if (event.time != null)
                              _Row(
                                  icon: Icons.access_time_outlined,
                                  text: event.time!),
                            _Row(
                                icon: Icons.location_on_outlined,
                                text: event.location),
                            if (event.description != null &&
                                event.description!.isNotEmpty) ...[
                              const Divider(height: 24),
                              Text(event.description!),
                            ],
                            const SizedBox(height: 20),
                            if (isMusician)
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _applyToPerform(context, ref, event),
                                icon: const Icon(Icons.how_to_reg_outlined),
                                label: const Text('Apply to Perform'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (ownsThisEvent) ...[
                      // ✅ Edit Event button (added)
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/events/${event.id}/edit'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Event'),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: SwitchListTile(
                          value: event.isPublished,
                          onChanged: (value) => ref
                              .read(firestoreServiceProvider)
                              .updateEventPublished(event.id, value),
                          secondary: Icon(
                            event.isPublished
                                ? Icons.public
                                : Icons.drafts_outlined,
                            color: event.isPublished
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          title:
                              Text(event.isPublished ? 'Published' : 'Draft'),
                          subtitle: Text(
                            event.isPublished
                                ? 'Visible to everyone browsing events'
                                : 'Only visible to you — musicians and the public can\'t see it yet',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _EcardLinkCard(
                          organizerId: event.organizerId, eventId: event.id),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _applyToPerform(
      BuildContext context, WidgetRef ref, Event event) async {
    final musicianId = ref.read(authServiceProvider).currentUser!.uid;
    final booking = Booking(
      id: '',
      musicianId: musicianId,
      organizerId: event.organizerId,
      eventId: event.id,
      eventName: event.title,
      eventDate: event.date,
      eventTime: event.time,
      venue: event.location,
      message: 'I would like to apply to perform at this event.',
      status: BookingStatus.pending,
      createdBy: musicianId,
    );
    final id = await ref.read(firestoreServiceProvider).createBooking(booking);
    if (context.mounted) context.go('/bookings/$id');
  }
}

class _EcardLinkCard extends ConsumerWidget {
  final String organizerId;
  final String eventId;
  const _EcardLinkCard({required this.organizerId, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecardAsync = ref.watch(ecardForEventProvider((eventId, organizerId)));

    return ecardAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (ecard) {
        if (ecard != null) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.mail_outline_rounded,
                  color: AppColors.primary),
              title: const Text('E-Card'),
              subtitle: const Text('View, add guests, or scan check-ins'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/e-cards/${ecard.id}'),
            ),
          );
        }
        return Card(
          child: ListTile(
            leading: const Icon(Icons.mail_outline_rounded,
                color: AppColors.textSecondary),
            title: const Text('Create E-Card'),
            subtitle: const Text(
                'Add a digital invitation with guest management and QR check-in'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go('/e-cards/create?eventId=$eventId'),
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Row({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
