import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/strings.dart';
import '../../../models/blog_post.dart';
import '../../../providers/auth_provider.dart';

/// A single mutable block used while editing — mirrors [BlogContentBlock]
/// but keeps a [TextEditingController] alive per block so text fields
/// don't lose focus/cursor position as the list reorders.
class EditableBlock {
  BlogBlockType type;
  final TextEditingController textController;
  String? imageUrl;
  bool uploading;

  EditableBlock({required this.type, String? text, this.imageUrl, this.uploading = false})
      : textController = TextEditingController(text: text);

  BlogContentBlock toBlock() => BlogContentBlock(type: type, text: textController.text.trim(), imageUrl: imageUrl);
}

/// Add/reorder/edit/delete UI for a post's [contentBlocks]. Purely a
/// controlled widget over the [blocks] list passed in — the parent
/// screen owns the state and calls [onChanged] after every mutation.
class BlogContentBlockEditor extends ConsumerWidget {
  final List<EditableBlock> blocks;
  final VoidCallback onChanged;

  const BlogContentBlockEditor({super.key, required this.blocks, required this.onChanged});

  Future<void> _pickImageFor(WidgetRef ref, EditableBlock block) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 85);
    if (picked == null) return;

    block.uploading = true;
    onChanged();
    try {
      final bytes = await picked.readAsBytes();
      final url = await ref.read(storageServiceProvider).uploadBytes(
            folder: AppStrings.blogImagesPath,
            bytes: bytes,
            extension: 'jpg',
          );
      block.imageUrl = url;
    } finally {
      block.uploading = false;
      onChanged();
    }
  }

  void _addBlock(BlogBlockType type) {
    blocks.add(EditableBlock(type: type));
    onChanged();
  }

  void _removeBlock(int index) {
    blocks.removeAt(index);
    onChanged();
  }

  void _move(int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= blocks.length) return;
    final block = blocks.removeAt(index);
    blocks.insert(newIndex, block);
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < blocks.length; i++) ...[
          _BlockCard(
            block: blocks[i],
            onMoveUp: i > 0 ? () => _move(i, -1) : null,
            onMoveDown: i < blocks.length - 1 ? () => _move(i, 1) : null,
            onDelete: () => _removeBlock(i),
            onPickImage: () => _pickImageFor(ref, blocks[i]),
            onTextChanged: onChanged,
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _addBlock(BlogBlockType.heading),
              icon: const Icon(Icons.title, size: 16),
              label: const Text('Add Heading'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addBlock(BlogBlockType.paragraph),
              icon: const Icon(Icons.notes, size: 16),
              label: const Text('Add Paragraph'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addBlock(BlogBlockType.imageText),
              icon: const Icon(Icons.image_outlined, size: 16),
              label: const Text('Add Photo + Caption'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BlockCard extends StatelessWidget {
  final EditableBlock block;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;
  final VoidCallback onPickImage;
  final VoidCallback onTextChanged;

  const _BlockCard({
    required this.block,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    required this.onPickImage,
    required this.onTextChanged,
  });

  String get _label {
    switch (block.type) {
      case BlogBlockType.heading:
        return 'Heading';
      case BlogBlockType.paragraph:
        return 'Paragraph';
      case BlogBlockType.imageText:
        return 'Photo + Caption';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(_label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondary)),
                const Spacer(),
                IconButton(iconSize: 18, onPressed: onMoveUp, icon: const Icon(Icons.arrow_upward)),
                IconButton(iconSize: 18, onPressed: onMoveDown, icon: const Icon(Icons.arrow_downward)),
                IconButton(iconSize: 18, onPressed: onDelete, icon: const Icon(Icons.close, color: AppColors.danger)),
              ],
            ),
            if (block.type == BlogBlockType.imageText) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onPickImage,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 64,
                        height: 64,
                        color: AppColors.background,
                        child: block.uploading
                            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                            : block.imageUrl != null
                                ? Image.network(block.imageUrl!, fit: BoxFit.cover)
                                : const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: block.textController,
                      maxLines: 3,
                      onChanged: (_) => onTextChanged(),
                      decoration: const InputDecoration(hintText: 'e.g. Name (@handle) is a...', border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                ],
              ),
            ] else
              TextField(
                controller: block.textController,
                maxLines: block.type == BlogBlockType.heading ? 1 : 5,
                onChanged: (_) => onTextChanged(),
                decoration: InputDecoration(
                  hintText: block.type == BlogBlockType.heading ? 'Section heading' : 'Paragraph text',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
