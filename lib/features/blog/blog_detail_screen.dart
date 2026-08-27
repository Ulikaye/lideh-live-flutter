import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/blog_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../models/blog_post.dart';

class BlogDetailScreen extends ConsumerWidget {
  final String postId;
  const BlogDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(blogPostByIdProvider(postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Blog Post')),
      body: postAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load post'),
        data: (post) {
          if (post == null) {
            return const AppErrorWidget(message: 'Post not found');
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.featuredImageUrl != null)
                  Image.network(post.featuredImageUrl!,
                      width: double.infinity, height: 200, fit: BoxFit.cover),
                const SizedBox(height: 16),
                Text(post.title,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                if (post.excerpt != null)
                  Text(post.excerpt!,
                      style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                ...post.contentBlocks
                    .map((block) => _blockWidget(context, block)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _blockWidget(BuildContext context, ContentBlock block) {
    switch (block.type) {
      case 'heading':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            block.text ?? '',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        );
      case 'paragraph':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(block.text ?? ''),
        );
      case 'imageText':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              if (block.imageUrl != null)
                Expanded(
                  flex: 1,
                  child: Image.network(block.imageUrl!,
                      height: 120, fit: BoxFit.cover),
                ),
              if (block.imageUrl != null) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(block.text ?? ''),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
