import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/auth_service.dart';
import '../firebase/fcm_service.dart';
import '../firebase/firestore_service.dart';
import '../firebase/storage_service.dart';
import '../models/user_profile.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());

/// Live Firebase auth state — drives route protection in app_router.dart.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// The signed-in user's application profile (role, bio, etc.), kept in
/// sync with Firestore in real time.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).watchUser(user.uid);
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).value != null;
});
