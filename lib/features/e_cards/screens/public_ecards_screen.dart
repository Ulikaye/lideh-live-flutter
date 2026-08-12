import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart';
import '../../../models/ecard.dart';
import '../../../providers/ecard_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/profile_menu_button.dart';

/// Public E-Cards page — reachable without signing in (added to
/// _publicRoutes in app_router.dart), same treatment as the existing
/// public /events listing. Only shows E-Cards an organizer explicitly
/// opted into (Ecard.visibility == 'public') — everything else stays
/// reachable only by direct link/QR, never listed here regardless of
/// how this page's query is used.
class PublicEcardsScreen extends ConsumerWidget {
  const PublicEcardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecardsAsync = ref.watch(publicEcardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Cards'),
        actions: const [ProfileMenuButton(), SizedBox(width: 8)],
      ),
      body: ecardsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load E-Cards'),
        data: (ecards) {
          if (ecards.isEmpty) {
            return const EmptyStateWidget(
              title: 'No public E-Cards yet',
              subtitle: 'Organizers can choose to list their invitations here',
              icon: Icons.mail_outline_rounded,
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
                      onTap: () => context.go('/e-cards/public/${ecard.id}'),
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
