import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../models/message_thread.dart';
import '../../shared/widgets/chat_thread_view.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';

class AdminMessageThreadScreen extends ConsumerStatefulWidget {
  final String uid; // the musician/organizer's uid — same id as the thread doc
  const AdminMessageThreadScreen({super.key, required this.uid});

  @override
  ConsumerState<AdminMessageThreadScreen> createState() => _AdminMessageThreadScreenState();
}

class _AdminMessageThreadScreenState extends ConsumerState<AdminMessageThreadScreen> {
  bool _markedRead = false;

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesForThreadProvider(widget.uid));
    final threadAsync = ref.watch(allThreadsForAdminProvider);
    final adminUid = ref.watch(authStateProvider).value?.uid;

    MessageThread? thread;
    for (final t in threadAsync.value ?? const []) {
      if (t.uid == widget.uid) {
        thread = t;
        break;
      }
    }
    if (thread != null && thread.unreadByAdmin && !_markedRead) {
      _markedRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(firestoreServiceProvider).markThreadRead(widget.uid, asAdmin: true);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(thread?.userDisplayName ?? 'Conversation')),
      body: messagesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load messages'),
        data: (messages) {
          if (adminUid == null) return const LoadingIndicator();
          return ChatThreadView(
            messages: messages,
            myRole: 'admin',
            onToggleLike: (message) => ref.read(firestoreServiceProvider).toggleMessageLiked(widget.uid, message.id, !message.liked),
            onSend: (text) => ref.read(firestoreServiceProvider).sendMessage(
                  uid: widget.uid,
                  text: text,
                  senderId: adminUid,
                  senderRole: 'admin',
                  userDisplayName: thread?.userDisplayName ?? '',
                  userType: thread?.userType ?? '',
                ),
          );
        },
      ),
    );
  }
}
