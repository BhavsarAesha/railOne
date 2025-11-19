import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:railone/services/firebase_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseService.db;

  Future<void> upsertUserProfile(String uid, Map<String, dynamic> data) async {
    final DocumentReference<Map<String, dynamic>> ref = _db.collection('users').doc(uid);
    await ref.set(data, SetOptions(merge: true)).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firestore operation timed out');
      },
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snap = await _db.collection('users').doc(uid).get().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firestore operation timed out');
      },
    );
    return snap.data();
  }

  Future<void> createBooking(String uid, Map<String, dynamic> booking) async {
    await _db.collection('users').doc(uid).collection('bookings').add(booking);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenBookings(String uid) {
    return _db.collection('users').doc(uid).collection('bookings').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> addWalletTransaction(String uid, Map<String, dynamic> txn) async {
    await _db.collection('users').doc(uid).collection('wallet').add(txn);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenWallet(String uid) {
    return _db.collection('users').doc(uid).collection('wallet').orderBy('createdAt', descending: true).snapshots();
  }

  // Notifications per user
  Stream<QuerySnapshot<Map<String, dynamic>>> listenNotifications(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<int> listenUnreadNotificationsCount(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // Feedback
  Future<String> addFeedback(String uid, {
    required String subject,
    required String message,
    int rating = 0,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _db.collection('feedbacks').doc();
    await ref.set({
      'id': ref.id,
      'uid': uid,
      'subject': subject,
      'message': message,
      'rating': rating,
      'createdAt': DateTime.now().toIso8601String(),
    }).timeout(const Duration(seconds: 10), onTimeout: () => throw Exception('Firestore operation timed out'));
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenUserFeedbacks(String uid) {
    return _db.collection('feedbacks').where('uid', isEqualTo: uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllFeedbacks() {
    return _db.collection('feedbacks').snapshots();
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    final WriteBatch batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> addNotification(String uid, {required String title, required String body}) async {
    await _db.collection('users').doc(uid).collection('notifications').add({
      'title': title,
      'body': body,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firestore operation timed out');
      },
    );
  }

  Future<int> sendNotificationToAll({required String title, required String body}) async {
    final QuerySnapshot<Map<String, dynamic>> users = await _db.collection('users').get().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Firestore operation timed out');
      },
    );
    final WriteBatch batch = _db.batch();
    for (final doc in users.docs) {
      final CollectionReference<Map<String, dynamic>> notifs = _db.collection('users').doc(doc.id).collection('notifications');
      final DocumentReference<Map<String, dynamic>> ref = notifs.doc();
      batch.set(ref, {
        'title': title,
        'body': body,
        'createdAt': DateTime.now().toIso8601String(),
        'read': false,
      });
    }
    await batch.commit();
    return users.size;
  }

  // Admin methods for user management
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return _db.collection('users').snapshots();
  }

  Future<Map<String, dynamic>?> getUserDetails(String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snap = await _db.collection('users').doc(uid).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firestore operation timed out');
        },
      );
      return snap.data();
    } catch (e) {
      print('Failed to get user details: $e');
      return null;
    }
  }

  // Admin methods for booking management
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllBookings() {
    return _db.collectionGroup('bookings').snapshots();
  }

  // Root-level bookings collection for admin/global queries
  Future<void> addRootBooking(Map<String, dynamic> booking) async {
    await _db.collection('bookings').doc(booking['id'] as String?).set({
      ...booking,
      'createdAt': booking['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firestore operation timed out');
      },
    );
  }

  // Get all PNR records for admin
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllPnrRecords() {
    return _db.collection('pnr_records').snapshots();
  }

  // Payments
  Future<void> addPayment(Map<String, dynamic> payment) async {
    final String docId = payment['id'] as String? ?? _db.collection('_').doc().id;
    await _db.collection('payments').doc(docId).set({
      ...payment,
      'id': docId,
      'createdAt': payment['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firestore operation timed out');
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllPayments() {
    return _db.collection('payments').orderBy('createdAt', descending: true).snapshots();
  }

  // Note: Food ordering module APIs required by Admin screen
  // Kept minimal and generic so the app compiles and admins can inspect orders.
  Future<void> seedRestaurantsWithMenu({int restaurants = 5, int itemsPerRestaurant = 10}) async {
    final WriteBatch batch = _db.batch();
    for (int r = 0; r < restaurants; r++) {
      final DocumentReference<Map<String, dynamic>> restaurantRef = _db.collection('restaurants').doc();
      batch.set(restaurantRef, {
        'id': restaurantRef.id,
        'name': 'Restaurant ${r + 1}',
        'rating': 4 + (r % 2) * 0.5,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      for (int i = 0; i < itemsPerRestaurant; i++) {
        final DocumentReference<Map<String, dynamic>> itemRef = restaurantRef.collection('menu').doc();
        batch.set(itemRef, {
          'id': itemRef.id,
          'name': 'Item ${i + 1}',
          'price': 50 + (i * 5),
          'veg': i % 2 == 0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    }
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenAllOrders() {
    return _db.collection('orders').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firestore operation timed out');
      },
    );
  }

  // Seat inventory APIs
  Future<void> ensureSeatMap({
    required String trainNumber,
    required String journeyDate,
    int totalSeats = 72,
    List<String>? coaches,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _db
        .collection('trains')
        .doc(trainNumber)
        .collection('seatMaps')
        .doc(journeyDate);
    final snap = await ref.get();
    if (!snap.exists) {
      final List<String> coachList = coaches ?? List<String>.generate(14, (i) => 'B${i + 1}');
      await ref.set({
        'trainNumber': trainNumber,
        'date': journeyDate,
        'totalSeats': totalSeats, // per coach
        'coaches': coachList,
        'booked': <int>[], // legacy support (single coach model)
        'bookedCodes': <String>[], // preferred: ["B1-27", ...]
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> listenSeatMap({
    required String trainNumber,
    required String journeyDate,
  }) {
    final DocumentReference<Map<String, dynamic>> ref = _db
        .collection('trains')
        .doc(trainNumber)
        .collection('seatMaps')
        .doc(journeyDate);
    return ref.snapshots();
  }

  Future<bool> reserveSeats({
    required String trainNumber,
    required String journeyDate,
    required List<int> seats,
    required String bookingId,
    required String userId,
  }) async {
    if (seats.isEmpty) return false;
    final DocumentReference<Map<String, dynamic>> ref = _db
        .collection('trains')
        .doc(trainNumber)
        .collection('seatMaps')
        .doc(journeyDate);
    return _db.runTransaction<bool>((transaction) async {
      final snap = await transaction.get(ref);
      final Map<String, dynamic> data = snap.data() ?? {};
      final List<dynamic> booked = List<dynamic>.from(data['booked'] as List? ?? <dynamic>[]);
      // Check for conflicts
      for (final s in seats) {
        if (booked.contains(s)) {
          return false; // conflict detected
        }
      }
      final List<int> updated = <int>[...booked.cast<int>(), ...seats];
      transaction.update(ref, {
        'booked': updated,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      // Optional: write reservation record
      final DocumentReference<Map<String, dynamic>> resRef = ref.collection('reservations').doc(bookingId);
      transaction.set(resRef, {
        'bookingId': bookingId,
        'userId': userId,
        'seats': seats,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    });
  }

  Future<bool> reserveSeatCodes({
    required String trainNumber,
    required String journeyDate,
    required List<String> seatCodes,
    required String bookingId,
    required String userId,
  }) async {
    if (seatCodes.isEmpty) return false;
    final DocumentReference<Map<String, dynamic>> ref = _db
        .collection('trains')
        .doc(trainNumber)
        .collection('seatMaps')
        .doc(journeyDate);
    return _db.runTransaction<bool>((transaction) async {
      final snap = await transaction.get(ref);
      final Map<String, dynamic> data = snap.data() ?? {};
      final List<dynamic> bookedCodes = List<dynamic>.from(data['bookedCodes'] as List? ?? <dynamic>[]);
      // conflict detection
      for (final code in seatCodes) {
        if (bookedCodes.contains(code)) {
          return false;
        }
      }
      final List<String> updated = <String>[...bookedCodes.cast<String>(), ...seatCodes];
      transaction.update(ref, {
        'bookedCodes': updated,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      final DocumentReference<Map<String, dynamic>> resRef = ref.collection('reservations').doc(bookingId);
      transaction.set(resRef, {
        'bookingId': bookingId,
        'userId': userId,
        'seatCodes': seatCodes,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    });
  }

  Future<List<Map<String, dynamic>>> getUserBookings(String uid) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _db
          .collection('users')
          .doc(uid)
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Firestore operation timed out');
            },
          );
      return snap.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Failed to get user bookings: $e');
      return [];
    }
  }

  // Admin methods for train management
  Future<void> addTrain(Map<String, dynamic> trainData) async {
    await _db.collection('trains').add({
      ...trainData,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firestore operation timed out');
      },
    );
  }

  Future<void> updateTrain(String trainId, Map<String, dynamic> trainData) async {
    await _db.collection('trains').doc(trainId).update({
      ...trainData,
      'updatedAt': DateTime.now().toIso8601String(),
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firestore operation timed out');
      },
    );
  }

  Future<void> deleteTrain(String trainId) async {
    await _db.collection('trains').doc(trainId).delete().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firestore operation timed out');
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllTrains() {
    return _db.collection('trains').orderBy('createdAt', descending: true).snapshots();
  }

  Future<Map<String, dynamic>?> getTrainByNumber(String trainNumber) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _db
          .collection('trains')
          .where('number', isEqualTo: trainNumber)
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Firestore operation timed out'),
          );
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data();
    } catch (e) {
      print('getTrainByNumber error: $e');
      return null;
    }
  }

  // Admin methods for grievance management
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllGrievances() {
    return _db.collectionGroup('grievances').snapshots();
  }

  Future<void> updateGrievanceStatus(String grievanceId, String status) async {
    final DocumentReference<Map<String, dynamic>> ref = _db.collection('grievances').doc(grievanceId);
    await ref.update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firestore operation timed out');
      },
    );
    try {
      // Notify the grievance owner if we can fetch uid
      final snap = await ref.get();
      final String? uid = snap.data()?['uid'] as String?;
      if (uid != null) {
        await addNotification(uid, title: 'Grievance Resolved', body: 'Your complaint has been marked as resolved.');
      }
    } catch (_) {}
  }

  Future<String> addGrievance(String uid, {
    required String category,
    required String subject,
    required String description,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _db.collection('grievances').doc();
    await ref.set({
      'id': ref.id,
      'uid': uid,
      'category': category,
      'subject': subject,
      'description': description,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Firestore operation timed out'),
    );
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenUserGrievances(String uid) {
    // Avoid composite index requirement by not ordering in Firestore; sort client-side
    return _db
        .collection('grievances')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }

  // Cancel booking functionality
  Future<void> cancelBooking(String userId, String bookingId) async {
    await _db.collection('users').doc(userId).collection('bookings').doc(bookingId).update({
      'status': 'cancelled',
      'cancelledAt': DateTime.now().toIso8601String(),
    }).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firestore operation timed out');
      },
    );
  }

  // Get user bookings with status filter
  Future<List<Map<String, dynamic>>> getUserBookingsWithStatus(String uid, {String? status}) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection('users')
          .doc(uid)
          .collection('bookings')
          .orderBy('createdAt', descending: true);
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      final QuerySnapshot<Map<String, dynamic>> snap = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firestore operation timed out');
        },
      );
      return snap.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Failed to get user bookings: $e');
      return [];
    }
  }
}

