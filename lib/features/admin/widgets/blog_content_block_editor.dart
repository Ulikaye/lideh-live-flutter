import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/blog_post.dart';

// Local enum for block types (matching ContentBlock.type strings)
enum BlockType { heading, paragraph, imageText }

extension BlockTypeExtension on BlockType {
  String get value {
    switch (this) {
      case BlockType.heading:
        return 'heading';
      case BlockType.paragraph:
        return 'paragraph';
      case BlockType.imageText:
        return 'imageText';
    }
  }

  static BlockType fromString(String value) {
    switch (value) {
      case 'heading':
        return BlockType.heading;
      case 'paragraph':
        return BlockType.paragraph;
      case 'imageText':
        return BlockType.imageText;
      default:
        return BlockType.paragraph;
    }
  }
}

class EditableBlock {
  final BlockType type;
  final TextEditingController textController;
  String? imageUrl;

  EditableBlock({
    required this.type,
    String? text,
    this.imageUrl,
  }) : textController = TextEditingController(text: text ?? '');

  ContentBlock toBlock() {
    return ContentBlock(
      type: type.value,
      text: textController.text.trim().isEmpty
          ? null
          : textController.text.trim(),
      imageUrl: imageUrl,
    );
  }

  void dispose() {
    textController.dispose();
  }
}

class BlogContentBlockEditor extends StatefulWidget {
  final List<EditableBlock> blocks;
  final VoidCallback onChanged;

  const BlogContentBlockEditor({
    super.key,
    required this.blocks,
    required this.onChanged,
  });

  @override
  State<BlogContentBlockEditor> createState() => _BlogContentBlockEditorState();
}

class _BlogContentBlockEditorState extends State<BlogContentBlockEditor> {
  void _addBlock(BlockType type) {
    setState(() {
      widget.blocks.add(EditableBlock(type: type));
      widget.onChanged();
    });
  }

  void _removeBlock(int index) {
    setState(() {
      widget.blocks[index].dispose();
      widget.blocks.removeAt(index);
      widget.onChanged();
    });
  }

  void _moveBlockUp(int index) {
    if (index == 0) return;
    setState(() {
      final temp = widget.blocks[index];
      widget.blocks[index] = widget.blocks[index - 1];
      widget.blocks[index - 1] = temp;
      widget.onChanged();
    });
  }

  void _moveBlockDown(int index) {
    if (index == widget.blocks.length - 1) return;
    setState(() {
      final temp = widget.blocks[index];
      widget.blocks[index] = widget.blocks[index + 1];
      widget.blocks[index + 1] = temp;
      widget.onChanged();
    });
  }

  Future<void> _pickImage(EditableBlock block) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (picked == null) return;
    // For simplicity, we'll just store a placeholder URL.
    // In a real app, you'd upload to Firebase Storage here.
    // We'll simulate with a local asset indicator.
    // But the actual upload is handled in the parent screen's save method.
    // So we'll just store a dummy string to indicate an image is selected.
    setState(() {
      block.imageUrl = 'pending_upload';
      widget.onChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => _addBlock(BlockType.heading),
              icon: const Icon(Icons.title, size: 16),
              label: const Text('Add heading'),
            ),
            ElevatedButton.icon(
              onPressed: () => _addBlock(BlockType.paragraph),
              icon: const Icon(Icons.text_fields, size: 16),
              label: const Text('Add paragraph'),
            ),
            ElevatedButton.icon(
              onPressed: () => _addBlock(BlockType.imageText),
              icon: const Icon(Icons.image, size: 16),
              label: const Text('Add image + text'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.blocks.isEmpty)
          const Text('No content blocks yet. Add one above.',
              style: TextStyle(color: AppColors.textSecondary)),
        ...widget.blocks.asMap().entries.map((entry) {
          final index = entry.key;
          final block = entry.value;
          return _BlockCard(
            block: block,
            index: index,
            total: widget.blocks.length,
            onRemove: () => _removeBlock(index),
            onMoveUp: () => _moveBlockUp(index),
            onMoveDown: () => _moveBlockDown(index),
            onChanged: widget.onChanged,
            onPickImage: () => _pickImage(block),
          );
        }),
      ],
    );
  }
}

class _BlockCard extends StatefulWidget {
  final EditableBlock block;
  final int index;
  final int total;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onChanged;
  final VoidCallback onPickImage;

  const _BlockCard({
    required this.block,
    required this.index,
    required this.total,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onChanged,
    required this.onPickImage,
  });

  @override
  State<_BlockCard> createState() => _BlockCardState();
}

class _BlockCardState extends State<_BlockCard> {
  @override
  void initState() {
    super.initState();
    widget.block.textController.addListener(widget.onChanged);
  }

  @override
  void dispose() {
    // Do not dispose the controller here; it's disposed by the parent.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isImageBlock = widget.block.type == BlockType.imageText;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.block.type == BlockType.heading
                      ? Icons.title
                      : widget.block.type == BlockType.imageText
                          ? Icons.image
                          : Icons.text_fields,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.block.type == BlockType.heading
                      ? 'Heading'
                      : widget.block.type == BlockType.imageText
                          ? 'Image + text'
                          : 'Paragraph',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  onPressed: widget.index == 0 ? null : widget.onMoveUp,
                  tooltip: 'Move up',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  onPressed: widget.index == widget.total - 1
                      ? null
                      : widget.onMoveDown,
                  tooltip: 'Move down',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.danger),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove block',
                ),
              ],
            ),
            if (isImageBlock) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: widget.onPickImage,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.background,
                  ),
                  child: Center(
                    child: widget.block.imageUrl != null
                        ? const Icon(Icons.check_circle,
                            color: AppColors.success)
                        : const Text('Tap to select image (simulated)'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: widget.block.textController,
              maxLines: widget.block.type == BlockType.heading ? 1 : 5,
              decoration: InputDecoration(
                hintText: widget.block.type == BlockType.heading
                    ? 'Section heading'
                    : isImageBlock
                        ? 'Caption or text next to image'
                        : 'Paragraph text',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
