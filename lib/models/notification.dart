import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at notifications/{autoId}. Populated by Cloud Functions —
/// bookings created/updated, and (as of this update) new
/// musician/organizer registrations awaiting verification, and E-Card
/// requests awaiting approval. Consumed via FCM + an in-app inbox.
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? bookingId;

  /// Generic deep-link, added alongside bookingId rather than
  /// replacing it — booking notifications keep using bookingId
  /// exactly as before (see notification_inbox_screen.dart), this
  /// covers everything that isn't a booking (an admin review screen,
  /// etc.) without needing a new field per notification type.
  final String? route;

  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.bookingId,
    this.route,
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
      route: map['route'],
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
      'route': route,
      'read': read,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
