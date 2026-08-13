import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at ecard_requests/{autoId}. An organizer's request for
/// admin approval to create an E-Card for a specific event — scoped
/// per (organizer, event) pair, not a one-time account-level
/// permission, matching how E-Cards themselves are scoped 1:1 to an
/// event.
///
/// Deliberately NOT built on top of the existing notifications/
/// collection: that collection is Cloud-Function-only by design
/// (see firestore.rules — `allow create: if false`), so admin's
/// awareness of a pending request comes from a live count query on
/// this collection directly (see allEcardRequestsForAdminProvider /
/// pendingEcardRequestsCountProvider) rather than a notification
/// document. No new backend deploy required for this to work.
class EcardRequest {
  final String id;
  final String organizerId;
  final String eventId;

  /// 'pending' | 'approved' | 'rejected'
  final String status;

  /// Admin's optional short reply, shown to the organizer either way.
  final String? adminReply;

  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const EcardRequest({
    required this.id,
    required this.organizerId,
    required this.eventId,
    this.status = 'pending',
    this.adminReply,
    this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory EcardRequest.fromMap(String id, Map<String, dynamic> map) {
    return EcardRequest(
      id: id,
      organizerId: map['organizer_id'] ?? '',
      eventId: map['event_id'] ?? '',
      status: map['status'] ?? 'pending',
      adminReply: map['admin_reply'],
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      resolvedAt: (map['resolved_at'] as Timestamp?)?.toDate(),
      resolvedBy: map['resolved_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizer_id': organizerId,
      'event_id': eventId,
      'status': status,
      'admin_reply': adminReply,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'resolved_at': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolved_by': resolvedBy,
    };
  }
}
