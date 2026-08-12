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

  /// Admin-only account control (see firestore.rules — only an admin
  /// can flip this, never the user themselves). A disabled account is
  /// blocked from the app at the router level (see app_router.dart)
  /// and, for musicians, hidden from the public directory (see
  /// Musician.disabled). Does not delete anything — fully reversible.
  final bool disabled;

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
    this.disabled = false,
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
      disabled: map['disabled'] ?? false,
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
      'disabled': disabled,
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
    bool? disabled,
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
      disabled: disabled ?? this.disabled,
      createdAt: createdAt,
    );
  }
}
