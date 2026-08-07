import 'package:cloud_firestore/cloud_firestore.dart';

/// A single block within a post's body. Lets richer posts — ones with
/// section headings and a photo + caption per person/item, like a
/// "meet the team" roundup — render properly instead of collapsing
/// everything into one plain-text field.
enum BlogBlockType { heading, paragraph, imageText }

class BlogContentBlock {
  final BlogBlockType type;
  final String? text;
  final String? imageUrl;

  const BlogContentBlock({required this.type, this.text, this.imageUrl});

  factory BlogContentBlock.fromMap(Map<String, dynamic> map) {
    return BlogContentBlock(
      type: _typeFromString(map['type'] as String?),
      text: map['text'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': _typeToString(type),
      if (text != null) 'text': text,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }

  static BlogBlockType _typeFromString(String? value) {
    switch (value) {
      case 'heading':
        return BlogBlockType.heading;
      case 'image_text':
        return BlogBlockType.imageText;
      default:
        return BlogBlockType.paragraph;
    }
  }

  static String _typeToString(BlogBlockType type) {
    switch (type) {
      case BlogBlockType.heading:
        return 'heading';
      case BlogBlockType.imageText:
        return 'image_text';
      case BlogBlockType.paragraph:
        return 'paragraph';
    }
  }
}

/// Stored at blogPosts/{autoId}. Mirrors Django's BlogPost model —
/// content hub for articles, testimonials and platform news.
///
/// `contentBlocks` is the preferred way to author a post body (supports
/// headings and per-item images with captions). `content` remains as a
/// plain-text fallback for posts that don't need that structure, and is
/// what renders if `contentBlocks` is empty.
class BlogPost {
  final String id;
  final String title;
  final String slug;
  final String authorId;
  final String? categoryId;
  final String? featuredImageUrl;
  final String? excerpt;
  final String content;
  final List<BlogContentBlock> contentBlocks;
  final bool isPublished;
  final DateTime? publishedDate;
  final String? relatedMusicianId;
  final String? relatedEventId;

  const BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    required this.authorId,
    this.categoryId,
    this.featuredImageUrl,
    this.excerpt,
    required this.content,
    this.contentBlocks = const [],
    this.isPublished = false,
    this.publishedDate,
    this.relatedMusicianId,
    this.relatedEventId,
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
      contentBlocks: (map['content_blocks'] as List<dynamic>?)
              ?.map((b) => BlogContentBlock.fromMap(Map<String, dynamic>.from(b as Map)))
              .toList() ??
          const [],
      isPublished: map['is_published'] ?? false,
      publishedDate: (map['published_date'] as Timestamp?)?.toDate(),
      relatedMusicianId: map['related_musician_id'],
      relatedEventId: map['related_event_id'],
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
      'published_date': publishedDate != null ? Timestamp.fromDate(publishedDate!) : FieldValue.serverTimestamp(),
      'related_musician_id': relatedMusicianId,
      'related_event_id': relatedEventId,
    };
  }
}
