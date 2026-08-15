import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at musicians/{uid}. Mirrors Django's Musician model
/// (stage name, skills, availability, price, experience, video).
class Musician {
  final String uid;
  final String stageName;
  final List<String> skills;
  final String? availabilityNotes;
  final String? videoUrl;
  final String? youtubeVideoId;
  final double? startingPrice;
  final int? yearsOfExperience;
  final String? location;
  final double avgRating;
  final int reviewCount;

  /// Mirrors users/{uid}.disabled — denormalized here because the
  /// public musician directory queries this collection directly, not
  /// users/. Kept in sync by the same admin action that sets it on
  /// the user doc (see FirestoreService.setUserDisabled). The public
  /// browse query filters on this field directly; a disabled
  /// musician's own profile document still exists, it's just excluded
  /// from discovery.
  final bool disabled;

  /// Mirrors users/{uid}.verified, same reasoning as `disabled` above.
  /// A musician stays out of the public directory — invisible to
  /// organizers, not bookable — until an admin verifies the account.
  /// The musician can still log in and edit their own profile while
  /// pending; only public discovery is gated. Set together with the
  /// user doc's `verified` field by FirestoreService.setUserVerified.
  final bool verified;

  final DateTime? joinedAt;

  const Musician({
    required this.uid,
    required this.stageName,
    this.skills = const [],
    this.availabilityNotes,
    this.videoUrl,
    this.youtubeVideoId,
    this.startingPrice,
    this.yearsOfExperience,
    this.location,
    this.avgRating = 0,
    this.reviewCount = 0,
    this.disabled = false,
    this.verified = false,
    this.joinedAt,
  });

  factory Musician.fromMap(String uid, Map<String, dynamic> map) {
    return Musician(
      uid: uid,
      stageName: map['stage_name'] ?? '',
      skills: List<String>.from(map['skills'] ?? const []),
      availabilityNotes: map['availability_notes'],
      videoUrl: map['video_url'],
      youtubeVideoId: map['youtube_video_id'],
      startingPrice: (map['starting_price'] as num?)?.toDouble(),
      yearsOfExperience: map['years_of_experience'],
      location: map['location'],
      avgRating: (map['avg_rating'] as num?)?.toDouble() ?? 0,
      reviewCount: map['review_count'] ?? 0,
      disabled: map['disabled'] ?? false,
      verified: map['verified'] ?? false,
      joinedAt: (map['joined_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stage_name': stageName,
      'skills': skills,
      'availability_notes': availabilityNotes,
      'video_url': videoUrl,
      'youtube_video_id': youtubeVideoId,
      'starting_price': startingPrice,
      'years_of_experience': yearsOfExperience,
      'location': location,
      'avg_rating': avgRating,
      'review_count': reviewCount,
      'disabled': disabled,
      'verified': verified,
      'joined_at': joinedAt != null ? Timestamp.fromDate(joinedAt!) : FieldValue.serverTimestamp(),
    };
  }

  Musician copyWith({
    String? stageName,
    List<String>? skills,
    String? availabilityNotes,
    String? videoUrl,
    String? youtubeVideoId,
    double? startingPrice,
    int? yearsOfExperience,
    String? location,
  }) {
    return Musician(
      uid: uid,
      stageName: stageName ?? this.stageName,
      skills: skills ?? this.skills,
      availabilityNotes: availabilityNotes ?? this.availabilityNotes,
      videoUrl: videoUrl ?? this.videoUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      startingPrice: startingPrice ?? this.startingPrice,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      location: location ?? this.location,
      avgRating: avgRating,
      reviewCount: reviewCount,
      // Both previously dropped here — meaning any self-edit via
      // copyWith silently reset disabled/verified back to false on
      // the next save, regardless of their real admin-set status.
      disabled: disabled,
      verified: verified,
      joinedAt: joinedAt,
    );
  }
}
