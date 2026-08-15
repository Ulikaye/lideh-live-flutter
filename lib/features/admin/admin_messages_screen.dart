import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/message_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';

class AdminMessagesScreen extends ConsumerWidget {
  const AdminMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(allThreadsForAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: threadsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load conversations'),
        data: (threads) {
          if (threads.isEmpty) {
            return const EmptyStateWidget(title: 'No conversations yet', icon: Icons.forum_outlined);
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: threads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final thread = threads[i];
                  return Card(
                    color: thread.unreadByAdmin ? AppColors.primary.withValues(alpha: 0.05) : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          thread.userDisplayName.isNotEmpty ? thread.userDisplayName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(
                        thread.userDisplayName,
                        style: TextStyle(fontWeight: thread.unreadByAdmin ? FontWeight.bold : FontWeight.normal),
                      ),
                      subtitle: Text(
                        '${thread.lastSenderRole == 'admin' ? 'You: ' : ''}${thread.lastMessage}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: thread.lastMessageAt != null
                          ? Text(DateFormat('MMM d').format(thread.lastMessageAt!), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
                          : null,
                      onTap: () => context.go('/admin/messages/${thread.uid}'),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
