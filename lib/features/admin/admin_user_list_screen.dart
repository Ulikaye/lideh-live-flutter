import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ecard_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/verified_badge.dart';

/// Admin account moderation — every registered musician/organizer
/// (and other admins, shown but not actionable against — see
/// _canModerate). Reachable only by an admin (route guard in
/// app_router.dart); the underlying watchAllUsersForAdmin() query
/// requires isAdmin() server-side regardless.
///
/// Deactivate is the everyday action for controlling misbehaving
/// accounts: reversible, blocks the account's dashboard access
/// (app_router.dart's redirect gate) and, for musicians, hides them
/// from the public directory immediately (FirestoreService.
/// setUserDisabled mirrors the flag onto musicians/{uid} in the same
/// batch). Delete is separated behind a second, more explicit
/// confirmation — see the doc comment on
/// FirestoreService.deleteUserAccount for what it does and does not
/// do (it cannot remove the Firebase Auth credential itself).
///
/// Verify is the newer, separate approval gate: every new musician
/// and organizer registers unverified by default (see
/// UserProfile.verified / Musician.verified doc comments) — a
/// musician stays out of the public directory, an organizer can't
/// create events, until this is flipped on. Unverify exists mainly
/// to correct a mistaken approval, not as a moderation tool the way
/// deactivate is — deactivate is still the right action for an
/// already-verified account that starts misbehaving.
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

          // Accounts waiting on a verification decision surface first
          // — that's the queue an admin actually needs to work
          // through regularly, versus the full list being mostly
          // already-resolved accounts.
          final sorted = [...users]..sort((a, b) {
              final aPending = _canModerate(a) && !a.verified ? 0 : 1;
              final bPending = _canModerate(b) && !b.verified ? 0 : 1;
              return aPending.compareTo(bPending);
            });

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final user = sorted[i];
                  final pendingVerification = _canModerate(user) && !user.verified;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user.disabled ? AppColors.danger.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: user.profilePictureUrl != null ? NetworkImage(user.profilePictureUrl!) : null,
                        child: user.profilePictureUrl == null
                            ? Icon(Icons.person_outline, color: user.disabled ? AppColors.danger : AppColors.primary)
                            : null,
                      ),
                      title: Row(
                        children: [
                          Flexible(child: Text(user.displayName ?? user.email)),
                          // Positive confirmation, not just the
                          // absence of "Pending verification" below —
                          // an admin scanning this list should be
                          // able to tell at a glance who's already
                          // cleared, not just who's waiting.
                          if (_canModerate(user) && user.verified) ...[
                            const SizedBox(width: 6),
                            const VerifiedBadge(size: 15),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${_roleLabel(user.userType)} · ${user.email}'
                        '${user.disabled ? " · Deactivated" : ""}'
                        '${pendingVerification ? " · Pending verification" : ""}',
                        style: pendingVerification ? const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600) : null,
                      ),
                      trailing: _canModerate(user)
                          ? PopupMenuButton<String>(
                              onSelected: (value) => _handleAction(context, ref, user, value),
                              itemBuilder: (context) => [
                                if (!user.verified)
                                  const PopupMenuItem(value: 'verify', child: Text('Verify'))
                                else
                                  const PopupMenuItem(value: 'unverify', child: Text('Unverify')),
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

    if (action == 'verify' || action == 'unverify') {
      final verifying = action == 'verify';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(verifying ? 'Verify $name?' : 'Remove verification from $name?'),
          content: Text(verifying
              ? (user.userType == UserType.musician
                  ? 'They will immediately appear in the public musician directory and become bookable.'
                  : 'They will immediately be able to create and publish events.')
              : (user.userType == UserType.musician
                  ? 'They will be hidden from the public directory again immediately.'
                  : 'They will lose the ability to create new events immediately. Existing events are unaffected.')),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(verifying ? 'Verify' : 'Remove verification')),
          ],
        ),
      );
      if (confirmed == true) {
        await service.setUserVerified(user.uid, verifying, userType: user.userType);
      }
      return;
    }

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
