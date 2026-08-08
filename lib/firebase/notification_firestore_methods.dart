import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/strings.dart';
import '../models/notification.dart';

/// Adds notification-inbox methods on top of the existing
/// FirestoreService. Kept in a separate file and mixed in via
/// extension rather than editing the large firestore_service.dart
/// directly, to keep this feature's diff self-contained.
extension NotificationFirestoreMethods on FirebaseFirestore {
  Stream<List<AppNotification>> watchNotificationsForUser(String uid) {
    return collection(AppStrings.notificationsCollection)
        .where('user_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList());
  }

  Future<void> markNotificationRead(String id) {
    return collection(AppStrings.notificationsCollection).doc(id).update({'read': true});
  }
}
