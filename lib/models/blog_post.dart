import 'package:cloud_firestore/cloud_firestore.dart';

class BlogPost {
  final String id;
  final String title;
  final String slug;
  final String authorId;
  final String? categoryId;
  final String? featuredImageUrl;
  final String? excerpt;
  final String content;
  final List<ContentBlock> contentBlocks;
  final bool isPublished;
  final bool isPinned; // NEW
  final DateTime? publishedDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    required this.authorId,
    this.categoryId,
    this.featuredImageUrl,
    this.excerpt,
    this.content = '',
    this.contentBlocks = const [],
    this.isPublished = false,
    this.isPinned = false, // NEW
    this.publishedDate,
    this.createdAt,
    this.updatedAt,
  });

  factory BlogPost.fromMap(String id, Map<String, dynamic> map) {
    return BlogPost(
      id: id,
      title: map['title'] ?? '',
      slug: map['slug'] ?? '',
      authorId: map['author_id'] ?? '',
      categoryId: map['category_id'],
      featuredImageUrl: map['featured_image_url'],
      excerpt: map['excerpt'],
      content: map['content'] ?? '',
      contentBlocks: (map['content_blocks'] as List?)
              ?.map((b) => ContentBlock.fromMap(b))
              .toList() ??
          const [],
      isPublished: map['is_published'] ?? false,
      isPinned: map['is_pinned'] ?? false, // NEW
      publishedDate: (map['published_date'] as Timestamp?)?.toDate(),
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'slug': slug,
      'author_id': authorId,
      'category_id': categoryId,
      'featured_image_url': featuredImageUrl,
      'excerpt': excerpt,
      'content': content,
      'content_blocks': contentBlocks.map((b) => b.toMap()).toList(),
      'is_published': isPublished,
      'is_pinned': isPinned, // NEW
      'published_date': publishedDate != null
          ? Timestamp.fromDate(publishedDate!)
          : FieldValue.serverTimestamp(),
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

class ContentBlock {
  final String type; // 'paragraph', 'image', 'quote'
  final String? text;
  final String? imageUrl;

  const ContentBlock({required this.type, this.text, this.imageUrl});

  factory ContentBlock.fromMap(Map<String, dynamic> map) {
    return ContentBlock(
      type: map['type'] ?? 'paragraph',
      text: map['text'],
      imageUrl: map['image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'text': text,
      'image_url': imageUrl,
    };
  }
}
