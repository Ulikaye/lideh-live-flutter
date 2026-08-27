import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blog_category.dart';
import '../models/blog_post.dart';
import 'auth_provider.dart';

final blogCategoriesProvider = StreamProvider<List<BlogCategory>>((ref) {
  return ref.watch(firestoreServiceProvider).watchBlogCategories();
});

final selectedBlogCategoryProvider = StateProvider<String?>((ref) => null);

/// Public blog posts – sorted: pinned first, then by published date descending
final blogPostsProvider = StreamProvider<List<BlogPost>>((ref) {
  final categoryId = ref.watch(selectedBlogCategoryProvider);
  final stream = ref
      .watch(firestoreServiceProvider)
      .watchBlogPosts(categoryId: categoryId);

  // Transform the stream to sort the list
  return stream.map((posts) {
    final sorted = List<BlogPost>.from(posts);
    sorted.sort((a, b) {
      // Pinned first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      // Then by published date descending (newest first)
      final aDate = a.publishedDate ?? DateTime(2000);
      final bDate = b.publishedDate ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return sorted;
  });
});

final blogPostByIdProvider =
    StreamProvider.family<BlogPost?, String>((ref, id) {
  return ref.watch(firestoreServiceProvider).watchBlogPost(id);
});

/// Unfiltered post list (includes drafts) for the admin blog dashboard.
final adminBlogPostsProvider = StreamProvider<List<BlogPost>>((ref) {
  return ref.watch(firestoreServiceProvider).watchAllBlogPostsForAdmin();
});
