/// Stored at organizers/{uid}. Mirrors Django's Organizer/Church model.
class Organizer {
  final String uid;
  final String organizationName;
  final String? churchAffiliation;
  final String? location;

  const Organizer({
    required this.uid,
    required this.organizationName,
    this.churchAffiliation,
    this.location,
  });

  factory Organizer.fromMap(String uid, Map<String, dynamic> map) {
    return Organizer(
      uid: uid,
      organizationName: map['organization_name'] ?? '',
      churchAffiliation: map['church_affiliation'],
      location: map['location'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organization_name': organizationName,
      'church_affiliation': churchAffiliation,
      'location': location,
    };
  }

  Organizer copyWith({String? organizationName, String? churchAffiliation, String? location}) {
    return Organizer(
      uid: uid,
      organizationName: organizationName ?? this.organizationName,
      churchAffiliation: churchAffiliation ?? this.churchAffiliation,
      location: location ?? this.location,
    );
  }
}
