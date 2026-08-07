import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/strings.dart';
import '../models/user_profile.dart';

/// Thin wrapper around FirebaseAuth. Never stores or handles raw
/// passwords beyond passing them straight to the Firebase SDK; Firebase
/// Authentication is the sole source of truth for credentials, replacing
/// Django's session/password-hash based auth entirely.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required UserType userType,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;

    // Create the base profile document. Role-specific documents
    // (musicians/{uid} or organizers/{uid}) are created during the
    // profile-setup step that follows registration.
    final profile = UserProfile(
      uid: uid,
      email: email,
      userType: userType,
      displayName: displayName,
    );
    await _firestore.collection(AppStrings.usersCollection).doc(uid).set(profile.toMap());
    await credential.user!.updateDisplayName(displayName);
    return credential;
  }

  Future<UserCredential> loginWithEmail({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> updateEmail(String newEmail) async {
    await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
  }

  Future<void> reauthenticate(String email, String password) async {
    final cred = EmailAuthProvider.credential(email: email, password: password);
    await _auth.currentUser?.reauthenticateWithCredential(cred);
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection(AppStrings.usersCollection).doc(uid).delete();
    await _auth.currentUser?.delete();
  }
}
