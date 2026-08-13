import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at events/{autoId}. Mirrors Django's Event model — organizers
/// publish events; musicians can discover and request to perform,
/// which creates a Booking referencing this event.
class Event {
  final String id;
  final String organizerId;
  final String title;
  final DateTime date;
  final String? time;
  final String location;
  final String? description;
  final String? imageUrl;
  final bool isCancelled;

  /// Draft/published state. Defaults to `true` here (not `false`) —
  /// this default only ever applies when the field is MISSING from a
  /// stored document, i.e. every event created before this field
  /// existed. Treating "missing" as "published" is what keeps every
  /// existing live event visible with no backfill migration needed;
  /// the actual "start as a draft" behavior for NEW events comes from
  /// create_event_screen.dart explicitly constructing
  /// Event(isPublished: false, ...), not from this default. See the
  /// matching firestore.rules comment (`is_published != false`) for
  /// the server-side half of this same reasoning.
  final bool isPublished;

  final DateTime? createdAt;

  const Event({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.date,
    this.time,
    required this.location,
    this.description,
    this.imageUrl,
    this.isCancelled = false,
    this.isPublished = true,
    this.createdAt,
  });

  factory Event.fromMap(String id, Map<String, dynamic> map) {
    return Event(
      id: id,
      organizerId: map['organizer_id'] ?? '',
      title: map['title'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: map['time'],
      location: map['location'] ?? '',
      description: map['description'],
      imageUrl: map['image_url'],
      isCancelled: map['is_cancelled'] ?? false,
      isPublished: map['is_published'] ?? true,
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizer_id': organizerId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'time': time,
      'location': location,
      'description': description,
      'image_url': imageUrl,
      'is_cancelled': isCancelled,
      'is_published': isPublished,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
