import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import 'auth_provider.dart'; // provides firestoreServiceProvider

final bookingMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, bookingId) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.watchBookingMessages(bookingId);
});

final bookingThreadSummaryProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, bookingId) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.watchBookingThreadSummary(bookingId);
});
