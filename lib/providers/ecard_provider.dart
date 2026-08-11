import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/strings.dart';
import '../models/ecard.dart';
import '../models/ecard_guest.dart';
import '../models/ecard_template.dart';
import 'auth_provider.dart';

// Mirrors event_provider.dart's pattern exactly: thin StreamProvider
// wrappers around firestoreServiceProvider, nothing else. No new
// FirestoreService instance, no new auth mechanism — reuses the
// providers already declared in auth_provider.dart.

final ecardsForOrganizerProvider =
    StreamProvider.family<List<Ecard>, String>((ref, organizerId) {
  return ref.watch(firestoreServiceProvider).watchEcardsForOrganizer(organizerId);
});

final ecardByIdProvider = StreamProvider.family<Ecard?, String>((ref, id) {
  return ref.watch(firestoreServiceProvider).watchEcard(id);
});

final ecardForEventProvider = StreamProvider.family<Ecard?, String>((ref, eventId) {
  return ref.watch(firestoreServiceProvider).watchEcardForEvent(eventId);
});

final ecardTemplatesProvider =
    StreamProvider.family<List<EcardTemplate>, EcardOccasion?>((ref, occasion) {
  return ref.watch(firestoreServiceProvider).watchEcardTemplates(occasion: occasion);
});

final guestsForEcardProvider =
    StreamProvider.family<List<EcardGuest>, String>((ref, ecardId) {
  return ref.watch(firestoreServiceProvider).watchGuestsForEcard(ecardId);
});

/// Keyed by a (ecardId, guestId) record — Phase 6's guest card/QR view
/// needs one specific guest, not the whole list.
final ecardGuestProvider =
    StreamProvider.family<EcardGuest?, (String ecardId, String guestId)>((ref, ids) {
  return ref.watch(firestoreServiceProvider).watchEcardGuest(ids.$1, ids.$2);
});
