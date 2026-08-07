/// Stored at blogCategories/{autoId}. Admin-managed, public-read lookup
/// list mirroring Django's BlogCategory model.
class BlogCategory {
  final String id;
  final String name;
  final String slug;

  const BlogCategory({required this.id, required this.name, required this.slug});

  factory BlogCategory.fromMap(String id, Map<String, dynamic> map) {
    return BlogCategory(id: id, name: map['name'] ?? '', slug: map['slug'] ?? '');
  }

  Map<String, dynamic> toMap() => {'name': name, 'slug': slug};
}
