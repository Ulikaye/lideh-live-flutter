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
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
