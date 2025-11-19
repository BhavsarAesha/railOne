import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:railone/firebase_options.dart';

/// Centralized Firebase initialization and instances
class FirebaseService {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Help mitigate Firestore webchannel 400 errors in restrictive networks
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          ignoreUndefinedProperties: true,
          // Works on web only; ignored on native
          // ignore: deprecated_member_use_from_same_package
          webExperimentalForceLongPolling: true,
          // experimentalForceLongPolling: true,
        );
      } catch (e) {
        print('Firestore settings error (non-critical): $e');
        // Best-effort; ignore if not supported on this platform/version
      }
      _initialized = true;
      print('Firebase initialized successfully');
    } catch (e) {
      print('Firebase initialization failed: $e');
      // Re-throw the error so calling code knows Firebase failed
      throw Exception('Firebase initialization failed: $e');
    }
  }

  /// Shortcut to auth instance
  static FirebaseAuth get auth => FirebaseAuth.instance;
  /// Shortcut to Firestore instance
  static FirebaseFirestore get db => FirebaseFirestore.instance;
}

