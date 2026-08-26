import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored either in message_threads/{uid}/messages/{autoId} (admin-user)
/// or in bookings/{bookingId}/messages/{autoId} (musician-organizer).
/// The same model is used for both contexts; senderRole indicates
/// 'admin', 'musician', or 'organizer'.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String text;
  final bool liked;
  final bool deleted; // soft delete flag
  final DateTime? deletedAt;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.liked = false,
    this.deleted = false,
    this.deletedAt,
    this.createdAt,
  });

  bool get isFromAdmin => senderRole == 'admin';

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      senderId: map['sender_id'] ?? '',
      senderRole: map['sender_role'] ?? 'user',
      text: map['text'] ?? '',
      liked: map['liked'] ?? false,
      deleted: map['deleted'] ?? false,
      deletedAt: (map['deleted_at'] as Timestamp?)?.toDate(),
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'sender_role': senderRole,
      'text': text,
      'liked': liked,
      'deleted': deleted,
      'deleted_at': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  ChatMessage copyWith({bool? deleted, DateTime? deletedAt}) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      senderRole: senderRole,
      text: text,
      liked: liked,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
    );
  }
}
