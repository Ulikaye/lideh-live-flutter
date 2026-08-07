import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

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

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      onSelected: (value) async {
        if (value == 'profile') {
          context.go('/profile');
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
