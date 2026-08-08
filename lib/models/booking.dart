import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/strings.dart';

/// Stored at bookings/{autoId}. Central entity of the platform — mirrors
/// Django's Booking model connecting an Organizer to a Musician for an
/// Event, carrying its own status lifecycle.
class Booking {
  final String id;
  final String musicianId;
  final String organizerId;
  final String? eventId;
  final String eventName;
  final DateTime eventDate;
  final String? eventTime;
  final String venue;
  final String? message;
  final String? contactPhone;
  final BookingStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool reviewSubmitted;
  // uid of whichever party initiated this booking — an organizer
  // requesting a musician, or a musician applying to an event. Needed
  // so the notification Cloud Function knows which party to notify
  // (always "the other one"), rather than guessing from context.
  final String createdBy;

  const Booking({
    required this.id,
    required this.musicianId,
    required this.organizerId,
    this.eventId,
    required this.eventName,
    required this.eventDate,
    this.eventTime,
    required this.venue,
    this.message,
    this.contactPhone,
    this.status = BookingStatus.pending,
    this.createdAt,
    this.updatedAt,
    this.reviewSubmitted = false,
    required this.createdBy,
  });

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    return Booking(
      id: id,
      musicianId: map['musician_id'] ?? '',
      organizerId: map['organizer_id'] ?? '',
      eventId: map['event_id'],
      eventName: map['event_name'] ?? '',
      eventDate: (map['event_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eventTime: map['event_time'],
      venue: map['venue'] ?? '',
      message: map['message'],
      contactPhone: map['contact_phone'],
      status: BookingStatusX.fromString(map['status']),
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate(),
      reviewSubmitted: map['review_submitted'] ?? false,
      createdBy: map['created_by'] ?? map['organizer_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'musician_id': musicianId,
      'organizer_id': organizerId,
      'event_id': eventId,
      'event_name': eventName,
      'event_date': Timestamp.fromDate(eventDate),
      'event_time': eventTime,
      'venue': venue,
      'message': message,
      'contact_phone': contactPhone,
      'status': status.value,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'review_submitted': reviewSubmitted,
      'created_by': createdBy,
    };
  }
}
