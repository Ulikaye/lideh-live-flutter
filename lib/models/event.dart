import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String organizerId;
  final String title;
  final String description;
  final DateTime date;
  final String? time;
  final String location;
  final String? coverImageUrl;
  final bool isCancelled;
  final bool isPublished;
  final bool isPinned; // NEW
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Event({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.date,
    this.time,
    required this.location,
    this.coverImageUrl,
    this.isCancelled = false,
    this.isPublished = false,
    this.isPinned = false, // NEW
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromMap(String id, Map<String, dynamic> map) {
    return Event(
      id: id,
      organizerId: map['organizer_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: map['time'],
      location: map['location'] ?? '',
      coverImageUrl: map['cover_image_url'],
      isCancelled: map['is_cancelled'] ?? false,
      isPublished: map['is_published'] ?? false,
      isPinned: map['is_pinned'] ?? false, // NEW
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizer_id': organizerId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'time': time,
      'location': location,
      'cover_image_url': coverImageUrl,
      'is_cancelled': isCancelled,
      'is_published': isPublished,
      'is_pinned': isPinned, // NEW
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
