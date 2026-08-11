import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ecard_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/notification_bell_button.dart';
import '../../../shared/widgets/profile_menu_button.dart';

/// Organizer's E-Card list — mirrors _EventsTab in organizer_dashboard.dart
/// (same ConstrainedBox/ListView.separated/Card shape) so it reads as
/// part of the same app rather than a bolted-on screen.
class EcardListScreen extends ConsumerWidget {
  const EcardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;
    if (profile == null) return const Scaffold(body: LoadingIndicator());

    final ecardsAsync = ref.watch(ecardsForOrganizerProvider(profile.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New E-Card',
            onPressed: () => context.go('/e-cards/create'),
          ),
          const NotificationBellButton(),
          const ProfileMenuButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: ecardsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load E-Cards'),
        data: (ecards) {
          if (ecards.isEmpty) {
            return EmptyStateWidget(
              title: 'No E-Cards yet',
              subtitle: 'Create a digital invitation for one of your events',
              icon: Icons.mail_outline_rounded,
              action: ElevatedButton.icon(
                onPressed: () => context.go('/e-cards/create'),
                icon: const Icon(Icons.add),
                label: const Text('Create E-Card'),
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: ecards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final ecard = ecards[i];
                  final titleField = ecard.fields['title'] ??
                      ecard.fields['service_title'] ??
                      ecard.fields['bride_name'] ??
                      ecard.occasion.label;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(_iconFor(ecard.occasion), color: AppColors.primary),
                      ),
                      title: Text('$titleField'),
                      subtitle: Text(ecard.occasion.label),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      onTap: () => context.go('/e-cards/${ecard.id}'),
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

  IconData _iconFor(EcardOccasion occasion) {
    switch (occasion) {
      case EcardOccasion.wedding:
        return Icons.favorite_outline_rounded;
      case EcardOccasion.worship:
        return Icons.church_outlined;
      case EcardOccasion.conference:
        return Icons.groups_outlined;
      case EcardOccasion.other:
        return Icons.event_outlined;
    }
  }
}
