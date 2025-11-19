import 'dart:math';
import 'package:railone/models/pnr.dart';
import 'package:railone/services/firebase_service.dart';

/// PNR helper utilities: generate PNR, create mock records, and resolve
/// PNR status from Firestore with graceful local fallbacks for demo.
class PnrService {
  // Mock PNR data for demonstration
  static final Map<String, PnrRecord> _mockPnrData = {};

  // Generate a random PNR for new bookings (10 digits)
  static String generatePnr() {
    final random = Random();
    // Generate 10-digit PNR by building it digit by digit
    final digits = <int>[];
    // First digit: 1-9 (to ensure 10 digits)
    digits.add(1 + random.nextInt(9));
    // Next 9 digits: 0-9
    for (int i = 0; i < 9; i++) {
      digits.add(random.nextInt(10));
    }
    return digits.join('');
  }

  // Create PNR record for a booking
  static PnrRecord createPnrRecord({
    required String pnr,
    required String trainNumber,
    required String trainName,
    required String journeyDate,
    required String from,
    required String to,
    required List<PnrPassenger> passengers,
    required String fare,
  }) {
    final random = Random();
    final statuses = ['On Time', 'Delayed', 'Late'];
    final chartStatuses = ['Chart Not Prepared', 'Chart Prepared'];
    final platforms = ['1', '2', '3', '4', '5', '6', '7', '8'];
    final classes = ['SL', '3A', '2A', '1A', 'CC', 'EC'];
    final quotas = ['GN', 'TQ', 'LD', 'HP', 'DF', 'PT', 'SS', 'PH'];
    final coachPositions = ['Front', 'Middle', 'Rear'];

    final pnrRecord = PnrRecord(
      pnr: pnr,
      trainNumber: trainNumber,
      trainName: trainName,
      journeyDate: journeyDate,
      from: from,
      to: to,
      passengers: passengers,
      trainStatus: statuses[random.nextInt(statuses.length)],
      chartStatus: chartStatuses[random.nextInt(chartStatuses.length)],
      departureTime: '${8 + random.nextInt(12)}:${random.nextInt(60).toString().padLeft(2, '0')}',
      arrivalTime: '${12 + random.nextInt(8)}:${random.nextInt(60).toString().padLeft(2, '0')}',
      platform: platforms[random.nextInt(platforms.length)],
      coachPosition: coachPositions[random.nextInt(coachPositions.length)],
      bookingClass: classes[random.nextInt(classes.length)],
      fare: fare,
      bookingDate: DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String().split('T')[0],
      boardingStation: from,
      destinationStation: to,
      journeyClass: classes[random.nextInt(classes.length)],
      quota: quotas[random.nextInt(quotas.length)],
      currentStatus: 'Confirmed',
      lastUpdated: DateTime.now().toIso8601String(),
    );

    _mockPnrData[pnr] = pnrRecord;
    return pnrRecord;
  }

  // Check PNR status
  static Future<PnrRecord?> checkPnrStatus(String pnr) async {
    try {
      // Try to get from Firebase first
      await FirebaseService.ensureInitialized();
      final doc = await FirebaseService.db.collection('pnr_records').doc(pnr).get();
      
      if (doc.exists) {
        return PnrRecord.fromJson(doc.data()!);
      }
      
      // Fallback to local mock data
      if (_mockPnrData.containsKey(pnr)) {
        return _mockPnrData[pnr];
      }
      
      // Generate mock data for demonstration (only 10-digit PNR)
      if (pnr.length == 10 && pnr.startsWith(RegExp(r'[0-9]'))) {
        return _generateMockPnrRecord(pnr);
      }
      
      return null;
    } catch (e) {
      // Fallback to local mock data if Firebase fails
      if (_mockPnrData.containsKey(pnr)) {
        return _mockPnrData[pnr];
      }
      
      if (pnr.length == 10 && pnr.startsWith(RegExp(r'[0-9]'))) {
        return _generateMockPnrRecord(pnr);
      }
      
      return null;
    }
  }

  // Generate mock PNR record for demonstration
  static PnrRecord _generateMockPnrRecord(String pnr) {
    final random = Random();
    final trains = [
      {'number': '12345', 'name': 'Rajdhani Express'},
      {'number': '12346', 'name': 'Shatabdi Express'},
      {'number': '12347', 'name': 'Duronto Express'},
      {'number': '12348', 'name': 'Garib Rath Express'},
      {'number': '12349', 'name': 'Jan Shatabdi Express'},
    ];
    
    final stations = [
      {'from': 'Delhi', 'to': 'Mumbai'},
      {'from': 'Mumbai', 'to': 'Delhi'},
      {'from': 'Chennai', 'to': 'Bangalore'},
      {'from': 'Bangalore', 'to': 'Chennai'},
      {'from': 'Kolkata', 'to': 'Delhi'},
    ];
    
    final train = trains[random.nextInt(trains.length)];
    final station = stations[random.nextInt(stations.length)];
    
    final statuses = ['On Time', 'Delayed by 30 mins', 'Delayed by 1 hour', 'Late'];
    final chartStatuses = ['Chart Not Prepared', 'Chart Prepared'];
    final platforms = ['1', '2', '3', '4', '5', '6', '7', '8'];
    final classes = ['SL', '3A', '2A', '1A', 'CC', 'EC'];
    final quotas = ['GN', 'TQ', 'LD', 'HP', 'DF', 'PT', 'SS', 'PH'];
    final coachPositions = ['Front', 'Middle', 'Rear'];
    
    final passengers = List.generate(
      random.nextInt(3) + 1, // 1-3 passengers
      (index) => PnrPassenger(
        name: 'Passenger ${index + 1}',
        age: 20 + random.nextInt(40),
        gender: random.nextBool() ? 'Male' : 'Female',
        coach: '${classes[random.nextInt(classes.length)]}${random.nextInt(10) + 1}',
        seat: random.nextInt(72) + 1,
        berth: ['LB', 'MB', 'UB', 'SL', 'SU', 'LB', 'MB', 'UB'][random.nextInt(8)],
        bookingStatus: 'CNF',
        currentStatus: 'Confirmed',
      ),
    );

    final paymentMethods = ['Credit Card', 'Debit Card', 'UPI', 'Net Banking', 'Wallet'];
    final cardNumbers = ['4111****1111', '5555****4444', '3782****10005', '6011****1117', '4000****5556'];
    final transactionIds = ['TXN${DateTime.now().millisecondsSinceEpoch}', 'TXN${random.nextInt(999999)}', 'TXN${random.nextInt(999999)}'];
    final paymentStatuses = ['Success', 'Success', 'Success', 'Pending', 'Failed'];
    
    return PnrRecord(
      pnr: pnr,
      trainNumber: train['number']!,
      trainName: train['name']!,
      journeyDate: DateTime.now().add(Duration(days: random.nextInt(30))).toIso8601String().split('T')[0],
      from: station['from']!,
      to: station['to']!,
      passengers: passengers,
      trainStatus: statuses[random.nextInt(statuses.length)],
      chartStatus: chartStatuses[random.nextInt(chartStatuses.length)],
      departureTime: '${8 + random.nextInt(12)}:${random.nextInt(60).toString().padLeft(2, '0')}',
      arrivalTime: '${12 + random.nextInt(8)}:${random.nextInt(60).toString().padLeft(2, '0')}',
      platform: platforms[random.nextInt(platforms.length)],
      coachPosition: coachPositions[random.nextInt(coachPositions.length)],
      bookingClass: classes[random.nextInt(classes.length)],
      fare: '${500 + random.nextInt(2000)}',
      bookingDate: DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String().split('T')[0],
      boardingStation: station['from']!,
      destinationStation: station['to']!,
      journeyClass: classes[random.nextInt(classes.length)],
      quota: quotas[random.nextInt(quotas.length)],
      currentStatus: 'Confirmed',
      lastUpdated: DateTime.now().toIso8601String(),
      paymentMethod: paymentMethods[random.nextInt(paymentMethods.length)],
      cardNumber: cardNumbers[random.nextInt(cardNumbers.length)],
      transactionId: transactionIds[random.nextInt(transactionIds.length)],
      paymentStatus: paymentStatuses[random.nextInt(paymentStatuses.length)],
      paymentDate: DateTime.now().subtract(Duration(days: random.nextInt(30))).toIso8601String().split('T')[0],
    );
  }

  // Get all PNR records (for admin)
  static List<PnrRecord> getAllPnrRecords() {
    return _mockPnrData.values.toList();
  }
}
