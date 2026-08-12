import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/strings.dart';

/// Stored at ecards/{autoId}. One per organizer's event that opts into
/// the E-Card service — references events/{eventId} by id rather than
/// replacing it (the existing Event model in event.dart is untouched).
///
/// `fields` intentionally stays a loose Map<String, dynamic> rather
/// than a fixed set of Dart properties: the occasion-specific field
/// set is defined by the chosen EcardTemplate.fieldSchema, so adding a
/// new occasion later never requires a model change here — only a new
/// template document and a form that renders its schema.
class Ecard {
  final String id;
  final String eventId;
  final String organizerId;
  final EcardOccasion occasion;
  final String templateId;
  final Map<String, dynamic> fields;

  /// Per-E-Card guest counter used to mint sequential, human-readable
  /// display IDs (e.g. "WD-0001") scoped to this card only. See
  /// FirestoreService.addEcardGuest — this replaces Harusi Cards'
  /// single global meta/counter document, which only worked because
  /// there was exactly one wedding.
  final int guestCounter;

  /// 'private' (default) or 'public'. Private E-Cards are only
  /// reachable by direct link/QR — nothing lists them. Public ones
  /// also appear on the platform's public E-Cards page
  /// (/e-cards/public) for discovery. Opt-in only, per design: an
  /// organizer sharing a wedding invite via WhatsApp/email has no
  /// reason to also want it listed publicly unless they choose to.
  final String visibility;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Ecard({
    required this.id,
    required this.eventId,
    required this.organizerId,
    required this.occasion,
    required this.templateId,
    required this.fields,
    this.guestCounter = 0,
    this.visibility = 'private',
    this.createdAt,
    this.updatedAt,
  });

  bool get isPublic => visibility == 'public';

  factory Ecard.fromMap(String id, Map<String, dynamic> map) {
    return Ecard(
      id: id,
      eventId: map['event_id'] ?? '',
      organizerId: map['organizer_id'] ?? '',
      occasion: EcardOccasionX.fromString(map['occasion'] as String?),
      templateId: map['template_id'] ?? '',
      fields: Map<String, dynamic>.from(map['fields'] ?? const {}),
      guestCounter: map['guest_counter'] ?? 0,
      visibility: map['visibility'] ?? 'private',
      createdAt: (map['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event_id': eventId,
      'organizer_id': organizerId,
      'occasion': occasion.value,
      'template_id': templateId,
      'fields': fields,
      'guest_counter': guestCounter,
      'visibility': visibility,
      'created_at':
          createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Ecard copyWith({Map<String, dynamic>? fields, String? templateId, String? visibility}) {
    return Ecard(
      id: id,
      eventId: eventId,
      organizerId: organizerId,
      occasion: occasion,
      templateId: templateId ?? this.templateId,
      fields: fields ?? this.fields,
      guestCounter: guestCounter,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
