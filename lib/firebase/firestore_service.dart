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
import '../models/ecard.dart';
import '../models/ecard_guest.dart';
import '../models/ecard_template.dart';

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

  // ---------------- Blog admin ----------------
  /// Unfiltered — includes drafts — for the admin post list. Regular
  /// readers only ever see [watchBlogPosts], which filters to
  /// `is_published: true`.
  Stream<List<BlogPost>> watchAllBlogPostsForAdmin({int limit = 100}) {
    return _db
        .collection(AppStrings.blogPostsCollection)
        .orderBy('published_date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => BlogPost.fromMap(d.id, d.data())).toList());
  }

  Future<String> createBlogPost(BlogPost post) async {
    final ref = await _db.collection(AppStrings.blogPostsCollection).add(post.toMap());
    return ref.id;
  }

  Future<void> setBlogPost(String id, BlogPost post) {
    return _db.collection(AppStrings.blogPostsCollection).doc(id).set(post.toMap());
  }

  Future<void> deleteBlogPost(String id) {
    return _db.collection(AppStrings.blogPostsCollection).doc(id).delete();
  }

  // ---------------- E-Cards (Phase 2 — additive) ----------------
  // Same gateway, same conventions as the sections above: collection
  // names from AppStrings, snake_case Firestore fields, models own
  // fromMap/toMap. ecards/{id} references events/{eventId} by id — the
  // existing Event model and its methods above are untouched.

  CollectionReference<Map<String, dynamic>> _guestsRef(String ecardId) {
    return _db
        .collection(AppStrings.ecardsCollection)
        .doc(ecardId)
        .collection(AppStrings.ecardGuestsSubcollection);
  }

  Future<String> createEcard(Ecard ecard) async {
    final ref = await _db.collection(AppStrings.ecardsCollection).add(ecard.toMap());
    return ref.id;
  }

  Stream<Ecard?> watchEcard(String id) {
    return _db.collection(AppStrings.ecardsCollection).doc(id).snapshots().map(
        (doc) => doc.exists ? Ecard.fromMap(id, doc.data()!) : null);
  }

  Stream<List<Ecard>> watchEcardsForOrganizer(String organizerId) {
    return _db
        .collection(AppStrings.ecardsCollection)
        .where('organizer_id', isEqualTo: organizerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Ecard.fromMap(d.id, d.data())).toList());
  }

  /// One E-Card per event is the expected UI flow (see the "Create an
  /// E-Card for this event?" prompt), but this isn't enforced at the
  /// data layer — kept as a query rather than a doc-id-by-eventId
  /// scheme so nothing here has to change if that changes later.
  ///
  /// Filters by organizer_id as well as event_id — not for the data
  /// (event_id alone is already unique enough), but because Firestore
  /// rules can only allow a *collection query* if the query itself
  /// provably satisfies the rule for every possible match. The rule
  /// checks resource.data.organizer_id == request.auth.uid, so without
  /// this filter present in the query, Firestore rejects the whole
  /// query with permission-denied even though every real result would
  /// individually pass the check.
  Stream<Ecard?> watchEcardForEvent(String eventId, String organizerId) {
    return _db
        .collection(AppStrings.ecardsCollection)
        .where('event_id', isEqualTo: eventId)
        .where('organizer_id', isEqualTo: organizerId)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : Ecard.fromMap(snap.docs.first.id, snap.docs.first.data()));
  }

  Future<void> updateEcardFields(String ecardId, Map<String, dynamic> fields) {
    return _db.collection(AppStrings.ecardsCollection).doc(ecardId).update({
      'fields': fields,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEcard(String ecardId) {
    // Note: does not cascade-delete the guests/ subcollection — that
    // requires either a small Cloud Function or a batched client-side
    // delete of the subcollection before removing the parent doc.
    // Flagged here rather than silently left out; worth a decision in
    // Phase 3 rather than guessed at in the data layer.
    return _db.collection(AppStrings.ecardsCollection).doc(ecardId).delete();
  }

  // ---- E-Card templates (admin/seed-managed, public read) ----

  Stream<List<EcardTemplate>> watchEcardTemplates({EcardOccasion? occasion}) {
    Query<Map<String, dynamic>> query =
        _db.collection(AppStrings.ecardTemplatesCollection).where('is_active', isEqualTo: true);
    if (occasion != null) {
      query = query.where('occasion', isEqualTo: occasion.value);
    }
    return query.snapshots().map(
        (snap) => snap.docs.map((d) => EcardTemplate.fromMap(d.id, d.data())).toList());
  }

  // ---- E-Card guests ----

  Stream<List<EcardGuest>> watchGuestsForEcard(String ecardId) {
    return _guestsRef(ecardId).orderBy('created_at').snapshots().map(
        (snap) => snap.docs.map((d) => EcardGuest.fromMap(d.id, d.data())).toList());
  }

  /// Single-guest watch for the guest card/QR view (Phase 6) — avoids
  /// loading the whole guest list just to show one invitation.
  Stream<EcardGuest?> watchEcardGuest(String ecardId, String guestId) {
    return _guestsRef(ecardId).doc(guestId).snapshots().map(
        (doc) => doc.exists ? EcardGuest.fromMap(doc.id, doc.data()!) : null);
  }

  /// Adds a guest and mints its human-readable display id (e.g.
  /// "WD-0001") from a counter scoped to THIS card only — inside a
  /// transaction, so concurrent adds from the same organizer on two
  /// devices can't collide. This replaces Harusi Cards'
  /// meta/counter, which was a single global document shared by every
  /// wedding (see Phase 1 doc, §3) — that scheme would leak sequence
  /// numbers across unrelated organizers' events if reused as-is.
  Future<EcardGuest> addEcardGuest({
    required String ecardId,
    required EcardOccasion occasion,
    required String fullName,
    String? phone,
    String? category,
  }) async {
    final ecardRef = _db.collection(AppStrings.ecardsCollection).doc(ecardId);
    final guestRef = _guestsRef(ecardId).doc();

    return _db.runTransaction((tx) async {
      final ecardSnap = await tx.get(ecardRef);
      final current = (ecardSnap.data()?['guest_counter'] as num?)?.toInt() ?? 0;
      final next = current + 1;
      final displayId = '${occasion.guestIdPrefix}-${next.toString().padLeft(4, '0')}';

      final guest = EcardGuest(
        id: guestRef.id,
        displayId: displayId,
        fullName: fullName,
        phone: phone,
        category: category,
      );

      tx.update(ecardRef, {'guest_counter': next, 'updated_at': FieldValue.serverTimestamp()});
      tx.set(guestRef, guest.toMap());
      return guest;
    });
  }

  Future<void> updateEcardGuest(String ecardId, String guestId, Map<String, dynamic> data) {
    return _guestsRef(ecardId).doc(guestId).update(data);
  }

  Future<void> deleteEcardGuest(String ecardId, String guestId) {
    return _guestsRef(ecardId).doc(guestId).delete();
  }

  /// Checks a guest in inside a transaction — read-and-verify-then-
  /// write in one atomic step, unlike the original ScanGateFragment's
  /// separate getContributor()-then-updateContributor() calls (see
  /// Phase 1 doc §2). Throws [AlreadyCheckedInException] if the guest
  /// was already checked in, so the scan screen can show the original
  /// check-in time instead of silently double-counting attendance.
  Future<void> checkInEcardGuest(String ecardId, String guestId) async {
    final guestRef = _guestsRef(ecardId).doc(guestId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(guestRef);
      if (!snap.exists) {
        throw StateError('Guest not found');
      }
      final data = snap.data()!;
      if (data['checked_in'] == true) {
        final ts = data['checked_in_time'] as Timestamp?;
        throw AlreadyCheckedInException(ts?.toDate());
      }
      tx.update(guestRef, {
        'checked_in': true,
        'checked_in_time': FieldValue.serverTimestamp(),
      });
    });
  }
}
