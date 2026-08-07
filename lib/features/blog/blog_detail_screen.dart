import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/blog_post.dart';
import '../../providers/blog_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_indicator.dart';

class BlogDetailScreen extends ConsumerWidget {
  final String postId;
  const BlogDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(blogPostByIdProvider(postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Article')),
      body: postAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => AppErrorWidget(message: 'Could not load article'),
        data: (post) {
          if (post == null) return const EmptyStateWidget(title: 'Article not found');
          return SingleChildScrollView(
            child: CenteredContent(
              padding: const EdgeInsets.all(0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.featuredImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: CachedNetworkImage(imageUrl: post.featuredImageUrl!, fit: BoxFit.cover),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(post.title, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      if (post.contentBlocks.isNotEmpty)
                        _BlogBody(blocks: post.contentBlocks)
                      else
                        Text(post.content, style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Renders a post's structured body: section headings, plain
/// paragraphs, and photo + caption entries (e.g. one per person in a
/// "meet the team" style post).
class _BlogBody extends StatelessWidget {
  final List<BlogContentBlock> blocks;
  const _BlogBody({required this.blocks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks) _blockWidget(context, block),
      ],
    );
  }

  Widget _blockWidget(BuildContext context, BlogContentBlock block) {
    switch (block.type) {
      case BlogBlockType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            block.text ?? '',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      case BlogBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(block.text ?? '', style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary)),
        );
      case BlogBlockType.imageText:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ImageTextBlock(imageUrl: block.imageUrl, text: block.text ?? ''),
        );
    }
  }
}

class _ImageTextBlock extends StatelessWidget {
  final String? imageUrl;
  final String text;
  const _ImageTextBlock({required this.imageUrl, required this.text});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: isMobile ? 64 : 80,
              height: isMobile ? 64 : 80,
              fit: BoxFit.cover,
            )
          : Container(
              width: isMobile ? 64 : 80,
              height: isMobile ? 64 : 80,
              color: AppColors.background,
              child: const Icon(Icons.person_outline, color: AppColors.textSecondary),
            ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        image,
        const SizedBox(width: 14),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
