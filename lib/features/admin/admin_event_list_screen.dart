import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';

class AdminEventListScreen extends ConsumerWidget {
  const AdminEventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(allEventsForAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Events')),
      body: eventsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load events'),
        data: (events) {
          if (events.isEmpty) {
            return const EmptyStateWidget(
                title: 'No events yet', icon: Icons.event_outlined);
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final event = events[i];
                  return Card(
                    child: ListTile(
                      title: Row(
                        children: [
                          if (event.isPinned)
                            const Icon(Icons.push_pin,
                                color: AppColors.primary, size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(event.title)),
                        ],
                      ),
                      subtitle: Text(
                          '${DateFormat('MMM d, yyyy').format(event.date)} · ${event.location}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (event.isCancelled)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Chip(
                                  label: Text('Unpublished'),
                                  backgroundColor: Color(0x1AE74C3C)),
                            ),
                          PopupMenuButton<String>(
                            onSelected: (value) =>
                                _handleAction(context, ref, event, value),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'toggle_publish',
                                child: Text(event.isCancelled
                                    ? 'Republish'
                                    : 'Unpublish'),
                              ),
                              PopupMenuItem(
                                value: 'toggle_pin',
                                child: Text(event.isPinned ? 'Unpin' : 'Pin'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete',
                                    style: TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, dynamic event, String action) async {
    final service = ref.read(firestoreServiceProvider);

    if (action == 'toggle_publish') {
      final unpublishing = !event.isCancelled;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(unpublishing
              ? 'Unpublish "${event.title}"?'
              : 'Republish "${event.title}"?'),
          content: Text(unpublishing
              ? 'This removes it from the public Events listing immediately. The organizer can see it was unpublished from their dashboard.'
              : 'This restores it to the public Events listing immediately.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(unpublishing ? 'Unpublish' : 'Republish')),
          ],
        ),
      );
      if (confirmed == true) {
        await service.setEventCancelled(event.id, unpublishing);
      }
      return;
    }

    if (action == 'toggle_pin') {
      final newPinned = !event.isPinned;
      await service.updateEventPinned(event.id, newPinned);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newPinned ? 'Pinned' : 'Unpinned')),
        );
      }
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete "${event.title}"?'),
          content: const Text(
              'This permanently removes the event. This cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await service.deleteEvent(event.id);
      }
    }
  }
}
