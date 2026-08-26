import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'widgets/booking_card.dart';
import 'widgets/review_modal.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingByIdProvider(bookingId));
    final profile = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: bookingAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load booking'),
        data: (booking) {
          if (booking == null)
            return const EmptyStateWidget(title: 'Booking not found');

          final isMusician = profile?.userType == UserType.musician &&
              profile?.uid == booking.musicianId;
          final isOrganizer = profile?.userType == UserType.organizer &&
              profile?.uid == booking.organizerId;
          final isAdmin = profile?.userType == UserType.admin;

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(booking.eventName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor(booking.status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(booking.status.label,
                                      style: TextStyle(
                                          color: statusColor(booking.status),
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _DetailRow(
                                icon: Icons.calendar_today_outlined,
                                label: 'Date',
                                value: DateFormat('EEEE, MMM d, yyyy')
                                    .format(booking.eventDate)),
                            if (booking.eventTime != null)
                              _DetailRow(
                                  icon: Icons.access_time_outlined,
                                  label: 'Time',
                                  value: booking.eventTime!),
                            _DetailRow(
                                icon: Icons.location_on_outlined,
                                label: 'Venue',
                                value: booking.venue),
                            if (booking.contactPhone != null &&
                                booking.contactPhone!.isNotEmpty)
                              _DetailRow(
                                  icon: Icons.phone_outlined,
                                  label: 'Contact',
                                  value: booking.contactPhone!),
                            if (booking.message != null &&
                                booking.message!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text('Message',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(booking.message!),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isMusician) _MusicianActions(booking: booking),
                    if (isOrganizer) _OrganizerActions(booking: booking),
                    if (isMusician || isOrganizer || isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.go('/bookings/${booking.id}/chat'),
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Open Chat'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _MusicianActions extends ConsumerWidget {
  final Booking booking;
  const _MusicianActions({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.read(firestoreServiceProvider);
    switch (booking.status) {
      case BookingStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    firestore.updateBookingStatus(booking.id, 'declined'),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () =>
                    firestore.updateBookingStatus(booking.id, 'accepted'),
                child: const Text('Accept'),
              ),
            ),
          ],
        );
      case BookingStatus.accepted:
        return ElevatedButton(
          onPressed: () =>
              firestore.updateBookingStatus(booking.id, 'completed'),
          child: const Text('Mark as Completed'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _OrganizerActions extends ConsumerWidget {
  final Booking booking;
  const _OrganizerActions({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (booking.status == BookingStatus.completed && !booking.reviewSubmitted) {
      return ElevatedButton.icon(
        onPressed: () => showReviewModal(context, ref, booking),
        icon: const Icon(Icons.star_outline_rounded),
        label: const Text('Leave a Review'),
      );
    }
    if (booking.status == BookingStatus.pending) {
      return OutlinedButton(
        onPressed: () => ref
            .read(firestoreServiceProvider)
            .updateBookingStatus(booking.id, 'cancelled'),
        child: const Text('Cancel Request'),
      );
    }
    return const SizedBox.shrink();
  }
}
