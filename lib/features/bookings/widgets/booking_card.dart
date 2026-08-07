import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart';
import '../../../models/booking.dart';
import '../../../shared/widgets/pressable_scale.dart';

Color statusColor(BookingStatus status) {
  switch (status) {
    case BookingStatus.pending:
      return AppColors.statusPending;
    case BookingStatus.accepted:
      return AppColors.statusAccepted;
    case BookingStatus.declined:
      return AppColors.statusDeclined;
    case BookingStatus.completed:
      return AppColors.statusCompleted;
    case BookingStatus.cancelled:
      return AppColors.statusCancelled;
  }
}

class BookingCard extends StatelessWidget {
  final Booking booking;
  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(booking.status);
    final dateStr = DateFormat('MMM d, yyyy').format(booking.eventDate);

    return PressableScale(
      child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/bookings/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 4, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.eventName, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('$dateStr${booking.eventTime != null ? ' • ${booking.eventTime}' : ''}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text(booking.venue, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(booking.status.label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
