import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:railone/services/firebase_service.dart';

class AdminSetup {
  static final FirebaseAuth _auth = FirebaseService.auth;
  static final FirebaseFirestore _db = FirebaseService.db;

  /// Create an admin user in Firebase
  /// Call this function once to set up the admin user
  static Future<void> createAdminUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create the user in Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set display name
      await userCredential.user!.updateDisplayName(name);

      // Create admin document in Firestore
      await _db.collection('admins').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'role': 'admin',
        'createdAt': DateTime.now().toIso8601String(),
        'permissions': [
          'manage_users',
          'manage_bookings',
          'manage_trains',
          'manage_grievances',
          'view_analytics',
        ],
      });

      print('Admin user created successfully!');
      print('Email: $email');
      print('Password: $password');
      print('UID: ${userCredential.user!.uid}');
    } catch (e) {
      print('Failed to create admin user: $e');
      rethrow;
    }
  }

  /// Check if a user is an admin
  static Future<bool> isUserAdmin(String uid) async {
    try {
      final DocumentSnapshot doc = await _db.collection('admins').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Get admin user details
  static Future<Map<String, dynamic>?> getAdminDetails(String uid) async {
    try {
      final DocumentSnapshot doc = await _db.collection('admins').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting admin details: $e');
      return null;
    }
  }

  /// List all admin users
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final QuerySnapshot snapshot = await _db.collection('admins').get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting all admins: $e');
      return [];
    }
  }
}
