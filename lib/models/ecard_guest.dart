import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at ecards/{ecardId}/guests/{autoId} — nested under its
/// E-Card, not a flat global collection. This is the key schema
/// difference from Harusi Cards' `contributors/` collection: scoping
/// guests under their card is what makes per-organizer data isolation
/// possible (see firestore.rules and Phase 1 doc §3/§4).
class EcardGuest {
  final String id;

  /// Human-readable sequential id, e.g. "WD-0001", minted per-card
  /// (see FirestoreService.addEcardGuest). Encoded in the guest's QR
  /// as `ecardId:guestId` — never name/amount, unlike the original
  /// Harusi Cards payload.
  final String displayId;

  final String fullName;
  final String? phone;

  /// Occasion-specific category, e.g. "Single"/"Double" for a wedding,
  /// "VIP"/"General" for a conference. Free-form string driven by the
  /// template, same spirit as Ecard.fields.
  final String? category;

  final bool checkedIn;
  final DateTime? checkedInTime;
  final DateTime? createdAt;

  const EcardGuest({
    required this.id,
    required this.displayId,
    required this.fullName,
    this.phone,
    this.category,
    this.checkedIn = false,
    this.checkedInTime,
    this.createdAt,
  });

  factory EcardGuest.fromMap(String id, Map<String, dynamic> map) {
    return EcardGuest(
      id: id,
      displayId: map['display_id'] ?? '',
      fullName: map['full_name'] ?? '',
      phone: map['phone'],
      category: map['category'],
      checkedIn: map['checked_in'] ?? false,
      checkedInTime: (map['checked_in_time'] as Timestamp?)?.toDate(),
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'display_id': displayId,
      'full_name': fullName,
      'phone': phone,
      'category': category,
      'checked_in': checkedIn,
      'checked_in_time':
          checkedInTime != null ? Timestamp.fromDate(checkedInTime!) : null,
      'created_at':
          createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}

/// Builds the QR payload for a guest — deliberately minimal (see
/// EcardGuest class doc): just enough to look the record up. The scan
/// screen reads name/amount/status server-side rather than trusting
/// anything printed on the card itself.
String buildEcardQrPayload({required String ecardId, required String guestId}) =>
    '$ecardId:$guestId';

/// Thrown by FirestoreService.checkInEcardGuest when a guest has
/// already been checked in. Replaces the read-then-write pattern in
/// the original ScanGateFragment.handleScanResult (a benign race in
/// practice for a single-door event, but a transaction closes it
/// properly rather than relying on scan timing).
class AlreadyCheckedInException implements Exception {
  final DateTime? checkedInTime;
  const AlreadyCheckedInException(this.checkedInTime);

  @override
  String toString() => 'Guest already checked in${checkedInTime != null ? " at $checkedInTime" : ""}';
}
