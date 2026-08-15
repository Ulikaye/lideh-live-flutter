import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at message_threads/{uid}/messages/{autoId}. One thread per
/// musician/organizer (uid == the thread doc's own id), any admin can
/// read/reply to any thread — matches how E-Card requests, blog, and
/// events are all "any admin can moderate," not assigned per-admin.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderRole; // 'admin' or 'user'
  final String text;

  /// Admin-only, one-way — the spec here is deliberately simple
  /// ("just a reply, or a like"), not a full reaction system. Only an
  /// admin can ever set this, enforced by the same field-lock pattern
  /// already used for disabled/verified elsewhere.
  final bool liked;

  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.liked = false,
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
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'sender_role': senderRole,
      'text': text,
      'liked': liked,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
