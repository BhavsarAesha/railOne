import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:railone/models/booking.dart';
import 'package:railone/screens/pnr_status_screen.dart';
import 'package:railone/services/auth_service.dart';
import 'package:railone/services/booking_service.dart';
import 'package:railone/services/firestore_service.dart';
import 'package:railone/utils/validators.dart';

// Displays user's bookings with stats and allows cancellation.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final BookingService _bookingService = BookingService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  late Future<List<Booking>> _future;
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _future = _bookingService.getBookings();
    _statsFuture = _bookingService.getBookingStats();
  }

  Future<void> _cancelBooking(String bookingId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _bookingService.cancelBooking(bookingId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        // Refresh the bookings and stats
        setState(() {
          _future = _bookingService.getBookings();
          _statsFuture = _bookingService.getBookingStats();
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _future = _bookingService.getBookings();
                _statsFuture = _bookingService.getBookingStats();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Booking Statistics
          FutureBuilder<Map<String, int>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox.shrink();
              }
              final stats = snapshot.data ?? {'total': 0, 'confirmed': 0, 'cancelled': 0};
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Booking Statistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem('Total Bookings', stats['total'] ?? 0, Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatItem('Confirmed', stats['confirmed'] ?? 0, Colors.green),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatItem('Cancelled', stats['cancelled'] ?? 0, Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Your Booked Tickets', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<List<Booking>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }
              final bookings = snapshot.data ?? [];
              if (bookings.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No bookings yet'),
                );
              }
              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final b = bookings[index];
                  return Card(
                    child: ListTile(
                      title: Text('${b.trainNumber} • ${b.trainName}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${b.from} → ${b.to}  ${b.departureTime}-${b.arrivalTime}'),
                          Text('Tickets: ${b.quantity} • Booked: ${DateFormat.yMMMd().add_jm().format(b.createdAt)}'),
                          if (b.pnr != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('PNR: ${b.pnr}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PnrStatusScreen(pnr: b.pnr!),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                    ),
                                    child: const Text(
                                      'Check Status',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (b.status == 'cancelled') ...[
                            Text('Status: Cancelled', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            if (b.cancelledAt != null)
                              Text('Cancelled on: ${DateFormat.yMMMd().add_jm().format(b.cancelledAt!)}', 
                                   style: TextStyle(color: Colors.red.shade600, fontSize: 12)),
                          ],
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${b.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (b.status == 'confirmed')
                            TextButton(
                              onPressed: () => _cancelBooking(b.id),
                              child: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: bookings.length,
              );
            },
          ),
        ],
      ),
    );
  }
}


