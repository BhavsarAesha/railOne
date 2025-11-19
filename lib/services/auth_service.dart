import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:railone/services/firebase_service.dart';

/// Thin wrapper around FirebaseAuth with social sign-in helpers and admin checks
class AuthService {
  final FirebaseAuth _auth = FirebaseService.auth;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signupWithEmailPassword(String email, String password) async {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential?> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success) return null;
    final String token = result.accessToken!.tokenString; // API change: use tokenString
    final OAuthCredential credential = FacebookAuthProvider.credential(token);
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateEmail(String newEmail) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'No authenticated user');
    }
    await user.updateEmail(newEmail);
    await user.reload();
  }

  Future<void> updateDisplayName(String name) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'No authenticated user');
    }
    await user.updateDisplayName(name);
    await user.reload();
  }

  // Admin authentication methods
  Future<UserCredential> adminSignIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    // Verify admin role
    final userDoc = await FirebaseService.db.collection('admins').doc(credential.user!.uid).get();
    if (!userDoc.exists) {
      await _auth.signOut();
      throw FirebaseAuthException(code: 'not-admin', message: 'User is not an admin');
    }
    return credential;
  }

  Future<bool> isAdmin(String uid) async {
    try {
      final userDoc = await FirebaseService.db.collection('admins').doc(uid).get();
      return userDoc.exists;
    } catch (e) {
      return false;
    }
  }
}

