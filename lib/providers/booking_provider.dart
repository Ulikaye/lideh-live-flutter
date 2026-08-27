import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import 'auth_provider.dart';

final bookingsForMusicianProvider =
    StreamProvider.family<List<Booking>, String>((ref, musicianId) {
  return ref
      .watch(firestoreServiceProvider)
      .watchBookingsForMusician(musicianId);
});

final bookingsForOrganizerProvider =
    StreamProvider.family<List<Booking>, String>((ref, organizerId) {
  return ref
      .watch(firestoreServiceProvider)
      .watchBookingsForOrganizer(organizerId);
});

final bookingByIdProvider = StreamProvider.family<Booking?, String>((ref, id) {
  return ref.watch(firestoreServiceProvider).watchBooking(id);
});

// Admin booking notifications
final unviewedBookingsForAdminProvider = StreamProvider<List<Booking>>((ref) {
  return ref.watch(firestoreServiceProvider).watchUnviewedBookingsForAdmin();
});

final unviewedBookingCountProvider = StreamProvider<int>((ref) {
  return ref.watch(firestoreServiceProvider).watchUnviewedBookingCount();
});
