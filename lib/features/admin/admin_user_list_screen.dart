import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ecard_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';

/// Admin account moderation — every registered musician/organizer
/// (and other admins, shown but not actionable against — see
/// _canModerate). Reachable only by an admin (route guard in
/// app_router.dart); the underlying watchAllUsersForAdmin() query
/// requires isAdmin() server-side regardless.
///
/// Deactivate is the everyday action: reversible, blocks the
/// account's dashboard access (app_router.dart's redirect gate) and,
/// for musicians, hides them from the public directory immediately
/// (FirestoreService.setUserDisabled mirrors the flag onto
/// musicians/{uid} in the same batch). Delete is separated behind a
/// second, more explicit confirmation — see the doc comment on
/// FirestoreService.deleteUserAccount for what it does and does not
/// do (it cannot remove the Firebase Auth credential itself).
class AdminUserListScreen extends ConsumerWidget {
  const AdminUserListScreen({super.key});

  bool _canModerate(UserProfile u) => u.userType != UserType.admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersForAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: usersAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load users'),
        data: (users) {
          if (users.isEmpty) return const EmptyStateWidget(title: 'No users yet', icon: Icons.people_outline);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final user = users[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.disabled ? AppColors.danger.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: user.profilePictureUrl != null ? NetworkImage(user.profilePictureUrl!) : null,
                        child: user.profilePictureUrl == null
                            ? Icon(Icons.person_outline, color: user.disabled ? AppColors.danger : AppColors.primary)
                            : null,
                      ),
                      title: Text(user.displayName ?? user.email),
                      subtitle: Text('${_roleLabel(user.userType)} · ${user.email}${user.disabled ? " · Deactivated" : ""}'),
                      trailing: _canModerate(user)
                          ? PopupMenuButton<String>(
                              onSelected: (value) => _handleAction(context, ref, user, value),
                              itemBuilder: (context) => [
                                if (user.disabled)
                                  const PopupMenuItem(value: 'reactivate', child: Text('Reactivate'))
                                else
                                  const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete account')),
                              ],
                            )
                          : const Tooltip(message: 'Admin accounts are not moderated here', child: Icon(Icons.shield_outlined, color: AppColors.textSecondary)),
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

  String _roleLabel(UserType type) {
    switch (type) {
      case UserType.musician:
        return 'Musician';
      case UserType.organizer:
        return 'Organizer';
      case UserType.admin:
        return 'Admin';
    }
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, UserProfile user, String action) async {
    final service = ref.read(firestoreServiceProvider);
    final name = user.displayName ?? user.email;

    if (action == 'deactivate' || action == 'reactivate') {
      final disabling = action == 'deactivate';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(disabling ? 'Deactivate $name?' : 'Reactivate $name?'),
          content: Text(disabling
              ? 'They will lose access to their dashboard immediately${user.userType == UserType.musician ? " and be hidden from the musician directory" : ""}. This is reversible.'
              : 'They will regain full access immediately.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(disabling ? 'Deactivate' : 'Reactivate')),
          ],
        ),
      );
      if (confirmed == true) {
        await service.setUserDisabled(user.uid, disabling, userType: user.userType);
      }
      return;
    }

    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete $name\'s account?'),
          content: const Text(
            'This permanently removes their profile — no dashboard, not listed anywhere, everything about them stops working. '
            'This does not delete their login credential itself (that needs a separate server-side step); deactivating is usually the right choice instead. This cannot be undone.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete permanently', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await service.deleteUserAccount(user.uid, userType: user.userType);
      }
    }
  }
}
