import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notificationsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load notifications'),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              title: 'No notifications yet',
              subtitle: "You'll see booking updates here",
              icon: Icons.notifications_none_rounded,
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _NotificationTile(notification: notifications[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.read ? null : AppColors.primary.withValues(alpha: 0.05),
      child: ListTile(
        leading: Icon(
          notification.read ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
          color: notification.read ? AppColors.textSecondary : AppColors.primary,
        ),
        title: Text(notification.title, style: TextStyle(fontWeight: notification.read ? FontWeight.normal : FontWeight.bold)),
        subtitle: Text(notification.body),
        trailing: notification.createdAt != null
            ? Text(DateFormat('MMM d').format(notification.createdAt!), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
            : null,
        onTap: () async {
          if (!notification.read) {
            await FirebaseFirestore.instance.collection('notifications').doc(notification.id).update({'read': true});
          }
          if (notification.bookingId != null && context.mounted) {
            context.go('/bookings/${notification.bookingId}');
          }
        },
      ),
    );
  }
}
