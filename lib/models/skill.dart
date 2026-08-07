/// Stored at skills/{autoId}. Public, admin-managed lookup list used to
/// populate the skill picker on musician profile setup — mirrors Django's
/// Skill model, which musicians had a many-to-many relationship with.
class Skill {
  final String id;
  final String name;
  final String slug;

  const Skill({required this.id, required this.name, required this.slug});

  factory Skill.fromMap(String id, Map<String, dynamic> map) {
    return Skill(id: id, name: map['name'] ?? '', slug: map['slug'] ?? '');
  }

  Map<String, dynamic> toMap() => {'name': name, 'slug': slug};
}
