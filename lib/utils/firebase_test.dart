import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:railone/services/firebase_service.dart';

class FirebaseTest {
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};
    
    try {
      // Test 1: Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      results['auth_user'] = user?.email ?? 'No user logged in';
      results['auth_uid'] = user?.uid ?? 'No UID';
      
      // Test 2: Firestore write
      final testDoc = await FirebaseService.db
          .collection('test')
          .doc('connection_test')
          .set({
        'timestamp': DateTime.now().toIso8601String(),
        'test': 'Firebase connection working',
      });
      results['firestore_write'] = 'Success';
      
      // Test 3: Firestore read
      final doc = await FirebaseService.db
          .collection('test')
          .doc('connection_test')
          .get();
      results['firestore_read'] = doc.exists ? 'Success' : 'Failed';
      
      // Test 4: Storage access
      try {
        final storage = FirebaseStorage.instance;
        final ref = storage.ref().child('test/connection.txt');
        await ref.putString('Firebase Storage working');
        results['storage_write'] = 'Success';
        
        final url = await ref.getDownloadURL();
        results['storage_read'] = url.isNotEmpty ? 'Success' : 'Failed';
      } catch (e) {
        results['storage_error'] = e.toString();
      }
      
      // Test 5: Mail collection write
      try {
        final mailDoc = await FirebaseService.db.collection('mail').add({
          'to': 'test@example.com',
          'subject': 'Test Email',
          'message': {'subject': 'Test', 'html': 'Test'},
          'createdAt': DateTime.now().toIso8601String(),
        });
        results['mail_write'] = 'Success - ID: ${mailDoc.id}';
      } catch (e) {
        results['mail_error'] = e.toString();
      }
      
    } catch (e) {
      results['error'] = e.toString();
    }
    
    return results;
  }
}
