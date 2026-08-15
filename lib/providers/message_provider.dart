import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/message_thread.dart';
import 'auth_provider.dart';

/// The signed-in user's own thread with admin — uid comes from the
/// currently authenticated user, so this always resolves to "my
/// conversation," never needs a parameter.
final myMessageThreadProvider = StreamProvider<MessageThread?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).watchMessageThread(uid);
});

final myMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).watchMessagesForThread(uid);
});

/// Admin-only — a specific user's thread, by their uid.
final messagesForThreadProvider = StreamProvider.family<List<ChatMessage>, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).watchMessagesForThread(uid);
});

/// Admin's full inbox — every conversation, most recent first.
final allThreadsForAdminProvider = StreamProvider<List<MessageThread>>((ref) {
  return ref.watch(firestoreServiceProvider).watchAllThreadsForAdmin();
});

/// Live badge count for the profile menu — same pattern as
/// pendingEcardRequestCountProvider, derived client-side from the
/// already-watched thread list rather than a second query.
final unreadThreadCountForAdminProvider = Provider<int>((ref) {
  final threads = ref.watch(allThreadsForAdminProvider).value ?? const [];
  return threads.where((t) => t.unreadByAdmin).length;
});
