import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/strings.dart';
import '../models/user_profile.dart';
import '../models/musician.dart';
import '../models/organizer.dart';
import '../models/skill.dart';
import '../models/booking.dart';
import '../models/event.dart';
import '../models/review.dart';
import '../models/blog_category.dart';
import '../models/blog_post.dart';

/// Single point of access to Cloud Firestore. Screens/providers never
/// talk to `FirebaseFirestore.instance` directly — everything routes
/// through here so query shape and security assumptions live in one
/// place, keeping reads efficient and consistent with firestore.rules.
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // ---------------- Users ----------------
  Future<UserProfile?> getUser(String uid) async {
    final doc = await _db.collection(AppStrings.usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(uid, doc.data()!);
  }

  Stream<UserProfile?> watchUser(String uid) {
    return _db.collection(AppStrings.usersCollection).doc(uid).snapshots().map(
        (doc) => doc.exists ? UserProfile.fromMap(uid, doc.data()!) : null);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return _db.collection(AppStrings.usersCollection).doc(uid).update(data);
  }

  // ---------------- Musicians ----------------
  Future<void> setMusicianProfile(Musician musician) {
    return _db.collection(AppStrings.musiciansCollection).doc(musician.uid).set(musician.toMap(), SetOptions(merge: true));
  }

  Stream<Musician?> watchMusician(String uid) {
    return _db.collection(AppStrings.musiciansCollection).doc(uid).snapshots().map(
        (doc) => doc.exists ? Musician.fromMap(uid, doc.data()!) : null);
  }

  Future<Musician?> getMusician(String uid) async {
    final doc = await _db.collection(AppStrings.musiciansCollection).doc(uid).get();
    if (!doc.exists) return null;
    return Musician.fromMap(uid, doc.data()!);
  }

  /// Discovery query. Firestore can't do case-insensitive "contains"
  /// search server-side, so location filtering is done with a
  /// range-prefix query and skill filtering with `array-contains`,
  /// then any free-text refinement happens client-side on the (small)
  /// result page — this keeps reads bounded instead of scanning
  /// everything.
  Stream<List<Musician>> watchMusicians({String? location, String? skill, int limit = 50}) {
    Query<Map<String, dynamic>> query = _db.collection(AppStrings.musiciansCollection);
    if (skill != null && skill.isNotEmpty) {
      query = query.where('skills', arrayContains: skill);
    }
    if (location != null && location.isNotEmpty) {
      query = query.orderBy('location').startAt([location]).endAt(['$location\uf8ff']);
    } else {
      query = query.orderBy('joined_at', descending: true);
    }
    return query.limit(limit).snapshots().map(
        (snap) => snap.docs.map((d) => Musician.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Musician>> watchFeaturedMusicians({int limit = 3}) {
    return _db
        .collection(AppStrings.musiciansCollection)
        .orderBy('avg_rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Musician.fromMap(d.id, d.data())).toList());
  }

  // ---------------- Organizers ----------------
  Future<void> setOrganizerProfile(Organizer organizer) {
    return _db.collection(AppStrings.organizersCollection).doc(organizer.uid).set(organizer.toMap(), SetOptions(merge: true));
  }

  Stream<Organizer?> watchOrganizer(String uid) {
    return _db.collection(AppStrings.organizersCollection).doc(uid).snapshots().map(
        (doc) => doc.exists ? Organizer.fromMap(uid, doc.data()!) : null);
  }

  // ---------------- Skills ----------------
  Stream<List<Skill>> watchSkills() {
    return _db.collection(AppStrings.skillsCollection).orderBy('name').snapshots().map(
        (snap) => snap.docs.map((d) => Skill.fromMap(d.id, d.data())).toList());
  }

  // ---------------- Bookings ----------------
  Future<String> createBooking(Booking booking) async {
    final ref = await _db.collection(AppStrings.bookingsCollection).add(booking.toMap());
    return ref.id;
  }

  Future<void> updateBookingStatus(String bookingId, String status) {
    return _db.collection(AppStrings.bookingsCollection).doc(bookingId).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<Booking?> watchBooking(String id) {
    return _db.collection(AppStrings.bookingsCollection).doc(id).snapshots().map(
        (doc) => doc.exists ? Booking.fromMap(id, doc.data()!) : null);
  }

  Stream<List<Booking>> watchBookingsForMusician(String musicianId) {
    return _db
        .collection(AppStrings.bookingsCollection)
        .where('musician_id', isEqualTo: musicianId)
        .orderBy('event_date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Booking>> watchBookingsForOrganizer(String organizerId) {
    return _db
        .collection(AppStrings.bookingsCollection)
        .where('organizer_id', isEqualTo: organizerId)
        .orderBy('event_date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList());
  }

  // ---------------- Reviews ----------------
  Future<void> submitReview(Review review) async {
    final batch = _db.batch();
    final reviewRef = _db.collection(AppStrings.reviewsCollection).doc(review.bookingId);
    batch.set(reviewRef, review.toMap());
    final bookingRef = _db.collection(AppStrings.bookingsCollection).doc(review.bookingId);
    batch.update(bookingRef, {'review_submitted': true});
    await batch.commit();
    // Recompute the musician's aggregate rating from all their reviews.
    await _recomputeMusicianRating(review.musicianId);
  }

  Future<void> _recomputeMusicianRating(String musicianId) async {
    final snap = await _db.collection(AppStrings.reviewsCollection).where('musician_id', isEqualTo: musicianId).get();
    if (snap.docs.isEmpty) return;
    final ratings = snap.docs.map((d) => (d.data()['rating'] as num).toDouble());
    final avg = ratings.reduce((a, b) => a + b) / ratings.length;
    await _db.collection(AppStrings.musiciansCollection).doc(musicianId).update({
      'avg_rating': avg,
      'review_count': snap.docs.length,
    });
  }

  Stream<List<Review>> watchReviewsForMusician(String musicianId) {
    return _db
        .collection(AppStrings.reviewsCollection)
        .where('musician_id', isEqualTo: musicianId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList());
  }

  // ---------------- Events ----------------
  Future<String> createEvent(Event event) async {
    final ref = await _db.collection(AppStrings.eventsCollection).add(event.toMap());
    return ref.id;
  }

  Stream<List<Event>> watchUpcomingEvents({int limit = 50}) {
    final now = Timestamp.fromDate(DateTime.now());
    return _db
        .collection(AppStrings.eventsCollection)
        .where('date', isGreaterThanOrEqualTo: now)
        .where('is_cancelled', isEqualTo: false)
        .orderBy('date')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Event.fromMap(d.id, d.data())).toList());
  }

  Stream<Event?> watchEvent(String id) {
    return _db.collection(AppStrings.eventsCollection).doc(id).snapshots().map(
        (doc) => doc.exists ? Event.fromMap(id, doc.data()!) : null);
  }

  Stream<List<Event>> watchEventsForOrganizer(String organizerId) {
    return _db
        .collection(AppStrings.eventsCollection)
        .where('organizer_id', isEqualTo: organizerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Event.fromMap(d.id, d.data())).toList());
  }

  // ---------------- Blog ----------------
  Stream<List<BlogCategory>> watchBlogCategories() {
    return _db.collection(AppStrings.blogCategoriesCollection).orderBy('name').snapshots().map(
        (snap) => snap.docs.map((d) => BlogCategory.fromMap(d.id, d.data())).toList());
  }

  Stream<List<BlogPost>> watchBlogPosts({String? categoryId, int limit = 30}) {
    Query<Map<String, dynamic>> query = _db
        .collection(AppStrings.blogPostsCollection)
        .where('is_published', isEqualTo: true);
    if (categoryId != null) {
      query = query.where('category_id', isEqualTo: categoryId);
    }
    return query.orderBy('published_date', descending: true).limit(limit).snapshots().map(
        (snap) => snap.docs.map((d) => BlogPost.fromMap(d.id, d.data())).toList());
  }

  Stream<BlogPost?> watchBlogPost(String id) {
    return _db.collection(AppStrings.blogPostsCollection).doc(id).snapshots().map(
        (doc) => doc.exists ? BlogPost.fromMap(id, doc.data()!) : null);
  }
}
