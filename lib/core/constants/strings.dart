class AppStrings {
  AppStrings._();

  static const appName = 'LiDeH Live';
  static const tagline =
      'Discover, connect, and book gospel musicians with ease.';

  // Firestore collection names — single source of truth so a rename
  // only ever happens in one place.
  static const usersCollection = 'users';
  static const musiciansCollection = 'musicians';
  static const organizersCollection = 'organizers';
  static const skillsCollection = 'skills';
  static const bookingsCollection = 'bookings';
  static const reviewsCollection = 'reviews';
  static const eventsCollection = 'events';
  static const blogCategoriesCollection = 'blogCategories';
  static const blogPostsCollection = 'blogPosts';
  static const notificationsCollection = 'notifications';

  // --- E-Cards (added Phase 2 — additive only) ---
  // ecards/{ecardId} references events/{eventId} by id; guests live in
  // a subcollection at ecards/{ecardId}/guests/{guestId}. See
  // ecard_provider.dart / firestore_service.dart E-Cards section.
  static const ecardsCollection = 'ecards';
  static const ecardTemplatesCollection = 'ecard_templates';
  static const ecardGuestsSubcollection = 'guests';
  static const ecardRequestsCollection = 'ecard_requests';

  // Storage paths
  static const profilePicturesPath = 'profile_pictures';
  static const musicianMediaPath = 'musician_media';
  static const eventImagesPath = 'event_images';
  static const blogImagesPath = 'blog_images';

  // --- E-Cards (added Phase 2) ---
  static const ecardMediaPath = 'ecard_media';
}

enum UserType { musician, organizer, admin }

enum BookingStatus { pending, accepted, declined, completed, cancelled }

extension BookingStatusX on BookingStatus {
  String get value => name;

  static BookingStatus fromString(String? value) {
    return BookingStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BookingStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

extension UserTypeX on UserType {
  String get value => name;

  static UserType fromString(String? value) {
    return UserType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserType.organizer,
    );
  }
}

/// The occasion an E-Card is built for. Drives which template/fields
/// are shown (see EcardTemplate) and the display-id prefix minted for
/// each guest (see FirestoreService.addEcardGuest). New occasions can
/// be added here without touching the E-Card data layer or UI shell —
/// only a new template document plus a form for its field set.
enum EcardOccasion { wedding, worship, conference, other }

extension EcardOccasionX on EcardOccasion {
  String get value => name;

  static EcardOccasion fromString(String? value) {
    return EcardOccasion.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EcardOccasion.other,
    );
  }

  String get label {
    switch (this) {
      case EcardOccasion.wedding:
        return 'Wedding';
      case EcardOccasion.worship:
        return 'Worship / Ibada';
      case EcardOccasion.conference:
        return 'Conference / Seminar';
      case EcardOccasion.other:
        return 'Other Event';
    }
  }

  /// Prefix used for human-readable guest display IDs, e.g. "WD-0001".
  /// Scoped per E-Card via FirestoreService.addEcardGuest — never a
  /// global counter (see Phase 1 doc, §3, for why Harusi Cards'
  /// single global counter doesn't work once there's more than one
  /// organizer).
  String get guestIdPrefix {
    switch (this) {
      case EcardOccasion.wedding:
        return 'WD';
      case EcardOccasion.worship:
        return 'WS';
      case EcardOccasion.conference:
        return 'CF';
      case EcardOccasion.other:
        return 'EV';
    }
  }
}
