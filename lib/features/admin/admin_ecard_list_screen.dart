import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ecard_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';

/// Admin moderation for E-Cards across every organizer — reachable
/// only by an admin account (route guard in app_router.dart, and the
/// underlying watchAllEcardsForAdmin() query itself requires
/// isAdmin() server-side per firestore.rules, so this screen has no
/// functional effect for anyone else even if they somehow reached it).
///
/// Deliberately does NOT show guest lists — admin can moderate the
/// card itself (make private, delete) but guest PII stays behind the
/// organizer-only rule on the guests/ subcollection, unchanged.
class AdminEcardListScreen extends ConsumerWidget {
  const AdminEcardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecardsAsync = ref.watch(allEcardsForAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage E-Cards')),
      body: ecardsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load E-Cards'),
        data: (ecards) {
          if (ecards.isEmpty) {
            return const EmptyStateWidget(title: 'No E-Cards yet', icon: Icons.mail_outline_rounded);
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: ecards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final ecard = ecards[i];
                  final titleField = ecard.fields['title'] ??
                      ecard.fields['service_title'] ??
                      ecard.fields['bride_name'] ??
                      ecard.occasion.label;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        ecard.isPublic ? Icons.public : Icons.lock_outline,
                        color: ecard.isPublic ? AppColors.primary : AppColors.textSecondary,
                      ),
                      title: Text('$titleField'),
                      subtitle: Text('${ecard.occasion.label} · organizer ${ecard.organizerId} · ${ecard.isPublic ? "Public" : "Private"}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          final service = ref.read(firestoreServiceProvider);
                          if (value == 'make_private') {
                            await service.updateEcardVisibility(ecard.id, 'private');
                          } else if (value == 'make_public') {
                            await service.updateEcardVisibility(ecard.id, 'public');
                          } else if (value == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete this E-Card?'),
                                content: const Text('This removes the card permanently. This does not delete its guest list.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) await service.deleteEcard(ecard.id);
                          }
                        },
                        itemBuilder: (context) => [
                          if (ecard.isPublic)
                            const PopupMenuItem(value: 'make_private', child: Text('Make private'))
                          else
                            const PopupMenuItem(value: 'make_public', child: Text('Make public')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
}
