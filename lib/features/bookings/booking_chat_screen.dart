import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/booking_chat_provider.dart';
import '../../shared/widgets/chat_thread_view.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';

class BookingChatScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingChatScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends ConsumerState<BookingChatScreen> {
  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingByIdProvider(widget.bookingId));
    final currentUser = ref.watch(authStateProvider).value;
    final currentProfile = ref.watch(currentUserProfileProvider).value;

    // Determine user role and IDs using enum .name
    String? myRole;
    String? myUid;
    String? userDisplayName;
    String? userType;
    if (currentUser != null && currentProfile != null) {
      myUid = currentUser.uid;
      userDisplayName = currentProfile.displayName ?? currentUser.email;
      final userTypeName = currentProfile.userType.name;
      if (userTypeName == 'musician') {
        myRole = 'musician';
        userType = 'musician';
      } else if (userTypeName == 'organizer') {
        myRole = 'organizer';
        userType = 'organizer';
      } else if (userTypeName == 'admin') {
        myRole = 'admin';
        userType = 'admin';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          bookingAsync.when(
            data: (booking) {
              if (booking == null) return 'Chat';
              final isMusician = myRole == 'musician';
              final otherPartyName = isMusician ? 'Organizer' : 'Musician';
              return 'Chat with $otherPartyName';
            },
            loading: () => 'Loading...',
            error: (_, __) => 'Chat',
          ),
        ),
      ),
      body: bookingAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load booking: $e'),
        data: (booking) {
          if (booking == null) {
            return const AppErrorWidget(message: 'Booking not found');
          }
          if (myRole == null || myUid == null) {
            return const AppErrorWidget(
                message: 'You must be logged in to chat.');
          }

          final messagesProvider =
              ref.watch(bookingMessagesProvider(widget.bookingId));

          return messagesProvider.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppErrorWidget(message: 'Could not load messages: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref
                          .refresh(bookingMessagesProvider(widget.bookingId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (messages) {
              return ChatThreadView(
                messages: messages,
                myRole: myRole!,
                onSend: (text) async {
                  final firestore = ref.read(firestoreServiceProvider);
                  await firestore.sendBookingMessage(
                    bookingId: widget.bookingId,
                    text: text,
                    senderId: myUid!,
                    senderRole: myRole!,
                    userDisplayName: userDisplayName ?? '',
                    userType: userType ?? '',
                  );
                },
                onDelete: (messageId) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Message'),
                      content: const Text(
                          'Are you sure you want to delete this message?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final firestore = ref.read(firestoreServiceProvider);
                    await firestore.deleteBookingMessage(
                      bookingId: widget.bookingId,
                      messageId: messageId,
                      currentUserId: myUid!,
                      currentUserRole: myRole!,
                    );
                  }
                },
                onToggleLike: myRole == 'admin'
                    ? (message) async {
                        final firestore = ref.read(firestoreServiceProvider);
                        await firestore.toggleBookingMessageLike(
                          bookingId: widget.bookingId,
                          messageId: message.id,
                          liked: !message.liked,
                        );
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
