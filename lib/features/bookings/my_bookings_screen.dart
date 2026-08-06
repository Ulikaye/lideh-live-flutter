import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'widgets/booking_card.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;

    if (profile == null) return const Scaffold(body: LoadingIndicator());

    final bookingsAsync = profile.userType == UserType.musician
        ? ref.watch(bookingsForMusicianProvider(profile.uid))
        : ref.watch(bookingsForOrganizerProvider(profile.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load bookings'),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const EmptyStateWidget(
              title: 'No bookings yet',
              subtitle: 'Bookings you create or receive will show up here',
              icon: Icons.event_busy_outlined,
            );
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
      ),
    );
  }
}
