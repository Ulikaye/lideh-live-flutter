import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import 'auth_provider.dart';

final upcomingEventsProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(firestoreServiceProvider).watchUpcomingEvents();
});

final eventByIdProvider = StreamProvider.family<Event?, String>((ref, id) {
  return ref.watch(firestoreServiceProvider).watchEvent(id);
});

final eventsForOrganizerProvider = StreamProvider.family<List<Event>, String>((ref, organizerId) {
  return ref.watch(firestoreServiceProvider).watchEventsForOrganizer(organizerId);
});

final allEventsForAdminProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(firestoreServiceProvider).watchAllEventsForAdmin();
});
