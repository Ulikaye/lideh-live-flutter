import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at blogPosts/{autoId}. Mirrors Django's BlogPost model —
/// content hub for articles, testimonials and platform news.
class BlogPost {
  final String id;
  final String title;
  final String slug;
  final String authorId;
  final String? categoryId;
  final String? featuredImageUrl;
  final String? excerpt;
  final String content;
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
      'is_published': isPublished,
      'published_date': publishedDate != null ? Timestamp.fromDate(publishedDate!) : FieldValue.serverTimestamp(),
      'related_musician_id': relatedMusicianId,
      'related_event_id': relatedEventId,
    };
  }
}
