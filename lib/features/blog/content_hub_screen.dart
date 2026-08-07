import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/blog_category.dart';
import '../../models/blog_post.dart';
import '../../providers/blog_provider.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/skeleton_loaders.dart';
import '../../shared/widgets/profile_menu_button.dart';

class ContentHubScreen extends ConsumerWidget {
  const ContentHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(blogPostsProvider);
    final categoriesAsync = ref.watch(blogCategoriesProvider);
    final selectedCategory = ref.watch(selectedBlogCategoryProvider);
    final isWide = Responsive.isDesktopOrTablet(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Hub'),
        actions: const [ProfileMenuButton(), SizedBox(width: 8)],
      ),
      body: CenteredContent(
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _PostsGrid(postsAsync: postsAsync)),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 240,
                    child: _CategorySidebar(categoriesAsync: categoriesAsync, selected: selectedCategory),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategorySidebar(categoriesAsync: categoriesAsync, selected: selectedCategory, horizontal: true),
                  const SizedBox(height: 12),
                  Expanded(child: _PostsGrid(postsAsync: postsAsync)),
                ],
              ),
      ),
    );
  }
}

class _CategorySidebar extends ConsumerWidget {
  final AsyncValue<List<BlogCategory>> categoriesAsync;
  final String? selected;
  final bool horizontal;
  const _CategorySidebar({required this.categoriesAsync, required this.selected, this.horizontal = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return categoriesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) {
        final chips = [
          ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => ref.read(selectedBlogCategoryProvider.notifier).state = null,
          ),
          ...categories.map((c) => ChoiceChip(
                label: Text(c.name),
                selected: selected == c.id,
                onSelected: (_) => ref.read(selectedBlogCategoryProvider.notifier).state = c.id,
              )),
        ];
        if (horizontal) {
          return SizedBox(height: 44, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: chips.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) => chips[i]));
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Categories', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: chips),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostsGrid extends StatelessWidget {
  final AsyncValue<List<BlogPost>> postsAsync;
  const _PostsGrid({required this.postsAsync});

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context).clamp(1, 2);
    return postsAsync.when(
      loading: () => BlogGridSkeleton(columns: columns),
      error: (e, _) => AppErrorWidget(message: 'Could not load posts'),
      data: (posts) {
        if (posts.isEmpty) return const EmptyStateWidget(title: 'No posts yet', icon: Icons.article_outlined);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.3),
          itemCount: posts.length,
          itemBuilder: (context, i) => _PostCard(post: posts[i]),
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final BlogPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/blog/${post.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.featuredImageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(imageUrl: post.featuredImageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: AppColors.border)),
              )
            else
              AspectRatio(aspectRatio: 16 / 9, child: Container(color: AppColors.primary.withValues(alpha: 0.08), child: const Icon(Icons.article_outlined, color: AppColors.primary, size: 32))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  if (post.excerpt != null)
                    Text(post.excerpt!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  if (post.publishedDate != null)
                    Text(DateFormat('MMM d, yyyy').format(post.publishedDate!), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
