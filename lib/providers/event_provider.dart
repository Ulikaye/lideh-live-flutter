import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import 'auth_provider.dart';

/// Public upcoming events – sorted: pinned first, then by date ascending
final upcomingEventsProvider = StreamProvider<List<Event>>((ref) {
  final stream = ref.watch(firestoreServiceProvider).watchUpcomingEvents();

  // Transform the stream to sort the list
  return stream.map((events) {
    final sorted = List<Event>.from(events);
    sorted.sort((a, b) {
      // Pinned first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // Then by date ascending (soonest first)
      return a.date.compareTo(b.date);
    });
    return sorted;
  });
});

final eventByIdProvider = StreamProvider.family<Event?, String>((ref, id) {
  return ref.watch(firestoreServiceProvider).watchEvent(id);
});

final eventsForOrganizerProvider =
    StreamProvider.family<List<Event>, String>((ref, organizerId) {
  return ref
      .watch(firestoreServiceProvider)
      .watchEventsForOrganizer(organizerId);
});

final allEventsForAdminProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(firestoreServiceProvider).watchAllEventsForAdmin();
});
