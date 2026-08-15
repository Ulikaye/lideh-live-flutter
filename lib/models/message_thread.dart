import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at message_threads/{uid} — the parent doc summarizing one
/// user's conversation with admin. userDisplayName/userType are
/// denormalized here (written once when the thread is first created)
/// so the admin's thread list can render names without an extra read
/// per thread, same reasoning as avg_rating living on Musician
/// instead of requiring a join to reviews/.
class MessageThread {
  final String uid;
  final String userDisplayName;
  final String userType; // 'musician' or 'organizer'
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderRole; // 'admin' or 'user'
  final bool unreadByAdmin;
  final bool unreadByUser;

  const MessageThread({
    required this.uid,
    required this.userDisplayName,
    required this.userType,
    this.lastMessage = '',
    this.lastMessageAt,
    this.lastSenderRole = 'user',
    this.unreadByAdmin = false,
    this.unreadByUser = false,
  });

  factory MessageThread.fromMap(String uid, Map<String, dynamic> map) {
    return MessageThread(
      uid: uid,
      userDisplayName: map['user_display_name'] ?? '',
      userType: map['user_type'] ?? '',
      lastMessage: map['last_message'] ?? '',
      lastMessageAt: (map['last_message_at'] as Timestamp?)?.toDate(),
      lastSenderRole: map['last_sender_role'] ?? 'user',
      unreadByAdmin: map['unread_by_admin'] ?? false,
      unreadByUser: map['unread_by_user'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_display_name': userDisplayName,
      'user_type': userType,
      'last_message': lastMessage,
      'last_message_at': FieldValue.serverTimestamp(),
      'last_sender_role': lastSenderRole,
      'unread_by_admin': unreadByAdmin,
      'unread_by_user': unreadByUser,
    };
  }
}
