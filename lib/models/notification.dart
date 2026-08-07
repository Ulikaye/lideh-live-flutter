import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at notifications/{autoId}. Populated by Cloud Functions when a
/// booking is created/updated, and consumed via FCM + an in-app inbox.
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? bookingId;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.bookingId,
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      bookingId: map['booking_id'],
      read: map['read'] ?? false,
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'body': body,
      'booking_id': bookingId,
      'read': read,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
