import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../shared/widgets/chat_thread_view.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';

/// A musician or organizer's own conversation with admin — the "ask
/// about something" channel from the platform's trust/safety flow:
/// verification pending, an E-Card request declined, or just a
/// general question, without needing a separate support system.
class UserMessageScreen extends ConsumerStatefulWidget {
  const UserMessageScreen({super.key});

  @override
  ConsumerState<UserMessageScreen> createState() => _UserMessageScreenState();
}

class _UserMessageScreenState extends ConsumerState<UserMessageScreen> {
  bool _markedRead = false;

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(myMessagesProvider);
    final profile = ref.watch(currentUserProfileProvider).value;

    // Mark read once per screen visit, not on every rebuild — avoids
    // spamming writes as new messages stream in while the screen is
    // already open and presumably already being read.
    final thread = ref.watch(myMessageThreadProvider).value;
    if (thread != null && thread.unreadByUser && !_markedRead) {
      _markedRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(firestoreServiceProvider).markThreadRead(profile!.uid, asAdmin: false);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: messagesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load messages'),
        data: (messages) {
          if (profile == null) return const LoadingIndicator();
          return ChatThreadView(
            messages: messages,
            myRole: 'user',
            onSend: (text) => ref.read(firestoreServiceProvider).sendMessage(
                  uid: profile.uid,
                  text: text,
                  senderId: profile.uid,
                  senderRole: 'user',
                  userDisplayName: profile.displayName ?? profile.email,
                  userType: profile.userType == UserType.musician ? 'musician' : 'organizer',
                ),
          );
        },
      ),
    );
  }
}
