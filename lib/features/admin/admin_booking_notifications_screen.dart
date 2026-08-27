import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../core/constants/strings.dart'; // for BookingStatus

/// Admin screen that lists all unviewed bookings (adminViewed == false).
/// Each booking can be marked as viewed (removes from list) or deleted
/// (soft-delete, also removes from list).
class AdminBookingNotificationsScreen extends ConsumerStatefulWidget {
  const AdminBookingNotificationsScreen({super.key});

  @override
  ConsumerState<AdminBookingNotificationsScreen> createState() =>
      _AdminBookingNotificationsScreenState();
}

class _AdminBookingNotificationsScreenState
    extends ConsumerState<AdminBookingNotificationsScreen> {
  // Helper to get status display text
  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      default:
        return status.toString().split('.').last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(unviewedBookingsForAdminProvider);
    final count = ref.watch(unviewedBookingCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Notifications'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: count.when(
              data: (c) => Chip(
                label: Text('$c new'),
                backgroundColor:
                    c > 0 ? AppColors.primary : Colors.grey.shade300,
                labelStyle:
                    TextStyle(color: c > 0 ? Colors.white : Colors.black54),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      body: bookingsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load bookings'),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const EmptyStateWidget(
              title: 'All caught up!',
              subtitle: 'No new booking notifications.',
              icon: Icons.notifications_off_outlined,
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final booking = bookings[i];
                  return Card(
                    child: ListTile(
                      title: Text(booking.eventName),
                      subtitle: Text(
                        '${_statusLabel(booking.status)} · ${DateFormat('MMM d, y').format(booking.eventDate)} · '
                        'Musician: ${booking.musicianId} · Organizer: ${booking.organizerId}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Mark as viewed',
                            icon: const Icon(Icons.check_circle_outline,
                                color: AppColors.success),
                            onPressed: () => _markViewed(booking.id),
                          ),
                          IconButton(
                            tooltip: 'Delete notification',
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            onPressed: () => _deleteNotification(booking.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markViewed(String bookingId) async {
    final service = ref.read(firestoreServiceProvider);
    await service.markBookingViewed(bookingId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as viewed')),
      );
    }
  }

  Future<void> _deleteNotification(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notification?'),
        content: const Text(
            'This removes it from your notification list. The booking itself is not deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final service = ref.read(firestoreServiceProvider);
      await service.deleteBookingNotification(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    }
  }
}
