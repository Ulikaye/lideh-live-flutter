import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at musicians/{uid}. Mirrors Django's Musician model
/// (stage name, skills, availability, price, experience, video, photo).
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
  final bool disabled;
  final bool verified;
  final String? photoURL; // NEW: profile picture URL
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
    this.photoURL, // NEW
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
      photoURL: map['photo_url'], // NEW
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
      'photo_url': photoURL, // NEW
      'joined_at': joinedAt != null
          ? Timestamp.fromDate(joinedAt!)
          : FieldValue.serverTimestamp(),
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
    String? photoURL, // NEW
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
      disabled: disabled,
      verified: verified,
      photoURL: photoURL ?? this.photoURL,
      joinedAt: joinedAt,
    );
  }
}
