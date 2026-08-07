import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Registers the device FCM token against the user's profile so Cloud
/// Functions can target push notifications for booking status changes,
/// new booking requests, and review reminders.
class FcmService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;

  FcmService({FirebaseMessaging? messaging, FirebaseFirestore? db})
      : _messaging = messaging ?? FirebaseMessaging.instance,
        _db = db ?? FirebaseFirestore.instance;

  Future<void> initForUser(String uid) async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken();
    if (token != null) {
      await _db.collection('users').doc(uid).update({'fcm_token': token});
    }
    _messaging.onTokenRefresh.listen((newToken) {
      _db.collection('users').doc(uid).update({'fcm_token': newToken});
    });
  }

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
}
