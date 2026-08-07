import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/strings.dart';

/// Corresponds to Django's core User + Profile. Stored at users/{uid}.
/// Role-specific data (musician/organizer) lives in its own collection,
/// keyed by the same uid, to avoid one bloated document.
class UserProfile {
  final String uid;
  final String email;
  final UserType userType;
  final String? displayName;
  final String? phone;
  final String? location;
  final String? bio;
  final String? profilePictureUrl;
  final bool verified;
  final DateTime? createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.userType,
    this.displayName,
    this.phone,
    this.location,
    this.bio,
    this.profilePictureUrl,
    this.verified = false,
    this.createdAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] ?? '',
      userType: UserTypeX.fromString(map['user_type'] as String?),
      displayName: map['display_name'],
      phone: map['phone'],
      location: map['location'],
      bio: map['bio'],
      profilePictureUrl: map['profile_picture_url'],
      verified: map['verified'] ?? false,
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'user_type': userType.value,
      'display_name': displayName,
      'phone': phone,
      'location': location,
      'bio': bio,
      'profile_picture_url': profilePictureUrl,
      'verified': verified,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? phone,
    String? location,
    String? bio,
    String? profilePictureUrl,
    bool? verified,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      userType: userType,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      verified: verified ?? this.verified,
      createdAt: createdAt,
    );
  }
}
