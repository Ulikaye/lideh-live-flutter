import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/blog_post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blog_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/profile_menu_button.dart';

/// Admin-only: lists every blog post, published or draft, with quick
/// actions to create, edit, publish/unpublish, or delete. This is the
/// entry point that replaces hand-editing documents in the Firestore
/// console.
class AdminBlogListScreen extends ConsumerWidget {
  const AdminBlogListScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, BlogPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: Text('"${post.title}" will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(firestoreServiceProvider).deleteBlogPost(post.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(adminBlogPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Blog'),
        actions: const [ProfileMenuButton(), SizedBox(width: 8)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/blog/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
      body: postsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load posts: $e'),
        data: (posts) {
          if (posts.isEmpty) {
            return const EmptyStateWidget(
              title: 'No posts yet',
              subtitle: 'Tap "New Post" to publish your first article.',
              icon: Icons.article_outlined,
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final post = posts[i];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: post.featuredImageUrl != null ? NetworkImage(post.featuredImageUrl!) : null,
                        child: post.featuredImageUrl == null ? const Icon(Icons.article_outlined, color: AppColors.primary) : null,
                      ),
                      title: Text(post.title.isEmpty ? '(untitled)' : post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(post.isPublished ? 'Published' : 'Draft', style: TextStyle(color: post.isPublished ? AppColors.success : AppColors.textSecondary)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => context.go('/admin/blog/${post.id}/edit'),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            onPressed: () => _confirmDelete(context, ref, post),
                          ),
                        ],
                      ),
                      onTap: () => context.go('/admin/blog/${post.id}/edit'),
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
