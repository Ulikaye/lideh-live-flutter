import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/musician_provider.dart';
import '../../shared/widgets/loading_indicator.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.go('/profile/edit')),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) return const LoadingIndicator();
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: profile.profilePictureUrl != null ? CachedNetworkImageProvider(profile.profilePictureUrl!) : null,
                      child: profile.profilePictureUrl == null
                          ? Text(
                              (profile.displayName?.isNotEmpty ?? false) ? profile.displayName![0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 32),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(profile.displayName ?? profile.email, style: Theme.of(context).textTheme.headlineSmall),
                    Text(profile.userType == UserType.musician ? 'Musician' : 'Organizer', style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: profile.email),
                            if (profile.phone != null) _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: profile.phone!),
                            if (profile.location != null) _InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: profile.location!),
                            if (profile.bio != null && profile.bio!.isNotEmpty) _InfoRow(icon: Icons.info_outline, label: 'Bio', value: profile.bio!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout, color: AppColors.danger),
                      label: const Text('Sign Out', style: TextStyle(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
