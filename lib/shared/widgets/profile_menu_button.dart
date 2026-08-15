import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ecard_provider.dart';
import '../../providers/message_provider.dart';

/// Persistent profile/logout access point. Every top-level screen
/// (Home, Musicians, Events, Blog, Dashboard) includes this in its
/// AppBar actions so both musicians and organizers always have a way
/// to reach their profile and sign out, regardless of which tab
/// they're on — there is no separate "Profile" nav destination.
class ProfileMenuButton extends ConsumerWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).value;
    final isAdmin = profile?.userType == UserType.admin;
    // Only queried for actual admins — this collection's rules
    // require isAdmin() to read at all, so watching it for every
    // musician/organizer would just be a permission-denied query
    // firing on every screen for no reason.
    final pendingRequestCount = isAdmin ? ref.watch(pendingEcardRequestCountProvider).value ?? 0 : 0;
    final unreadThreadCount = isAdmin ? ref.watch(unreadThreadCountForAdminProvider) : 0;

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      onSelected: (value) async {
        if (value == 'profile') {
          context.go('/profile');
        } else if (value == 'admin_blog') {
          context.go('/admin/blog');
        } else if (value == 'admin_ecards') {
          context.go('/admin/e-cards');
        } else if (value == 'admin_ecard_requests') {
          context.go('/admin/ecard-requests');
        } else if (value == 'admin_users') {
          context.go('/admin/users');
        } else if (value == 'admin_events') {
          context.go('/admin/events');
        } else if (value == 'admin_messages') {
          context.go('/admin/messages');
        } else if (value == 'my_messages') {
          context.go('/messages');
        } else if (value == 'signout') {
          await ref.read(authServiceProvider).signOut();
          if (context.mounted) context.go('/login');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text(profile?.displayName ?? 'My Profile', overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        if (isAdmin) ...[
          const PopupMenuItem(
            value: 'admin_blog',
            child: Row(
              children: [
                Icon(Icons.dashboard_customize_outlined, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Text('Manage Blog'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'admin_ecards',
            child: Row(
              children: [
                Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Text('Manage E-Cards'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'admin_ecard_requests',
            child: Row(
              children: [
                const Icon(Icons.pending_actions_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                const Text('E-Card Requests'),
                if (pendingRequestCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      pendingRequestCount > 9 ? '9+' : '$pendingRequestCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'admin_users',
            child: Row(
              children: [
                Icon(Icons.people_outline, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Text('Manage Users'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'admin_events',
            child: Row(
              children: [
                Icon(Icons.event_outlined, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Text('Manage Events'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'admin_messages',
            child: Row(
              children: [
                const Icon(Icons.forum_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                const Text('Messages'),
                if (unreadThreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      unreadThreadCount > 9 ? '9+' : '$unreadThreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else
          const PopupMenuItem(
            value: 'my_messages',
            child: Row(
              children: [
                Icon(Icons.forum_outlined, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Text('Message Admin'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'signout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: AppColors.danger),
              SizedBox(width: 10),
              Text('Sign Out', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          backgroundImage: profile?.profilePictureUrl != null ? NetworkImage(profile!.profilePictureUrl!) : null,
          child: profile?.profilePictureUrl == null
              ? Text(
                  (profile?.displayName?.isNotEmpty ?? false) ? profile!.displayName![0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                )
              : null,
        ),
      ),
    );
  }
}
