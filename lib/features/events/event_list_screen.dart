import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/profile_menu_button.dart';
import '../../shared/widgets/skeleton_loaders.dart';

class EventListScreen extends ConsumerWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final profile = ref.watch(currentUserProfileProvider).value;
    final canCreate = profile?.userType == UserType.organizer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Events'),
        actions: [
          if (canCreate)
            TextButton.icon(
              onPressed: () => context.go('/events/create'),
              icon: const Icon(Icons.add),
              label: const Text('New Event'),
            ),
          const ProfileMenuButton(),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: canCreate && Responsive.isMobile(context)
          ? FloatingActionButton(onPressed: () => context.go('/events/create'), child: const Icon(Icons.add))
          : null,
      body: eventsAsync.when(
        loading: () => const CenteredContent(child: EventListSkeleton()),
        error: (e, _) => AppErrorWidget(message: 'Could not load events'),
        data: (events) {
          if (events.isEmpty) {
            return const EmptyStateWidget(title: 'No upcoming events', subtitle: 'Check back soon or create one', icon: Icons.event_busy_outlined);
          }
          return CenteredContent(
            child: ListView.separated(
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final event = events[i];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.go('/events/${event.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(DateFormat('MMM').format(event.date).toUpperCase(),
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                                Text(DateFormat('d').format(event.date),
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 20)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.title, style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 13, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(event.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
