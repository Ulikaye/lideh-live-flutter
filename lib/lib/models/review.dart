import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at reviews/{bookingId} (one review per completed booking).
/// Mirrors Django's Review model tied 1:1 to a Booking.
class Review {
  final String id;
  final String bookingId;
  final String musicianId;
  final String organizerId;
  final int rating; // 1-5
  final String? comment;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.bookingId,
    required this.musicianId,
    required this.organizerId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      bookingId: map['booking_id'] ?? '',
      musicianId: map['musician_id'] ?? '',
      organizerId: map['organizer_id'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'booking_id': bookingId,
      'musician_id': musicianId,
      'organizer_id': organizerId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
