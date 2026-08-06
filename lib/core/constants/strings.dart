class AppStrings {
  AppStrings._();

  static const appName = 'LiDeH Live';
  static const tagline = 'Connecting Gospel Musicians with the Church';

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

  // Storage paths
  static const profilePicturesPath = 'profile_pictures';
  static const musicianMediaPath = 'musician_media';
  static const eventImagesPath = 'event_images';
  static const blogImagesPath = 'blog_images';
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
