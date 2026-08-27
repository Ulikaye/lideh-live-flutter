import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/strings.dart';
import '../../models/blog_category.dart';
import '../../models/blog_post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blog_provider.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'widgets/blog_content_block_editor.dart';

class AdminBlogEditorScreen extends ConsumerStatefulWidget {
  final String? postId;
  const AdminBlogEditorScreen({super.key, this.postId});

  bool get isEditing => postId != null;

  @override
  ConsumerState<AdminBlogEditorScreen> createState() =>
      _AdminBlogEditorScreenState();
}

class _AdminBlogEditorScreenState extends ConsumerState<AdminBlogEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _excerptController = TextEditingController();

  String? _categoryId;
  String? _featuredImageUrl;
  bool _uploadingFeatured = false;
  bool _isPublished = false;
  bool _isPinned = false;
  bool _saving = false;
  bool _initialized = false;
  final List<EditableBlock> _blocks = [];

  void _initFromPost(BlogPost post) {
    if (_initialized) return;
    _titleController.text = post.title;
    _slugController.text = post.slug;
    _excerptController.text = post.excerpt ?? '';
    _categoryId = post.categoryId;
    _featuredImageUrl = post.featuredImageUrl;
    _isPublished = post.isPublished;
    _isPinned = post.isPinned;
    _blocks.addAll(post.contentBlocks.map((b) => EditableBlock(
          type: BlockTypeExtension.fromString(b.type),
          text: b.text,
          imageUrl: b.imageUrl,
        )));
    _initialized = true;
  }

  String _slugify(String value) {
    final lower = value.trim().toLowerCase();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return replaced.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _pickFeaturedImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingFeatured = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(storageServiceProvider).uploadBytes(
            folder: AppStrings.blogImagesPath,
            bytes: bytes,
            extension: 'jpg',
          );
      setState(() => _featuredImageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not upload image: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingFeatured = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final authorId = ref.read(authServiceProvider).currentUser!.uid;
    final firestore = ref.read(firestoreServiceProvider);

    final post = BlogPost(
      id: widget.postId ?? '',
      title: _titleController.text.trim(),
      slug: _slugController.text.trim().isEmpty
          ? _slugify(_titleController.text)
          : _slugController.text.trim(),
      authorId: authorId,
      categoryId: _categoryId,
      featuredImageUrl: _featuredImageUrl,
      excerpt: _excerptController.text.trim().isEmpty
          ? null
          : _excerptController.text.trim(),
      content: '',
      contentBlocks: _blocks.map((b) => b.toBlock()).toList(),
      isPublished: _isPublished,
      isPinned: _isPinned,
      publishedDate: DateTime.now(),
    );

    try {
      if (widget.isEditing) {
        await firestore.setBlogPost(widget.postId!, post);
      } else {
        await firestore.createBlogPost(post);
      }
      if (mounted) context.go('/admin/blog');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not save post: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildForm(BuildContext context, List<BlogCategory> categories) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Featured image
                GestureDetector(
                  onTap: _uploadingFeatured ? null : _pickFeaturedImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: AppColors.background,
                        child: _uploadingFeatured
                            ? const Center(child: CircularProgressIndicator())
                            : _featuredImageUrl != null
                                ? Image.network(_featuredImageUrl!,
                                    fit: BoxFit.cover)
                                : const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined,
                                            size: 32,
                                            color: AppColors.textSecondary),
                                        SizedBox(height: 8),
                                        Text('Tap to upload a featured image',
                                            style: TextStyle(
                                                color:
                                                    AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _slugController,
                  decoration: const InputDecoration(
                      labelText: 'Slug (leave blank to auto-generate)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _excerptController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Excerpt (short teaser)',
                      alignLabelWithHint: true),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: _categoryId,
                  decoration:
                      const InputDecoration(labelText: 'Category (optional)'),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('No category')),
                    ...categories.map((c) => DropdownMenuItem<String?>(
                        value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Published'),
                  subtitle: Text(_isPublished
                      ? 'Visible to everyone'
                      : 'Draft — only visible here'),
                  value: _isPublished,
                  onChanged: (v) => setState(() => _isPublished = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pinned'),
                  subtitle:
                      const Text('Appears at the top of the blog listing'),
                  value: _isPinned,
                  onChanged: (v) => setState(() => _isPinned = v),
                ),
                const Divider(height: 32),
                Text('Body', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                BlogContentBlockEditor(
                    blocks: _blocks, onChanged: () => setState(() {})),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          widget.isEditing ? 'Save Changes' : 'Publish Post'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(blogCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit Post' : 'New Post')),
      body: categoriesAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) {
          if (!widget.isEditing) {
            return _buildForm(context, categories);
          }
          final postAsync = ref.watch(blogPostByIdProvider(widget.postId!));
          return postAsync.when(
            loading: () => const LoadingIndicator(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (post) {
              if (post == null)
                return const Center(child: Text('Post not found'));
              _initFromPost(post);
              return _buildForm(context, categories);
            },
          );
        },
      ),
    );
  }
}
