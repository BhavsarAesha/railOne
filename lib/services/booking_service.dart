import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:railone/models/booking.dart';
import 'package:railone/models/pnr.dart';
import 'package:railone/services/firebase_service.dart';
import 'package:railone/services/firestore_service.dart';
import 'package:railone/services/pnr_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class BookingService {
  final FirebaseAuth _auth = FirebaseService.auth;
  static final List<Booking> _memoryFallback = <Booking>[];

  Future<bool> saveBooking(Booking booking) async {
    try {
      // Initialize Firebase early
      await FirebaseService.ensureInitialized();
      final FirebaseFirestore db = FirebaseService.db;

      // Ensure we have an authenticated user; fallback to anonymous sign-in
      User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found. Signing in anonymously...');
        try {
          final cred = await _auth.signInAnonymously();
          user = cred.user;
        } catch (e) {
          print('Anonymous sign-in failed: $e');
          // As a last resort, keep using memory fallback
          _memoryFallback.add(booking);
          return false;
        }
      }
      final String? uid = user?.uid;
      if (uid == null) {
        print('Failed to obtain UID after sign-in');
        _memoryFallback.add(booking);
        return false;
      }
      // Safe non-null user instance for the rest of this method
      final User userN = user!;
      
      // Generate PNR for the booking
      String pnr;
      try {
        pnr = PnrService.generatePnr();
        print('Generated PNR: $pnr');
      } catch (e) {
        print('Error generating PNR: $e');
        // Fallback PNR generation
        pnr = DateTime.now().millisecondsSinceEpoch.toString().substring(3); // Last 10 digits
        print('Using fallback PNR: $pnr');
      }
      
      // Add user information to booking
      final bookingWithUser = Booking(
        id: booking.id,
        trainNumber: booking.trainNumber,
        trainName: booking.trainName,
        from: booking.from,
        to: booking.to,
        departureTime: booking.departureTime,
        arrivalTime: booking.arrivalTime,
        createdAt: booking.createdAt,
        amount: booking.amount,
        quantity: booking.quantity,
        status: booking.status,
        userId: uid,
        userName: userN.displayName ?? 'Unknown User',
        userEmail: userN.email ?? 'No email',
        pnr: pnr,
        journeyDate: booking.journeyDate,
        seats: booking.seats,
        seatCodes: booking.seatCodes,
        passengers: booking.passengers,
      );
      
      print('Saving booking to Firebase...');
      // Save booking to Firebase (user subcollection)
      await db.collection('users').doc(uid).collection('bookings').doc(booking.id).set(bookingWithUser.toJson());
      // Save booking also to root collection for admin/global queries
      try {
        await FirestoreService().addRootBooking(bookingWithUser.toJson());
      } catch (e) {
        print('Warning: failed to add root booking: $e');
      }
      print('Booking saved successfully to Firebase');
      
      // Create PNR record with passenger data
      final List<Map<String, dynamic>> pnrPassengers = (booking.passengers != null && booking.passengers!.isNotEmpty)
          ? List<Map<String, dynamic>>.generate(booking.passengers!.length, (index) {
              final p = booking.passengers![index];
              return {
                'name': p['name'] ?? 'Passenger ${index + 1}',
                'age': p['age'] ?? 0,
                'gender': p['gender'] ?? 'N/A',
                'mobile': p['mobile'] ?? '',
                'coach': booking.seatCodes != null && booking.seatCodes!.isNotEmpty ? (booking.seatCodes![index % booking.seatCodes!.length].split('/').elementAt(1)) : 'B${index + 1}',
                'seat': booking.seatCodes != null && booking.seatCodes!.isNotEmpty
                    ? int.tryParse((booking.seatCodes![index % booking.seatCodes!.length].split('/').elementAt(2))) ?? (10 + index)
                    : (10 + index),
                'berth': booking.seatCodes != null && booking.seatCodes!.isNotEmpty
                    ? (booking.seatCodes![index % booking.seatCodes!.length].split('/').elementAt(3))
                    : ['LB', 'MB', 'UB'][index % 3],
                'bookingStatus': 'CNF',
                'currentStatus': 'Confirmed',
              };
            })
          : List<Map<String, dynamic>>.generate(
              booking.quantity,
              (index) => {
                'name': '${userN.displayName ?? 'Passenger'} ${index + 1}',
                'age': 25 + (index * 5),
                'gender': index % 2 == 0 ? 'Male' : 'Female',
                'mobile': '',
                'coach': 'B${index + 1}',
                'seat': 10 + (index * 2),
                'berth': ['LB', 'MB', 'UB'][index % 3],
                'bookingStatus': 'CNF',
                'currentStatus': 'Confirmed',
              },
            );
      
      // Generate payment data
      final random = Random();
      final paymentMethods = ['Credit Card', 'Debit Card', 'UPI', 'Net Banking', 'Wallet'];
      final cardNumbers = ['4111****1111', '5555****4444', '3782****10005', '6011****1117', '4000****5556'];
      final transactionIds = ['TXN${DateTime.now().millisecondsSinceEpoch}', 'TXN${random.nextInt(999999)}'];
      final paymentStatuses = ['Success', 'Success', 'Success', 'Pending'];
      
      final paymentData = {
        'paymentMethod': paymentMethods[random.nextInt(paymentMethods.length)],
        'cardNumber': cardNumbers[random.nextInt(cardNumbers.length)],
        'transactionId': transactionIds[random.nextInt(transactionIds.length)],
        'paymentStatus': paymentStatuses[random.nextInt(paymentStatuses.length)],
        'paymentDate': DateTime.now().toIso8601String().split('T')[0],
      };
      
      print('Saving PNR record to Firebase...');
      // Store PNR record in Firebase with payment data
      await db.collection('pnr_records').doc(pnr).set({
        'pnr': pnr,
        'trainNumber': booking.trainNumber,
        'trainName': booking.trainName,
        'journeyDate': booking.departureTime.split(' ')[0],
        'from': booking.from,
        'to': booking.to,
        'passengers': pnrPassengers,
        'trainStatus': 'On Time',
        'chartStatus': 'Chart Prepared',
        'departureTime': booking.departureTime,
        'arrivalTime': booking.arrivalTime,
        'platform': '${random.nextInt(8) + 1}',
        'coachPosition': ['Front', 'Middle', 'Rear'][random.nextInt(3)],
        'bookingClass': ['SL', '3A', '2A', '1A'][random.nextInt(4)],
        'fare': booking.amount.toString(),
        'quantity': booking.quantity,
        'ticketPrice': (booking.amount / (booking.quantity == 0 ? 1 : booking.quantity)).toStringAsFixed(0),
        'bookingDate': booking.createdAt.toIso8601String().split('T')[0],
        'boardingStation': booking.from,
        'destinationStation': booking.to,
        'journeyClass': ['SL', '3A', '2A', '1A'][random.nextInt(4)],
        'quota': ['GN', 'TQ', 'LD', 'HP'][random.nextInt(4)],
        'currentStatus': 'Confirmed',
        'lastUpdated': DateTime.now().toIso8601String(),
        'userId': uid,
        'userName': userN.displayName ?? 'Unknown User',
        'userEmail': userN.email ?? 'No email',
        ...paymentData,
      });
      
      // Create a payment record in payments collection
      try {
        await FirestoreService().addPayment({
          'bookingId': booking.id,
          'userId': uid,
          'userName': userN.displayName ?? 'Unknown User',
          'userEmail': userN.email ?? 'No email',
          'pnr': pnr,
          'amount': booking.amount,
          'quantity': booking.quantity,
          'trainNumber': booking.trainNumber,
          'trainName': booking.trainName,
          'from': booking.from,
          'to': booking.to,
          'paymentMethod': paymentData['paymentMethod'],
          'transactionId': paymentData['transactionId'],
          'paymentStatus': paymentData['paymentStatus'],
          'paymentDate': paymentData['paymentDate'],
          'createdAt': booking.createdAt.toIso8601String(),
        });
      } catch (e) {
        print('Warning: failed to add payment record: $e');
      }
      
      print('PNR record saved successfully to Firebase');
      // Generate PDF and email the ticket
      try {
        final Map<String, String> ticket = await _generateAndUploadTicketPdf(bookingWithUser, pnr);
        await _enqueueTicketEmail(
          toEmail: userN.email ?? '',
          subject: 'Your Ticket ${bookingWithUser.id} - ${bookingWithUser.trainNumber}',
          html: _buildEmailHtml(bookingWithUser, pnr, ticket['url'] ?? ''),
          attachments: [
            {
              'filename': 'Ticket-${bookingWithUser.id}.pdf',
              // Firebase Trigger Email expects a Cloud Storage path (gs://...)
              'path': ticket['gsPath'] ?? '',
            }
          ],
        );
        print('Email queued successfully for ${userN.email}');
      } catch (e) {
        print('Warning: failed to generate/send ticket email: $e');
        // Don't fail the booking if email fails
      }
      
      // Notify user about successful booking
      try {
        await FirestoreService().addNotification(uid,
            title: 'Booking Confirmed',
            body: 'Your booking ${booking.id} for ${booking.trainNumber} • ${booking.trainName} is confirmed. PNR $pnr.');
      } catch (e) {
        print('Warning: failed to send booking notification: $e');
      }
      return true;
    } catch (e) {
      print('Error saving to Firebase: $e');
      // Only fallback to memory if Firebase completely fails
      _memoryFallback.add(booking);
      return false;
    }
  }

  Future<Map<String, String>> _generateAndUploadTicketPdf(Booking booking, String pnr) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('RailOne Ticket', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('PNR: $pnr', style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 16),
                pw.Text('${booking.trainNumber} • ${booking.trainName}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text('${booking.from} → ${booking.to}'),
                pw.Text('Departure: ${booking.departureTime}'),
                pw.Text('Arrival: ${booking.arrivalTime}'),
                pw.SizedBox(height: 12),
                if (booking.seatCodes != null && booking.seatCodes!.isNotEmpty)
                  pw.Text('Seats: ${booking.seatCodes!.join(', ')}'),
                pw.SizedBox(height: 12),
                pw.Text('Quantity: ${booking.quantity}'),
                pw.Text('Amount: ₹${booking.amount.toStringAsFixed(0)}'),
                pw.SizedBox(height: 24),
                pw.Text('Passenger: ${booking.userName ?? ''}'),
                pw.Text('Email: ${booking.userEmail ?? ''}'),
                pw.SizedBox(height: 24),
                pw.Text('Thank you for booking with RailOne!'),
              ],
            ),
          );
        },
      ),
    );
    final bytes = await doc.save();
    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final ref = storage.ref().child('tickets/${booking.userId}/${booking.id}.pdf');
      await ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
      final String url = await ref.getDownloadURL();
      final String bucket = storage.bucket; // e.g., your-project.appspot.com
      final String gsPath = 'gs://$bucket/tickets/${booking.userId}/${booking.id}.pdf';
      print('PDF uploaded to: $url');
      return {'url': url, 'gsPath': gsPath};
    } catch (e) {
      print('PDF upload failed: $e');
      // Return fallback values
      return {'url': '', 'gsPath': ''};
    }
  }

  Future<void> _enqueueTicketEmail({
    required String toEmail,
    required String subject,
    required String html,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      final doc = await FirebaseService.db.collection('mail').add({
        'to': toEmail,
        'message': {
          'subject': subject,
          'html': html,
        },
        if (attachments.isNotEmpty) 'attachments': attachments,
        'createdAt': DateTime.now().toIso8601String(),
      });
      print('Email document created with ID: ${doc.id}');
    } catch (e) {
      print('Enqueue email failed: $e');
      rethrow; // Let caller handle the error
    }
  }

  String _buildEmailHtml(Booking booking, String pnr, String pdfUrl) {
    final seatsHtml = (booking.seatCodes != null && booking.seatCodes!.isNotEmpty)
        ? '<p><strong>Coach:</strong> ${booking.selectedCoach ?? '-'}<br/><strong>Seats:</strong> ${booking.seatCodes!.join(', ')}</p>'
        : '';
    final passengersHtml = (booking.passengers != null && booking.passengers!.isNotEmpty)
        ? '<div style="margin-top:12px"><strong>Passengers</strong><ul style="margin:6px 0 0 18px">' +
            booking.passengers!
                .map((p) => '<li>${p['name'] ?? 'Passenger'} — ${p['gender'] ?? '-'}, ${p['age'] ?? '-'} yrs, ${p['mobile'] ?? ''}</li>')
                .join()
            + '</ul></div>'
        : '';
    return '''
    <div style="font-family:Arial,sans-serif;font-size:14px;color:#222">
      <h2 style="margin:0 0 8px">Ticket Confirmed</h2>
      <p style="margin:0 0 8px"><strong>PNR:</strong> $pnr</p>
      <p style="margin:0 0 4px"><strong>${booking.trainNumber}</strong> • ${booking.trainName}</p>
      <p style="margin:0 0 8px"><strong>Route:</strong> ${booking.from} → ${booking.to}</p>
      <p style="margin:0 0 8px"><strong>Departure:</strong> ${booking.departureTime} &nbsp; <strong>Arrival:</strong> ${booking.arrivalTime}</p>
      $seatsHtml
      <p style="margin:8px 0"><strong>Tickets:</strong> ${booking.quantity} &nbsp; <strong>Amount:</strong> ₹${booking.amount.toStringAsFixed(0)}</p>
      $passengersHtml
      <div style="margin-top:14px;padding:12px;background:#f7f7f7;border:1px solid #eee;border-radius:6px">
        <p style="margin:0 0 6px">Your ticket PDF is ready:</p>
        <p style="margin:0"><a href="$pdfUrl">Download Ticket PDF</a></p>
      </div>
      <p style="margin-top:16px;color:#555">Thank you for choosing RailOne. Wish you a pleasant journey!</p>
    </div>
    ''';
  }

  Future<List<Booking>> getBookings() async {
    final String? uid = _auth.currentUser?.uid;
    try {
      await FirebaseService.ensureInitialized();
      if (uid != null) {
        final QuerySnapshot<Map<String, dynamic>> snap = await FirebaseService.db
            .collection('users')
            .doc(uid)
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .get();
        return snap.docs.map((d) => Booking.fromJson(d.data())).toList();
      }
      throw Exception('No auth user');
    } catch (_) {
      return List<Booking>.from(_memoryFallback.reversed);
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final String? uid = _auth.currentUser?.uid;
    try {
      await FirebaseService.ensureInitialized();
      if (uid != null) {
        await FirebaseService.db
            .collection('users')
            .doc(uid)
            .collection('bookings')
            .doc(bookingId)
            .update({
          'status': 'cancelled',
          'cancelledAt': DateTime.now().toIso8601String(),
        });
        // Try root bookings as well
        try {
          await FirebaseService.db.collection('bookings').doc(bookingId).update({
            'status': 'cancelled',
            'cancelledAt': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
        // Notify user about cancellation
        try {
          await FirestoreService().addNotification(uid,
              title: 'Booking Cancelled',
              body: 'Your booking $bookingId has been cancelled.');
        } catch (_) {}
      } else {
        throw Exception('No auth user');
      }
    } catch (e) {
      // Fallback: remove from memory
      _memoryFallback.removeWhere((booking) => booking.id == bookingId);
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Get booking statistics for user profile
  Future<Map<String, int>> getBookingStats() async {
    final String? uid = _auth.currentUser?.uid;
    try {
      await FirebaseService.ensureInitialized();
      if (uid != null) {
        final QuerySnapshot<Map<String, dynamic>> snap = await FirebaseService.db
            .collection('users')
            .doc(uid)
            .collection('bookings')
            .get();
        
        int totalBookings = snap.docs.length;
        int confirmedBookings = snap.docs.where((doc) => doc.data()['status'] == 'confirmed').length;
        int cancelledBookings = snap.docs.where((doc) => doc.data()['status'] == 'cancelled').length;
        
        return {
          'total': totalBookings,
          'confirmed': confirmedBookings,
          'cancelled': cancelledBookings,
        };
      }
      throw Exception('No auth user');
    } catch (e) {
      // Fallback: count from memory
      int totalBookings = _memoryFallback.length;
      int confirmedBookings = _memoryFallback.where((booking) => booking.status == 'confirmed').length;
      int cancelledBookings = _memoryFallback.where((booking) => booking.status == 'cancelled').length;
      
      return {
        'total': totalBookings,
        'confirmed': confirmedBookings,
        'cancelled': cancelledBookings,
      };
    }
  }
}

