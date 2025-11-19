import 'package:flutter/material.dart';
import 'package:railone/models/train.dart';
import 'package:railone/screens/booking_payment/payment_screen.dart';
import 'package:railone/services/firestore_service.dart';

class TrainDetailsScreen extends StatefulWidget {
  final Train train;
  const TrainDetailsScreen({super.key, required this.train});

  @override
  State<TrainDetailsScreen> createState() => _TrainDetailsScreenState();
}

class _TrainDetailsScreenState extends State<TrainDetailsScreen> {
  int _quantity = 1;
  final FirestoreService _firestore = FirestoreService();
  String _journeyDate = DateTime.now().toIso8601String().split('T').first; // simple default
  final Set<int> _selectedSeats = <int>{};
  static const int _defaultTotalSeats = 72;
  final List<String> _coaches = List<String>.generate(14, (i) => 'B${i + 1}');
  String _selectedCoach = 'B1';
  final Map<String, String> _berthMap = const {
    '1': 'LB', '2': 'MB', '3': 'UB', '4': 'LB', '5': 'MB', '6': 'UB', '7': 'SL', '8': 'SU'
  }; // simple 8-seat bay pattern

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.train.ticketAmount * _quantity;
    
    return Scaffold(
      appBar: AppBar(title: Text('${widget.train.number} • ${widget.train.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                title: Text('${widget.train.source} → ${widget.train.destination}'),
                subtitle: Text('Departure: ${widget.train.departureTime} • Arrival: ${widget.train.arrivalTime}'),
              ),
            ),
            const SizedBox(height: 12),
            // Seat map and selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Seats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () async {
                            // naive date picker; keep ISO date only
                            final DateTime now = DateTime.now();
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: now.subtract(const Duration(days: 0)),
                              lastDate: now.add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setState(() {
                                _journeyDate = picked.toIso8601String().split('T').first;
                                _selectedSeats.clear();
                              });
                            }
                          },
                          child: Text('Date: $_journeyDate'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<void>(
                      future: _firestore.ensureSeatMap(
                        trainNumber: widget.train.number,
                        journeyDate: _journeyDate,
                        totalSeats: _defaultTotalSeats,
                        coaches: _coaches,
                      ),
                      builder: (context, _) {
                        return StreamBuilder(
                          stream: _firestore.listenSeatMap(
                            trainNumber: widget.train.number,
                            journeyDate: _journeyDate,
                          ),
                          builder: (context, snap) {
                            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                            final data = snap.data!.data() ?? {};
                            final int total = (data['totalSeats'] as int?) ?? _defaultTotalSeats;
                            final Set<int> booked = Set<int>.from((data['booked'] as List?)?.map((e) => (e as num).toInt()) ?? <int>[]);
                            final Set<String> bookedCodes = Set<String>.from((data['bookedCodes'] as List?)?.map((e) => e.toString()) ?? <String>[]);
                            // Coach selector
                            final List<String> coaches = (data['coaches'] as List?)?.map((e) => e.toString()).toList() ?? _coaches;
                            if (!coaches.contains(_selectedCoach)) {
                              _selectedCoach = coaches.first;
                            }
                            // Keep selected within available
                            _selectedSeats.removeWhere((s) => booked.contains(s) || s > total);
                            final int cols = 8; // 8 bay pattern
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Coach:'),
                                    const SizedBox(width: 8),
                                    DropdownButton<String>(
                                      value: _selectedCoach,
                                      items: coaches.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                      onChanged: (v) {
                                        if (v == null) return;
                                        setState(() {
                                          _selectedCoach = v;
                                          _selectedSeats.clear();
                                          _quantity = 1;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double maxWidth = constraints.maxWidth;
                                    final double cell = (maxWidth - (7 * 6)) / 8; // spacing 6 between 8 cells
                                    final double size = cell.clamp(28.0, 40.0);
                                    return Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: List.generate(total, (i) {
                                        final seatNo = i + 1;
                                        final String seatCode = '$_selectedCoach-$seatNo';
                                        final bool isBooked = booked.contains(seatNo) || bookedCodes.contains(seatCode);
                                        final bool isSelected = _selectedSeats.contains(seatNo);
                                        final String berth = _berthMap['${((seatNo - 1) % 8) + 1}'] ?? 'LB';
                                        return GestureDetector(
                                          onTap: isBooked
                                              ? null
                                              : () {
                                                  setState(() {
                                                    if (isSelected) {
                                                      _selectedSeats.remove(seatNo);
                                                    } else {
                                                      _selectedSeats.add(seatNo);
                                                    }
                                                    _quantity = _selectedSeats.length.clamp(1, 10);
                                                  });
                                                },
                                          child: Container(
                                            width: size,
                                            height: size,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: isBooked
                                                  ? Colors.red.shade200
                                                  : (isSelected ? Colors.green.shade300 : Colors.grey.shade200),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: isBooked ? Colors.red.shade400 : Colors.grey.shade400),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text('$seatNo', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                                Text(berth, style: const TextStyle(fontSize: 8)),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _legend(color: Colors.green.shade300, label: 'Available'),
                                    const SizedBox(width: 12),
                                    _legend(color: Colors.red.shade200, label: 'Booked'),
                                    const SizedBox(width: 12),
                                  _legend(color: Colors.grey.shade200, label: 'Empty'),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Live Status'),
                subtitle: Text(widget.train.status),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ticket Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Price per ticket:'),
                        Text('₹${widget.train.ticketAmount.toStringAsFixed(0)}', 
                             style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantity:'),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              onPressed: _quantity < 10 ? () => setState(() => _quantity++) : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('₹${totalAmount.toStringAsFixed(0)}', 
                             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.train.lastUpdated != null)
              Text('Last updated: ${widget.train.lastUpdated}'),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _selectedSeats.isEmpty
                  ? null
                  : () {
                      final List<int> seats = _selectedSeats.toList()..sort();
                      final List<String> seatCodes = seats.map((s) {
                        final String berth = _berthMap['${((s - 1) % 8) + 1}'] ?? 'LB';
                        return 'CNF/$_selectedCoach/$s/$berth';
                      }).toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            train: widget.train,
                            quantity: seats.length,
                            selectedSeats: seats,
                            journeyDate: _journeyDate,
                            selectedSeatCodes: seatCodes,
                            selectedCoach: _selectedCoach,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.payment),
              label: Text(_selectedSeats.isEmpty
                  ? 'Select seats to continue'
                  : 'Pay ₹${(widget.train.ticketAmount * _selectedSeats.length).toStringAsFixed(0)} for ${_selectedSeats.length} seats'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.grey.shade400))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

