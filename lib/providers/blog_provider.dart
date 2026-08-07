import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blog_category.dart';
import '../models/blog_post.dart';
import 'auth_provider.dart';

final blogCategoriesProvider = StreamProvider<List<BlogCategory>>((ref) {
  return ref.watch(firestoreServiceProvider).watchBlogCategories();
});

final selectedBlogCategoryProvider = StateProvider<String?>((ref) => null);

final blogPostsProvider = StreamProvider<List<BlogPost>>((ref) {
  final categoryId = ref.watch(selectedBlogCategoryProvider);
  return ref.watch(firestoreServiceProvider).watchBlogPosts(categoryId: categoryId);
});

final blogPostByIdProvider = StreamProvider.family<BlogPost?, String>((ref, id) {
  return ref.watch(firestoreServiceProvider).watchBlogPost(id);
});

/// Unfiltered post list (includes drafts) for the admin blog dashboard.
final adminBlogPostsProvider = StreamProvider<List<BlogPost>>((ref) {
  return ref.watch(firestoreServiceProvider).watchAllBlogPostsForAdmin();
});
